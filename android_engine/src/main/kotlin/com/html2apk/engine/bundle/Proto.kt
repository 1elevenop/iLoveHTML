package com.html2apk.engine.bundle

import java.io.ByteArrayOutputStream

/**
 * Minimal protobuf wire-format message: an ordered list of fields kept as
 * raw values, so messages can be edited without generated classes and
 * fields this code does not know about are written back unchanged.
 */
class ProtoMessage(val fields: MutableList<Field> = mutableListOf()) {

    /** [value] is a Long for varint/fixed fields and a ByteArray for length-delimited ones. */
    class Field(val number: Int, val wireType: Int, var value: Any)

    fun all(number: Int) = fields.filter { it.number == number }
    fun first(number: Int) = fields.firstOrNull { it.number == number }

    fun string(number: Int): String? = (first(number)?.value as? ByteArray)?.toString(Charsets.UTF_8)
    fun varint(number: Int): Long? = first(number)?.value as? Long
    fun message(number: Int): ProtoMessage? = (first(number)?.value as? ByteArray)?.let { parse(it) }
    fun messages(number: Int): List<ProtoMessage> = all(number).map { parse(it.value as ByteArray) }

    fun setString(number: Int, value: String) = setBytes(number, value.toByteArray(Charsets.UTF_8))

    fun setBytes(number: Int, value: ByteArray) {
        val f = first(number)
        if (f != null) { f.value = value } else fields.add(Field(number, LEN, value))
    }

    fun setMessage(number: Int, value: ProtoMessage) = setBytes(number, value.encode())

    fun setVarint(number: Int, value: Long) {
        val f = first(number)
        if (f != null) { f.value = value } else fields.add(Field(number, VARINT, value))
    }

    fun remove(number: Int) { fields.removeAll { it.number == number } }

    fun encode(): ByteArray {
        val out = ByteArrayOutputStream()
        for (f in fields) {
            writeVarint(out, (f.number.toLong() shl 3) or f.wireType.toLong())
            when (f.wireType) {
                VARINT -> writeVarint(out, f.value as Long)
                FIXED64 -> { val v = f.value as Long; for (i in 0 until 8) out.write(((v shr (8 * i)) and 0xff).toInt()) }
                FIXED32 -> { val v = f.value as Long; for (i in 0 until 4) out.write(((v shr (8 * i)) and 0xff).toInt()) }
                LEN -> { val b = f.value as ByteArray; writeVarint(out, b.size.toLong()); out.write(b) }
                else -> throw IllegalStateException("Unsupported wire type ${f.wireType}")
            }
        }
        return out.toByteArray()
    }

    companion object {
        const val VARINT = 0
        const val FIXED64 = 1
        const val LEN = 2
        const val FIXED32 = 5

        fun parse(bytes: ByteArray): ProtoMessage {
            val msg = ProtoMessage()
            var pos = 0
            fun varint(): Long {
                var result = 0L
                var shift = 0
                while (true) {
                    require(pos < bytes.size && shift < 64) { "Truncated protobuf varint" }
                    val b = bytes[pos++].toInt() and 0xff
                    result = result or ((b and 0x7f).toLong() shl shift)
                    if (b and 0x80 == 0) return result
                    shift += 7
                }
            }
            while (pos < bytes.size) {
                val key = varint()
                val number = (key ushr 3).toInt()
                val type = (key and 7).toInt()
                require(number > 0) { "Bad protobuf field number" }
                val value: Any = when (type) {
                    VARINT -> varint()
                    FIXED64 -> { require(pos + 8 <= bytes.size); var v = 0L; for (i in 0 until 8) v = v or ((bytes[pos + i].toLong() and 0xff) shl (8 * i)); pos += 8; v }
                    FIXED32 -> { require(pos + 4 <= bytes.size); var v = 0L; for (i in 0 until 4) v = v or ((bytes[pos + i].toLong() and 0xff) shl (8 * i)); pos += 4; v }
                    LEN -> {
                        val n = varint()
                        require(n >= 0 && pos + n <= bytes.size) { "Truncated protobuf field" }
                        bytes.copyOfRange(pos, pos + n.toInt()).also { pos += n.toInt() }
                    }
                    else -> throw IllegalArgumentException("Unsupported protobuf wire type $type")
                }
                msg.fields.add(Field(number, type, value))
            }
            return msg
        }

        private fun writeVarint(out: ByteArrayOutputStream, value: Long) {
            var v = value
            while (true) {
                if (v and 0x7fL.inv() == 0L) { out.write(v.toInt()); return }
                out.write(((v and 0x7f) or 0x80).toInt())
                v = v ushr 7
            }
        }
    }
}

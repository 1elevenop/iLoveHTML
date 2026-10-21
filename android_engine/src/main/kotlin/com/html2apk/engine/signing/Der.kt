package com.html2apk.engine.signing

import java.io.ByteArrayOutputStream
import java.math.BigInteger
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** Minimal DER encoder: just enough to build an X.509 certificate. */
internal object Der {
    fun tlv(tag: Int, content: ByteArray): ByteArray {
        val out = ByteArrayOutputStream()
        out.write(tag)
        val n = content.size
        when {
            n < 0x80 -> out.write(n)
            n < 0x100 -> { out.write(0x81); out.write(n) }
            n < 0x10000 -> { out.write(0x82); out.write(n shr 8); out.write(n and 0xff) }
            else -> { out.write(0x83); out.write(n shr 16); out.write((n shr 8) and 0xff); out.write(n and 0xff) }
        }
        out.write(content)
        return out.toByteArray()
    }

    private fun concat(items: Array<out ByteArray>) =
        ByteArrayOutputStream().apply { items.forEach { write(it) } }.toByteArray()

    fun seq(vararg items: ByteArray) = tlv(0x30, concat(items))
    fun set(vararg items: ByteArray) = tlv(0x31, concat(items))
    fun int(v: BigInteger) = tlv(0x02, v.toByteArray())
    fun int(v: Long) = int(BigInteger.valueOf(v))
    fun nul() = byteArrayOf(0x05, 0x00)
    fun utf8(s: String) = tlv(0x0C, s.toByteArray(Charsets.UTF_8))
    fun printable(s: String) = tlv(0x13, s.toByteArray(Charsets.US_ASCII))
    fun octets(b: ByteArray) = tlv(0x04, b)
    fun bitString(b: ByteArray) = tlv(0x03, byteArrayOf(0) + b)
    fun explicit(tagNumber: Int, content: ByteArray) = tlv(0xA0 or tagNumber, content)

    fun oid(dotted: String): ByteArray {
        val arcs = dotted.split('.').map { it.toLong() }
        val out = ByteArrayOutputStream()
        out.write((arcs[0] * 40 + arcs[1]).toInt())
        for (arc in arcs.drop(2)) {
            val groups = ArrayList<Int>()
            var v = arc
            do { groups.add((v and 0x7f).toInt()); v = v shr 7 } while (v > 0)
            for (i in groups.indices.reversed()) out.write(if (i > 0) groups[i] or 0x80 else groups[i])
        }
        return tlv(0x06, out.toByteArray())
    }

    /** RFC 5280: UTCTime for 1950-2049, GeneralizedTime otherwise. */
    fun time(date: Date): ByteArray {
        val year = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply { time = date }.get(Calendar.YEAR)
        val utc = year in 1950..2049
        val fmt = SimpleDateFormat(if (utc) "yyMMddHHmmss'Z'" else "yyyyMMddHHmmss'Z'", Locale.US)
        fmt.timeZone = TimeZone.getTimeZone("UTC")
        return tlv(if (utc) 0x17 else 0x18, fmt.format(date).toByteArray(Charsets.US_ASCII))
    }
}

/** Minimal DER reader for the structures inside JKS key entries. */
internal class DerReader(private val b: ByteArray, private var pos: Int = 0, private val end: Int = b.size) {
    class Tlv(val tag: Int, val start: Int, val end: Int)

    fun hasMore() = pos < end

    fun next(): Tlv {
        require(pos + 2 <= end) { "Truncated DER" }
        val tag = b[pos++].toInt() and 0xff
        var len = b[pos++].toInt() and 0xff
        if (len and 0x80 != 0) {
            val n = len and 0x7f
            require(n in 1..4 && pos + n <= end) { "Bad DER length" }
            len = 0
            repeat(n) { len = (len shl 8) or (b[pos++].toInt() and 0xff) }
        }
        require(len >= 0 && pos + len <= end) { "DER length out of range" }
        val t = Tlv(tag, pos, pos + len)
        pos += len
        return t
    }

    fun inside(t: Tlv) = DerReader(b, t.start, t.end)
    fun bytes(t: Tlv): ByteArray = b.copyOfRange(t.start, t.end)

    fun oid(t: Tlv): String {
        require(t.tag == 0x06) { "Expected an OID" }
        val first = b[t.start].toInt() and 0xff
        val arcs = mutableListOf(first / 40L, first % 40L)
        var v = 0L
        for (i in t.start + 1 until t.end) {
            val x = b[i].toInt() and 0xff
            v = (v shl 7) or (x and 0x7f).toLong()
            if (x and 0x80 == 0) { arcs.add(v); v = 0 }
        }
        return arcs.joinToString(".")
    }
}

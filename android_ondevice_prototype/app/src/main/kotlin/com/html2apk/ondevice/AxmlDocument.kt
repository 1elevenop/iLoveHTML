package com.html2apk.ondevice

import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * Minimal editor for Android binary XML (the compiled AndroidManifest.xml in an APK).
 *
 * Supports exactly what the on-device engine needs: reading elements and
 * attributes, changing attribute values, appending pool strings and inserting
 * new child elements. Existing string indices never change: new strings are
 * appended after the resource-ID map range, so attribute-name lookups by
 * resource ID stay valid.
 */
class AxmlDocument private constructor(
    val strings: MutableList<String>,
    private val utf8: Boolean,
    private val resourceIds: IntArray,
    val nodes: MutableList<Node>,
) {
    sealed class Node

    /** A chunk this editor does not need to understand, kept byte-for-byte. */
    class RawNode(val bytes: ByteArray) : Node()

    class Attribute(
        val ns: Int,
        val name: Int,
        var rawValue: Int,
        var type: Int,
        var data: Int,
    )

    class StartElement(
        val line: Int,
        val ns: Int,
        val name: Int,
        val attributes: MutableList<Attribute>,
        private val idIndex: Int,
        private val classIndex: Int,
        private val styleIndex: Int,
    ) : Node() {
        internal fun write(out: ByteBuffer) {
            val size = 16 + 20 + attributes.size * 20
            out.putShort(RES_XML_START_ELEMENT.toShort()).putShort(16).putInt(size)
            out.putInt(line).putInt(-1)
            out.putInt(ns).putInt(name)
            out.putShort(20).putShort(20).putShort(attributes.size.toShort())
            out.putShort(idIndex.toShort()).putShort(classIndex.toShort()).putShort(styleIndex.toShort())
            for (a in attributes) {
                out.putInt(a.ns).putInt(a.name).putInt(a.rawValue)
                out.putShort(8).put(0).put(a.type.toByte()).putInt(a.data)
            }
        }

        internal val byteSize get() = 36 + attributes.size * 20
    }

    class EndElement(val line: Int, val ns: Int, val name: Int) : Node()

    fun indexOf(s: String): Int = strings.indexOf(s)

    /** Appends [s] to the string pool (or reuses an existing non-mapped copy). */
    fun addString(s: String): Int {
        for (i in resourceIds.size until strings.size) if (strings[i] == s) return i
        strings.add(s)
        return strings.size - 1
    }

    /** Index of the pool string that carries resource ID [resId] (attribute names). */
    fun attrNameIndex(resId: Int): Int = resourceIds.indexOf(resId)

    fun elements(name: String): List<StartElement> {
        val idx = indexOf(name)
        return nodes.filterIsInstance<StartElement>().filter { it.name == idx }
    }

    fun attribute(element: StartElement, resId: Int): Attribute? {
        val nameIdx = attrNameIndex(resId)
        return element.attributes.firstOrNull { it.name == nameIdx && nameIdx >= 0 }
    }

    /** Attribute without namespace, e.g. manifest@package. */
    fun plainAttribute(element: StartElement, name: String): Attribute? {
        val nameIdx = indexOf(name)
        return element.attributes.firstOrNull { it.name == nameIdx && it.ns == -1 }
    }

    fun setString(attr: Attribute, value: String) {
        val idx = addString(value)
        attr.rawValue = idx
        attr.type = TYPE_STRING
        attr.data = idx
    }

    fun setInt(attr: Attribute, value: Int, type: Int = TYPE_INT_DEC) {
        attr.rawValue = -1
        attr.type = type
        attr.data = value
    }

    /**
     * Inserts `<[elementName] android:name="[nameValue]"/>` as a child of the
     * element at [parentIndex] in [nodes], before its first child.
     */
    fun insertChildWithName(parentIndex: Int, elementName: String, nameValue: String) {
        val parent = nodes[parentIndex] as StartElement
        val androidNs = indexOf(ANDROID_NS)
        val nameAttr = attrNameIndex(ATTR_NAME)
        require(androidNs >= 0 && nameAttr >= 0) { "android:name not available in base manifest" }
        val elem = addString(elementName)
        val value = addString(nameValue)
        val start = StartElement(parent.line, -1, elem,
            mutableListOf(Attribute(androidNs, nameAttr, value, TYPE_STRING, value)), 0, 0, 0)
        nodes.add(parentIndex + 1, start)
        nodes.add(parentIndex + 2, EndElement(parent.line, -1, elem))
    }

    fun toByteArray(): ByteArray {
        val pool = encodeStringPool()
        val mapSize = 8 + resourceIds.size * 4
        val nodeBytes = ByteArrayOutputStream()
        for (n in nodes) {
            when (n) {
                is RawNode -> nodeBytes.write(n.bytes)
                is StartElement -> nodeBytes.write(le(n.byteSize).also { n.write(it) }.array())
                is EndElement -> nodeBytes.write(le(24).apply {
                    putShort(RES_XML_END_ELEMENT.toShort()).putShort(16).putInt(24)
                    putInt(n.line).putInt(-1).putInt(n.ns).putInt(n.name)
                }.array())
            }
        }
        val total = 8 + pool.size + mapSize + nodeBytes.size()
        val out = le(total)
        out.putShort(RES_XML_TYPE.toShort()).putShort(8).putInt(total)
        out.put(pool)
        out.putShort(RES_XML_RESOURCE_MAP.toShort()).putShort(8).putInt(mapSize)
        for (id in resourceIds) out.putInt(id)
        out.put(nodeBytes.toByteArray())
        return out.array()
    }

    private fun encodeStringPool(): ByteArray {
        val data = ByteArrayOutputStream()
        val offsets = IntArray(strings.size)
        for ((i, s) in strings.withIndex()) {
            offsets[i] = data.size()
            if (utf8) {
                val bytes = s.toByteArray(Charsets.UTF_8)
                writeUtf8Len(data, s.length)
                writeUtf8Len(data, bytes.size)
                data.write(bytes)
                data.write(0)
            } else {
                writeUtf16Len(data, s.length)
                for (c in s) { data.write(c.code and 0xff); data.write(c.code shr 8) }
                data.write(0); data.write(0)
            }
        }
        while (data.size() % 4 != 0) data.write(0)
        val headerSize = 28
        val stringsStart = headerSize + strings.size * 4
        val size = stringsStart + data.size()
        val out = le(size)
        out.putShort(RES_STRING_POOL.toShort()).putShort(headerSize.toShort()).putInt(size)
        out.putInt(strings.size).putInt(0)
        out.putInt(if (utf8) UTF8_FLAG else 0)
        out.putInt(stringsStart).putInt(0)
        for (o in offsets) out.putInt(o)
        out.put(data.toByteArray())
        return out.array()
    }

    companion object {
        const val RES_STRING_POOL = 0x0001
        const val RES_XML_TYPE = 0x0003
        const val RES_XML_START_ELEMENT = 0x0102
        const val RES_XML_END_ELEMENT = 0x0103
        const val RES_XML_RESOURCE_MAP = 0x0180
        const val UTF8_FLAG = 0x100

        const val TYPE_REFERENCE = 0x01
        const val TYPE_STRING = 0x03
        const val TYPE_INT_DEC = 0x10

        const val ANDROID_NS = "http://schemas.android.com/apk/res/android"
        const val ATTR_NAME = 0x01010003
        const val ATTR_LABEL = 0x01010001
        const val ATTR_SCREEN_ORIENTATION = 0x0101001e
        const val ATTR_VERSION_CODE = 0x0101021b
        const val ATTR_VERSION_NAME = 0x0101021c

        private fun le(size: Int): ByteBuffer = ByteBuffer.allocate(size).order(ByteOrder.LITTLE_ENDIAN)

        fun parse(bytes: ByteArray): AxmlDocument {
            val buf = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
            require(buf.short.toInt() and 0xffff == RES_XML_TYPE) { "Not a binary XML file" }
            val headerSize = buf.short.toInt() and 0xffff
            val total = buf.int
            require(total <= bytes.size) { "Truncated binary XML" }
            buf.position(headerSize)

            var strings: MutableList<String>? = null
            var utf8 = false
            var resourceIds = IntArray(0)
            val nodes = mutableListOf<Node>()
            while (buf.position() < total) {
                val start = buf.position()
                val type = buf.short.toInt() and 0xffff
                val chunkHeader = buf.short.toInt() and 0xffff
                val size = buf.int
                require(size >= 8 && start + size <= total) { "Corrupt chunk at $start" }
                when (type) {
                    RES_STRING_POOL -> {
                        val count = buf.int
                        val styleCount = buf.int
                        val flags = buf.int
                        val stringsStart = buf.int
                        require(styleCount == 0) { "Styled strings are not supported" }
                        utf8 = flags and UTF8_FLAG != 0
                        buf.int // stylesStart
                        val offsets = IntArray(count) { buf.int }
                        strings = MutableList(count) { i ->
                            readString(bytes, start + stringsStart + offsets[i], utf8)
                        }
                    }
                    RES_XML_RESOURCE_MAP -> resourceIds = IntArray((size - chunkHeader) / 4) { buf.int }
                    RES_XML_START_ELEMENT -> {
                        val line = buf.int
                        buf.int // comment
                        val ns = buf.int
                        val name = buf.int
                        val attrStart = buf.short.toInt() and 0xffff
                        val attrSize = buf.short.toInt() and 0xffff
                        val attrCount = buf.short.toInt() and 0xffff
                        val idIndex = buf.short.toInt() and 0xffff
                        val classIndex = buf.short.toInt() and 0xffff
                        val styleIndex = buf.short.toInt() and 0xffff
                        val attrs = MutableList(attrCount) { i ->
                            buf.position(start + chunkHeader + attrStart + i * attrSize)
                            val aNs = buf.int
                            val aName = buf.int
                            val raw = buf.int
                            buf.short; buf.get()
                            val dataType = buf.get().toInt() and 0xff
                            Attribute(aNs, aName, raw, dataType, buf.int)
                        }
                        nodes.add(StartElement(line, ns, name, attrs, idIndex, classIndex, styleIndex))
                    }
                    RES_XML_END_ELEMENT -> {
                        val line = buf.int
                        buf.int
                        nodes.add(EndElement(line, buf.int, buf.int))
                    }
                    else -> nodes.add(RawNode(bytes.copyOfRange(start, start + size)))
                }
                buf.position(start + size)
            }
            return AxmlDocument(requireNotNull(strings) { "No string pool" }, utf8, resourceIds, nodes)
        }

        private fun readString(b: ByteArray, pos: Int, utf8: Boolean): String {
            var p = pos
            return if (utf8) {
                // UTF-16 length, then UTF-8 byte length, each 1 or 2 bytes.
                p += if (b[p].toInt() and 0x80 != 0) 2 else 1
                var len = b[p].toInt() and 0xff
                if (len and 0x80 != 0) { len = ((len and 0x7f) shl 8) or (b[p + 1].toInt() and 0xff); p += 2 } else p += 1
                String(b, p, len, Charsets.UTF_8)
            } else {
                var len = (b[p].toInt() and 0xff) or ((b[p + 1].toInt() and 0xff) shl 8)
                p += 2
                if (len and 0x8000 != 0) {
                    len = ((len and 0x7fff) shl 16) or (b[p].toInt() and 0xff) or ((b[p + 1].toInt() and 0xff) shl 8)
                    p += 2
                }
                val chars = CharArray(len) { i -> ((b[p + 2 * i].toInt() and 0xff) or ((b[p + 2 * i + 1].toInt() and 0xff) shl 8)).toChar() }
                String(chars)
            }
        }

        private fun writeUtf8Len(out: ByteArrayOutputStream, len: Int) {
            require(len < 0x8000) { "String too long" }
            if (len > 0x7f) { out.write(0x80 or (len shr 8)); out.write(len and 0xff) } else out.write(len)
        }

        private fun writeUtf16Len(out: ByteArrayOutputStream, len: Int) {
            require(len < 0x8000) { "String too long" }
            out.write(len and 0xff); out.write(len shr 8)
        }
    }
}

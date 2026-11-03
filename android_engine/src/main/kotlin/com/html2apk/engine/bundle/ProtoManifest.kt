package com.html2apk.engine.bundle

/**
 * Edits an App Bundle's AndroidManifest.xml, stored as aapt2's protobuf
 * XmlNode (Resources.proto), rather than the binary XML used inside APKs.
 *
 * Field numbers from aapt2's Resources.proto:
 *  XmlNode      { element = 1; text = 2; source = 3 }
 *  XmlElement   { namespace_declaration = 1; namespace_uri = 2; name = 3; attribute = 4; child = 5 }
 *  XmlAttribute { namespace_uri = 1; name = 2; value = 3; source = 4; resource_id = 5; compiled_item = 6 }
 *  Item         { ref = 1; str = 2; ... prim = 7 }
 *  String       { value = 1 }
 *  Primitive    { ... int_decimal_value = 6 }
 */
class ProtoManifest(bytes: ByteArray) {
    private val root = ProtoMessage.parse(bytes)
    private val manifest: ProtoMessage = root.message(NODE_ELEMENT) ?: throw IllegalArgumentException("Manifest has no root element")

    init {
        require(manifest.string(EL_NAME) == "manifest") { "Root element is not <manifest>" }
    }

    fun encode(): ByteArray {
        root.setMessage(NODE_ELEMENT, manifest)
        return root.encode()
    }

    val packageName: String? get() = attributes(manifest).firstOrNull { it.string(ATTR_NAME) == "package" && it.string(ATTR_NS).isNullOrEmpty() }?.string(ATTR_VALUE)

    fun setPackage(value: String) = editAttribute(manifest, null, "package") { setStringValue(it, value) }
    fun setVersionCode(value: Int) = editAttribute(manifest, ANDROID_NS, "versionCode") { setIntValue(it, value) }
    fun setVersionName(value: String) = editAttribute(manifest, ANDROID_NS, "versionName") { setStringValue(it, value) }

    /** Replaces the `@string/app_name` reference with a literal label. */
    fun setLabel(value: String) = editChild("application") { app -> editAttribute(app, ANDROID_NS, "label") { setStringValue(it, value) } }

    fun setScreenOrientation(value: Int) = editChild("application") { app ->
        editChild(app, "activity") { activity -> editAttribute(activity, ANDROID_NS, "screenOrientation") { setIntValue(it, value) } }
    }

    /** Sets the FileProvider's authority, when the base manifest declares one. */
    fun setProviderAuthority(value: String) = editChild("application") { app ->
        if (hasChild(app, "provider")) {
            editChild(app, "provider") { provider -> editAttribute(provider, ANDROID_NS, "authorities") { setStringValue(it, value) } }
        }
    }

    /** Inserts `<uses-permission android:name="…"/>` as the first children of `<manifest>`. */
    fun addPermissions(permissions: List<String>) {
        val newChildren = permissions.map { perm ->
            val attr = ProtoMessage().apply {
                setString(ATTR_NS, ANDROID_NS)
                setString(ATTR_NAME, "name")
                setString(ATTR_VALUE, perm)
                setVarint(ATTR_RESOURCE_ID, NAME_RESOURCE_ID)
            }
            val element = ProtoMessage().apply {
                setString(EL_NAME, "uses-permission")
                fields.add(ProtoMessage.Field(EL_ATTRIBUTE, ProtoMessage.LEN, attr.encode()))
            }
            ProtoMessage.Field(EL_CHILD, ProtoMessage.LEN, ProtoMessage().apply { setMessage(NODE_ELEMENT, element) }.encode())
        }
        val firstChild = manifest.fields.indexOfFirst { it.number == EL_CHILD }.let { if (it < 0) manifest.fields.size else it }
        manifest.fields.addAll(firstChild, newChildren)
    }

    private fun attributes(element: ProtoMessage) = element.messages(EL_ATTRIBUTE)

    private fun editAttribute(element: ProtoMessage, ns: String?, name: String, edit: (ProtoMessage) -> Unit) {
        val field = element.all(EL_ATTRIBUTE).firstOrNull {
            val a = ProtoMessage.parse(it.value as ByteArray)
            a.string(ATTR_NAME) == name && (a.string(ATTR_NS) ?: "") == (ns ?: "")
        } ?: throw IllegalArgumentException("Attribute $name not found in base manifest")
        val attr = ProtoMessage.parse(field.value as ByteArray)
        edit(attr)
        field.value = attr.encode()
    }

    private fun hasChild(parent: ProtoMessage, name: String) = parent.all(EL_CHILD).any {
        ProtoMessage.parse(it.value as ByteArray).message(NODE_ELEMENT)?.string(EL_NAME) == name
    }

    private fun editChild(name: String, edit: (ProtoMessage) -> Unit) = editChild(manifest, name, edit)

    private fun editChild(parent: ProtoMessage, name: String, edit: (ProtoMessage) -> Unit) {
        val field = parent.all(EL_CHILD).firstOrNull {
            ProtoMessage.parse(it.value as ByteArray).message(NODE_ELEMENT)?.string(EL_NAME) == name
        } ?: throw IllegalArgumentException("<$name> not found in base manifest")
        val node = ProtoMessage.parse(field.value as ByteArray)
        val element = node.message(NODE_ELEMENT)!!
        edit(element)
        node.setMessage(NODE_ELEMENT, element)
        field.value = node.encode()
    }

    private fun setStringValue(attr: ProtoMessage, value: String) {
        attr.setString(ATTR_VALUE, value)
        if (attr.first(ATTR_COMPILED) != null) {
            attr.setMessage(ATTR_COMPILED, ProtoMessage().apply { setMessage(ITEM_STR, ProtoMessage().apply { setString(1, value) }) })
        }
    }

    private fun setIntValue(attr: ProtoMessage, value: Int) {
        attr.setString(ATTR_VALUE, value.toString())
        // int32 is encoded as a sign-extended 64-bit varint.
        val prim = ProtoMessage().apply { setVarint(PRIM_INT_DECIMAL, value.toLong()) }
        attr.setMessage(ATTR_COMPILED, ProtoMessage().apply { setMessage(ITEM_PRIM, prim) })
    }

    companion object {
        const val ANDROID_NS = "http://schemas.android.com/apk/res/android"
        private const val NODE_ELEMENT = 1
        private const val EL_NAME = 3
        private const val EL_ATTRIBUTE = 4
        private const val EL_CHILD = 5
        private const val ATTR_NS = 1
        private const val ATTR_NAME = 2
        private const val ATTR_VALUE = 3
        private const val ATTR_RESOURCE_ID = 5
        private const val ATTR_COMPILED = 6
        private const val ITEM_STR = 2
        private const val ITEM_PRIM = 7
        private const val PRIM_INT_DECIMAL = 6
        private const val NAME_RESOURCE_ID = 0x01010003L
    }
}

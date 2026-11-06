package com.html2apk.engine.bundle

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Builds a small protobuf manifest by hand, so no base bundle is needed. */
class ProtoManifestTvTest {
    private fun element(name: String, vararg children: ProtoMessage) = ProtoMessage().apply {
        setString(3, name)
        for (c in children) fields.add(ProtoMessage.Field(5, ProtoMessage.LEN, ProtoMessage().apply { setMessage(1, c) }.encode()))
    }

    private fun children(e: ProtoMessage) = e.messages(5).mapNotNull { it.message(1) }

    private fun child(e: ProtoMessage, name: String) = children(e).single { it.string(3) == name }

    @Test
    fun addsOptionalLeanbackFeatureAndTvLauncherCategory() {
        val manifest = element("manifest", element("application", element("activity", element("intent-filter", element("action")))))
        val bytes = ProtoMessage().apply { setMessage(1, manifest) }.encode()

        val m = ProtoManifest(bytes)
        m.addTvSupport("android.software.leanback", "android.intent.category.LEANBACK_LAUNCHER")
        val root = ProtoMessage.parse(m.encode()).message(1)!!

        val feature = children(root).first()
        assertEquals("uses-feature", feature.string(3))
        val (name, required) = feature.messages(4)
        assertEquals("name", name.string(2))
        assertEquals("android.software.leanback", name.string(3))
        assertEquals(0x01010003L, name.varint(5))
        assertEquals("required", required.string(2))
        assertEquals("false", required.string(3))
        assertEquals(0x0101028eL, required.varint(5))
        val prim = required.message(6)!!.message(7)!!
        assertEquals(0L, prim.varint(8), "boolean_value must be written even when false")

        val filter = child(child(child(root, "application"), "activity"), "intent-filter")
        val names = children(filter).map { it.string(3) }
        assertEquals(listOf("action", "category"), names)
        val category = children(filter).last().messages(4).single()
        assertEquals("android.intent.category.LEANBACK_LAUNCHER", category.string(3))
        assertTrue(children(root).count { it.string(3) == "application" } == 1)
    }
}

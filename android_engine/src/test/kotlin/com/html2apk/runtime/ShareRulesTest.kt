package com.html2apk.runtime

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The generated app's file-share checks (android_template's ShareRules.kt). */
class ShareRulesTest {
    @Test
    fun onlyImagesAndPdfAreShareable() {
        for (ok in listOf("image/png", "image/jpeg", "image/webp", "image/svg+xml", "application/pdf")) {
            assertTrue(ShareRules.isShareable(ok), ok)
        }
        for (bad in listOf("", "image/", "image", "text/html", "application/pdf2", "video/mp4", "image/png\nx", "application/octet-stream")) {
            assertFalse(ShareRules.isShareable(bad), bad)
        }
        assertFalse(ShareRules.isImage("application/pdf"))
    }

    @Test
    fun base64SizeMatchesDecodedLength() {
        for (n in 0..10) {
            val bytes = ByteArray(n) { it.toByte() }
            val encoded = java.util.Base64.getEncoder().encodeToString(bytes)
            assertEquals(n.toLong(), ShareRules.base64Size(encoded), "n=$n")
        }
        assertEquals(5, ShareRules.base64Size("aGVs\nbG8=")) // "hello", with a line break
    }

    @Test
    fun parsesDataUrls() {
        assertEquals(Triple("image/png", true, "AAAA"), ShareRules.parseDataUrl("data:IMAGE/png;base64,AAAA"))
        assertEquals(Triple("text/plain", false, "hi%20there"), ShareRules.parseDataUrl("data:text/plain,hi%20there"))
        assertNull(ShareRules.parseDataUrl("data:image/png;base64"))
        assertNull(ShareRules.parseDataUrl("blob:https://x/1"))
    }

    @Test
    fun sanitizesNames() {
        assertEquals("a_b_c.png", ShareRules.sanitizeName("a/b\\c.png"))
        assertEquals("passwd", ShareRules.sanitizeName("../passwd").trimStart('_'))
        assertEquals("download", ShareRules.sanitizeName("..."))
        assertEquals("x_y", ShareRules.sanitizeName("x\u0000y"))
        assertEquals(120, ShareRules.sanitizeName("a".repeat(500)).length)
    }

    @Test
    fun galleryFolderIsOneFolder() {
        assertEquals("Kishor G", ShareRules.folderName("Kishor G"))
        assertEquals("a_b", ShareRules.folderName("a/b"))
        assertEquals("x", ShareRules.folderName("../x")?.trimStart('_'))
        assertNull(ShareRules.folderName("   "))
        assertNull(ShareRules.folderName(null))
        assertEquals(60, ShareRules.folderName("f".repeat(100))!!.length)
    }

    @Test
    fun repeatedNamesAreNumbered() {
        assertEquals(listOf("a.png", "a (2).png", "A (3).PNG", "b"), ShareRules.uniqueNames(listOf("a.png", "a.png", "A.PNG", "b")))
    }

    @Test
    fun packageNames() {
        assertTrue(ShareRules.isPackageName("com.whatsapp"))
        assertTrue(ShareRules.isPackageName("org.telegram.messenger"))
        for (bad in listOf("whatsapp", "com..x", "1com.x", "com.x/y", "com.x;rm")) assertFalse(ShareRules.isPackageName(bad), bad)
    }
}

package com.html2apk.runtime

import kotlin.test.Test
import kotlin.test.assertEquals

/** Which pages get the generated app's bridge (android_template's AppOrigins.kt). */
class AppOriginsTest {
    private val assets = "appassets.androidplatform.net"

    @Test
    fun bundledAppsTrustOnlyTheirOwnFiles() {
        assertEquals(setOf("https://$assets"), AppOrigins.of(assets, null, emptySet()))
    }

    @Test
    fun urlAppsTrustTheirSiteWithAndWithoutWww() {
        assertEquals(
            setOf("https://$assets", "https://example.com", "https://www.example.com"),
            AppOrigins.of(assets, "example.com", emptySet()),
        )
        assertEquals(
            setOf("https://$assets", "https://example.com", "https://www.example.com"),
            AppOrigins.of(assets, "www.example.com", emptySet()),
        )
    }

    @Test
    fun onlyListedHostsAreAdded() {
        val origins = AppOrigins.of(assets, "example.com", setOf("shop.example.com"))
        assertEquals(
            setOf("https://$assets", "https://example.com", "https://www.example.com", "https://shop.example.com"),
            origins,
        )
    }
}

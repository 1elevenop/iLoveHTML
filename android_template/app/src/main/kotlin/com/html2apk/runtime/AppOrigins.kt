package com.html2apk.runtime

/**
 * Origin rules for the scripts and bridges added to pages. No Android types,
 * so android_engine's JVM tests can run them.
 */
object AppOrigins {
    /**
     * The app's own pages plus [extraHosts]. [startHost] is the site of a URL
     * app, which also counts with or without "www."; null for an app made of
     * bundled files.
     */
    fun of(assetHost: String, startHost: String?, extraHosts: Set<String>): Set<String> = buildSet {
        add("https://$assetHost")
        if (startHost != null) {
            add("https://$startHost")
            add(if (startHost.startsWith("www.")) "https://${startHost.removePrefix("www.")}" else "https://www.$startHost")
        }
        extraHosts.forEach { add("https://$it") }
    }
}

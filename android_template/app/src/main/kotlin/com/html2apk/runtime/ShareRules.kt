package com.html2apk.runtime

/**
 * Checks for files the page shares or downloads. No Android types, so
 * android_engine's JVM tests can run them.
 */
object ShareRules {
    const val MAX_FILES = 10
    const val MAX_BYTES = 20 * 1024 * 1024

    private val IMAGE_MIME = Regex("^image/[a-z0-9][a-z0-9.+-]*$")
    private val UNSAFE_NAME_CHARS = Regex("[\\\\/:*?\"<>|\\p{Cntrl}]")
    private val PACKAGE_NAME = Regex("^[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+$")

    fun isImage(mime: String) = IMAGE_MIME.matches(mime)

    /** Only images and PDFs may be shared as files. */
    fun isShareable(mime: String) = isImage(mime) || mime == "application/pdf"

    /** Bytes a base64 payload decodes to, without decoding it. */
    fun base64Size(payload: String): Long {
        var chars = 0L
        var padding = 0
        for (c in payload) {
            when {
                c == '=' -> padding++
                !c.isWhitespace() -> chars++
            }
        }
        return (chars + padding) / 4 * 3 - padding
    }

    /** A data: URL split into mime type, base64 flag and payload, or null. */
    fun parseDataUrl(url: String): Triple<String, Boolean, String>? {
        if (!url.startsWith("data:")) return null
        val comma = url.indexOf(',')
        if (comma < 0) return null
        val meta = url.substring(5, comma)
        return Triple(meta.substringBefore(';').trim().lowercase(), meta.endsWith(";base64"), url.substring(comma + 1))
    }

    /** A file name with no path separators or control characters, at most 120 chars. */
    fun sanitizeName(name: String, fallback: String = "download"): String {
        val clean = name.replace(UNSAFE_NAME_CHARS, "_").trim().trimStart('.')
        return clean.ifEmpty { fallback }.take(120)
    }

    /** One gallery folder name (never a path), or null if nothing usable is left. */
    fun folderName(name: String?): String? =
        name?.replace(UNSAFE_NAME_CHARS, "_")?.trim()?.trimStart('.')?.take(60)?.trim()?.ifEmpty { null }

    /** [names] with repeats renamed "photo (2).png", so files in one share don't overwrite each other. */
    fun uniqueNames(names: List<String>): List<String> {
        val used = mutableSetOf<String>()
        return names.map { name ->
            var candidate = name
            var n = 2
            while (!used.add(candidate.lowercase())) {
                val dot = name.lastIndexOf('.').takeIf { it > 0 } ?: name.length
                candidate = "${name.substring(0, dot)} ($n)${name.substring(dot)}"
                n++
            }
            candidate
        }
    }

    fun isPackageName(name: String) = name.length <= 255 && PACKAGE_NAME.matches(name)
}

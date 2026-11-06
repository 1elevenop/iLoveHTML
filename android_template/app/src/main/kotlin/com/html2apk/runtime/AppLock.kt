package com.html2apk.runtime

import android.app.Activity
import android.app.KeyguardManager
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.SystemClock
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

/**
 * Covers the page until the user unlocks with the phone's own lock:
 * fingerprint or face, or the screen-lock PIN, pattern or password.
 *
 * Locks when the app opens and when it comes back after [RELOCK_MS] or more
 * in the background. While locked the page is invisible (also to
 * accessibility services) and the cover takes every touch. On a phone with
 * no screen lock there is nothing to check, so the app opens with a hint.
 */
class AppLock(
    private val activity: Activity,
    private val root: FrameLayout,
    private val page: View,
    private val backgroundColor: Int,
    private val textColor: Int,
) {
    var locked = false
        private set
    private var cover: View? = null
    private var stoppedAt = 0L
    private var prompting = false
    /** The prompt opens by itself once per lock; after a cancel the user taps Unlock. */
    private var autoPrompted = false
    private var cancel: CancellationSignal? = null

    private val label: String by lazy { activity.applicationInfo.loadLabel(activity.packageManager).toString() }

    /** Call in onCreate after setContentView. */
    fun start(saved: Bundle?) {
        // Android 13+: the recent-apps screen shows a blank card instead of the page.
        if (Build.VERSION.SDK_INT >= 33) activity.setRecentsScreenshotEnabled(false)
        // A theme change recreates the activity; do not ask again right after an unlock.
        val unlockedAt = saved?.getLong(KEY_UNLOCKED_AT, 0L) ?: 0L
        if (unlockedAt == 0L || now() - unlockedAt >= RELOCK_MS) lock()
    }

    fun save(out: Bundle) {
        if (!locked) out.putLong(KEY_UNLOCKED_AT, now())
    }

    fun onStart() {
        if (!locked && stoppedAt > 0 && now() - stoppedAt >= RELOCK_MS) lock()
        stoppedAt = 0
    }

    fun onResume() {
        if (locked && !prompting && !autoPrompted) {
            autoPrompted = true
            authenticate()
        }
    }

    fun onStop() {
        if (!locked && !activity.isChangingConfigurations) stoppedAt = now()
    }

    fun onDestroy() {
        cancel?.cancel()
    }

    /** Result of the Android 7-9 confirm-credential screen. */
    fun onUnlockResult(resultCode: Int) {
        prompting = false
        if (resultCode == Activity.RESULT_OK) unlock()
    }

    private fun lock() {
        locked = true
        autoPrompted = false
        page.visibility = View.INVISIBLE
        if (cover == null) cover = createCover().also { root.addView(it, FrameLayout.LayoutParams(MATCH_PARENT, MATCH_PARENT)) }
        cover?.visibility = View.VISIBLE
    }

    private fun unlock() {
        locked = false
        page.visibility = View.VISIBLE
        cover?.visibility = View.GONE
    }

    private fun authenticate() {
        val keyguard = activity.getSystemService(KeyguardManager::class.java)
        if (keyguard == null || !keyguard.isDeviceSecure) {
            unlock()
            Toast.makeText(activity, "Set a screen lock on this phone to protect this app", Toast.LENGTH_LONG).show()
            return
        }
        prompting = true
        if (Build.VERSION.SDK_INT >= 29) {
            val builder = BiometricPrompt.Builder(activity).setTitle(label).setSubtitle("Unlock to continue")
            if (Build.VERSION.SDK_INT >= 30) {
                builder.setAllowedAuthenticators(
                    BiometricManager.Authenticators.BIOMETRIC_WEAK or BiometricManager.Authenticators.DEVICE_CREDENTIAL
                )
            } else {
                @Suppress("DEPRECATION")
                builder.setDeviceCredentialAllowed(true)
            }
            val signal = CancellationSignal().also { cancel = it }
            builder.build().authenticate(signal, activity.mainExecutor, object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    prompting = false
                    unlock()
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    // Cancelled or too many tries: stay locked; the Unlock button tries again.
                    prompting = false
                }
            })
        } else {
            @Suppress("DEPRECATION")
            val intent = keyguard.createConfirmDeviceCredentialIntent(label, "Unlock to continue")
            if (intent == null) {
                prompting = false
                unlock()
                return
            }
            @Suppress("DEPRECATION")
            activity.startActivityForResult(intent, REQUEST_UNLOCK)
        }
    }

    private fun createCover(): View {
        val column = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
        }
        column.addView(ImageView(activity).apply {
            setImageDrawable(activity.packageManager.getApplicationIcon(activity.applicationInfo))
        }, LinearLayout.LayoutParams(dp(88), dp(88)))
        column.addView(TextView(activity).apply {
            text = "$label is locked"
            setTextColor(textColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply { topMargin = dp(16) })
        column.addView(Button(activity).apply {
            text = "Unlock"
            setOnClickListener { if (!prompting) authenticate() }
        }, LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply { topMargin = dp(24) })
        return FrameLayout(activity).apply {
            setBackgroundColor(backgroundColor)
            isClickable = true
            isFocusable = true
            addView(column, FrameLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT, Gravity.CENTER))
        }
    }

    private fun dp(v: Int) = (v * activity.resources.displayMetrics.density).toInt()

    private fun now() = SystemClock.elapsedRealtime()

    companion object {
        const val REQUEST_UNLOCK = 4202
        const val RELOCK_MS = 30_000L
        private const val KEY_UNLOCKED_AT = "html2apk.unlockedAt"
    }
}

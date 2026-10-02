package com.strivacity.flutter.strivacity_pushnotification_example

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // True once there is no system splash screen on screen any more, or never was one to wait for.
    private var splashGone = Build.VERSION.SDK_INT < Build.VERSION_CODES.S
    private val splashGoneWaiters = mutableListOf<MethodChannel.Result>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Dart asks and we answer when ready, so the answer can't be lost to a handler that isn't
        // registered yet.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPLASH_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "untilSplashGone") {
                    result.notImplemented()
                } else if (splashGone) {
                    result.success(null)
                } else {
                    splashGoneWaiters.add(result)
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Remove the system splash screen at once instead of fading it out. This runs after Flutter
            // has drawn its first frame, because the window's first draw is held until then.
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                splashScreenView.remove()
                splashGone = true
                splashGoneWaiters.forEach { it.success(null) }
                splashGoneWaiters.clear()
            }
        }
    }

    private companion object {
        const val SPLASH_CHANNEL = "strivacity_pushnotification_example/splash"
    }
}

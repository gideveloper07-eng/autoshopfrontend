package com.example.car_app_flutter

import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Let Flutter own the full window area so it can handle
        // system bar / keyboard insets correctly on Android 15+
        // (edge-to-edge is enforced by default on Android 15 / Samsung S25)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Prevent screenshots and screen recording
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}

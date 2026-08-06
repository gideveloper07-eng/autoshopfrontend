package com.example.car_app_flutter

import android.os.Bundle
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Edge-to-edge: let the Flutter engine manage all insets itself.
        // Flutter 3.x+ handles keyboard, navigation bar, and status bar
        // insets correctly on all Android versions including Android 15
        // (Samsung S25 Ultra, Pixel 9, etc.) when this is set to false.
        //
        // DO NOT add any manual inset handling here — Flutter's
        // MediaQuery.viewInsets / viewPadding already reflect the live
        // values from the OS when setDecorFitsSystemWindows = false.
        WindowCompat.setDecorFitsSystemWindows(window, false)

        // Prevent screenshots and screen recording
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}


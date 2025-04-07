package com.example.to_do_list_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import com.baseflow.permissionhandler.PermissionHandlerPlugin
import me.carda.awesome_notifications.AwesomeNotificationsPlugin
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        flutterEngine.plugins.add(PermissionHandlerPlugin())
        flutterEngine.plugins.add(AwesomeNotificationsPlugin())
        flutterEngine.plugins.add(FlutterFirebaseMessagingPlugin())
    }
}
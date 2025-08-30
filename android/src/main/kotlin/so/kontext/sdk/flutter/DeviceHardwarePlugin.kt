package so.kontext.sdk.flutter

import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.SystemClock
import android.os.storage.StorageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DeviceHardwarePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "kontext_flutter_sdk/device_hardware")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getBootEpochMs" -> {
                val now = System.currentTimeMillis()
                result.success(now - SystemClock.elapsedRealtime())
            }
            "hasRemovableSdCard" -> {
                result.success(hasRemovableSdCard(context))
            }
            else -> result.notImplemented()
        }
    }

    private fun hasRemovableSdCard(context: Context): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // API 24+
                val sm = context.getSystemService(StorageManager::class.java)
                val vols = sm?.storageVolumes ?: return false
                vols.any { vol ->
                    val state = try { vol.state } catch (_: Exception) { null }
                    vol.isRemovable && (state == Environment.MEDIA_MOUNTED || state == Environment.MEDIA_MOUNTED_READ_ONLY)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                // API 19–23
                val dirs = context.getExternalFilesDirs(null)
                if (dirs == null || dirs.size <= 1) return false
                dirs.drop(1).any { dir ->
                    val state = Environment.getExternalStorageState(dir)
                    (state == Environment.MEDIA_MOUNTED || state == Environment.MEDIA_MOUNTED_READ_ONLY) &&
                            Environment.isExternalStorageRemovable(dir)
                }
            } else {
                // API 9–18
                val state = Environment.getExternalStorageState()
                (state == Environment.MEDIA_MOUNTED || state == Environment.MEDIA_MOUNTED_READ_ONLY) &&
                        Environment.isExternalStorageRemovable()
            }
        } catch (_: Throwable) {
            false
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

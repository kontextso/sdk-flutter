package so.kontext.sdk.flutter

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.SystemClock
import android.os.Process
import android.system.Os
import android.system.OsConstants
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class AppInfoPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "kontext_flutter_sdk/app_info")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInstallUpdateTimes" -> {
                try {
                    val pm = context.packageManager
                    val pkgInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        pm.getPackageInfo(context.packageName, PackageManager.PackageInfoFlags.of(0))
                    } else {
                        @Suppress("DEPRECATION")
                        pm.getPackageInfo(context.packageName, 0)
                    }
                    result.success(
                        mapOf(
                            "firstInstall" to pkgInfo.firstInstallTime, // ms since epoch
                            "lastUpdate" to pkgInfo.lastUpdateTime // ms since epoch
                        )
                    )
                } catch (_: Exception) {
                    result.success(null)
                }
            }

            "getProcessStartEpochMs" -> {
                try {
                    val now = System.currentTimeMillis()
                    val epoch: Long? = when {
                        // API 24+
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.N -> {
                            val startElapsed = Process.getStartElapsedRealtime()
                            val elapsedNow   = SystemClock.elapsedRealtime()
                            now - (elapsedNow - startElapsed)
                        }
                        else -> {
                            // Legacy fallback
                            val startSinceBootMs = readProcessStartSinceBootMs()
                            if (startSinceBootMs != null) {
                                val bootEpoch = now - SystemClock.elapsedRealtime()
                                bootEpoch + startSinceBootMs
                            } else {
                                null
                            }
                        }
                    }

                    result.success(epoch)
                } catch (_: Exception) {
                    result.success(null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun readProcessStartSinceBootMs(): Long? {
        return try {
            val content = File("/proc/self/stat").readText()
            val rparen = content.lastIndexOf(')')
            if (rparen == -1) return null

            val after = content.substring(rparen + 2)
            val parts = after.trim().split(Regex("\\s+"))
            val startTicks = parts[19].toLong()

            val ticksPerSec = try {
                android.system.Os.sysconf(android.system.OsConstants._SC_CLK_TCK).toDouble()
            } catch (_: Throwable) {
                100.0
            }
            ((startTicks * 1000.0) / ticksPerSec).toLong()
        } catch (_: Exception) {
            null
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

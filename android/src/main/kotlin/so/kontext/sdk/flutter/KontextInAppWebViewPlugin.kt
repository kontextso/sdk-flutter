package so.kontext.sdk.flutter

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformViewRegistry

class KontextInAppWebViewPlugin {
    fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE,
            KontextInAppWebViewFactory(
                context = binding.applicationContext,
                messenger = binding.binaryMessenger,
            )
        )
    }

    companion object {
        const val VIEW_TYPE = "kontext_flutter_sdk/in_app_webview"
    }
}

internal class KontextInAppWebViewFactory(
    private val context: Context,
    private val messenger: BinaryMessenger,
) : io.flutter.plugin.platform.PlatformViewFactory(io.flutter.plugin.common.StandardMessageCodec.INSTANCE) {
    override fun create(
        context: Context?,
        viewId: Int,
        args: Any?,
    ): io.flutter.plugin.platform.PlatformView {
        @Suppress("UNCHECKED_CAST")
        return KontextInAppWebView(
            context = context ?: this.context,
            messenger = messenger,
            viewId = viewId,
            creationParams = args as? Map<String, Any?>,
        )
    }
}

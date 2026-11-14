package com.barriocero.eras

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.charset.CodingErrorAction
import java.util.concurrent.Executors

/** One-shot Storage Access Framework exchange. No filesystem permission needed. */
class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.barriocero.eras/documents"
        private const val REQUEST_DOCUMENT = 4182
        private const val MAX_BYTES = 25_000_000
    }

    private data class Pending(
        val result: MethodChannel.Result,
        val exporting: Boolean,
        var bytes: ByteArray? = null,
    )

    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private var channel: MethodChannel? = null
    private var pending: Pending? = null
    private var destroyed = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // The API29 software emulator hangs before its first Vulkan frame.
        // Keep physical devices and explicit renderer diagnostics unchanged.
        if (Build.VERSION.SDK_INT <= 29 &&
            Build.HARDWARE in setOf("ranchu", "goldfish") &&
            !intent.hasExtra("enable-impeller")) {
            intent.putExtra("enable-impeller", false)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(::handleDocumentCall)
        }
    }

    private fun handleDocumentCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "exportDocument" && call.method != "importDocument") {
            result.notImplemented()
            return
        }
        if (destroyed) {
            result.error("activity_unavailable", "La actividad ya se cerró.", null)
            return
        }
        if (pending != null) {
            result.error("document_busy", "Ya hay un intercambio de documento en curso.", null)
            return
        }
        val exporting = call.method == "exportDocument"
        val text = call.argument<Any>("text") as? String
        val proposedName = call.argument<Any>("suggestedName") as? String ?: "barrio-cero.json"
        if (exporting && text == null) {
            result.error("invalid_argument", "Falta el texto del documento.", null)
            return
        }
        val request = Pending(result, exporting)
        pending = request
        if (!exporting) {
            launchPicker(request, Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "application/json"
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            })
            return
        }
        // Encode and bound the payload away from Android's UI thread.
        io.execute {
            try {
                val bytes = text!!.toByteArray(Charsets.UTF_8)
                if (bytes.size > MAX_BYTES) {
                    fail(request, "document_too_large", "El documento supera 25 MB.")
                } else {
                    main.post {
                        if (!destroyed && pending === request) {
                            request.bytes = bytes
                            val name = proposedName.substringAfterLast('/').substringAfterLast('\\')
                                .filter { it >= ' ' && it != '\u007f' }.take(120)
                                .ifBlank { "barrio-cero.json" }
                            launchPicker(request, Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "application/json"
                                putExtra(Intent.EXTRA_TITLE, name)
                                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                            })
                        }
                    }
                }
            } catch (_: Exception) {
                fail(request, "document_io", "No se pudo preparar el documento.")
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun launchPicker(request: Pending, intent: Intent) {
        try {
            startActivityForResult(intent, REQUEST_DOCUMENT)
        } catch (_: Exception) {
            fail(request, "document_unavailable", "No se pudo abrir el selector de documentos.")
        }
    }

    @Deprecated("Activity result API retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST_DOCUMENT) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val request = pending ?: return
        if (resultCode != Activity.RESULT_OK) {
            complete(request, null)
            return
        }
        val uri: Uri = data?.data ?: run {
            fail(request, "document_io", "El proveedor no devolvió un documento.")
            return
        }
        io.execute {
            try {
                if (request.exporting) {
                    val bytes = request.bytes ?: error("Missing payload")
                    contentResolver.openOutputStream(uri, "wt")?.use { stream ->
                        stream.write(bytes)
                        stream.flush()
                    } ?: error("Cannot open output")
                    complete(request, uri.toString())
                } else {
                    val bytes = contentResolver.openInputStream(uri)?.use { stream ->
                        val output = ByteArrayOutputStream()
                        val buffer = ByteArray(8192)
                        var total = 0
                        while (true) {
                            if (Thread.currentThread().isInterrupted) error("Interrupted")
                            val count = stream.read(buffer)
                            if (count < 0) break
                            total += count
                            if (total > MAX_BYTES) throw DocumentTooLarge()
                            output.write(buffer, 0, count)
                        }
                        output.toByteArray()
                    } ?: error("Cannot open input")
                    val decoder = Charsets.UTF_8.newDecoder()
                        .onMalformedInput(CodingErrorAction.REPORT)
                        .onUnmappableCharacter(CodingErrorAction.REPORT)
                    complete(request, decoder.decode(ByteBuffer.wrap(bytes)).toString())
                }
            } catch (_: DocumentTooLarge) {
                fail(request, "document_too_large", "El documento supera 25 MB.")
            } catch (_: java.nio.charset.CharacterCodingException) {
                fail(request, "document_encoding", "El documento no contiene texto UTF-8 válido.")
            } catch (_: Exception) {
                fail(request, "document_io", "No se pudo leer o escribir el documento.")
            }
        }
    }

    private class DocumentTooLarge : Exception()

    private fun complete(request: Pending, value: String?) {
        main.post {
            if (!destroyed && pending === request) {
                pending = null
                request.result.success(value)
            }
        }
    }

    private fun fail(request: Pending, code: String, message: String) {
        main.post {
            if (!destroyed && pending === request) {
                pending = null
                request.result.error(code, message, null)
            }
        }
    }

    override fun onDestroy() {
        destroyed = true
        channel?.setMethodCallHandler(null)
        channel = null
        pending?.result?.error("activity_unavailable", "La actividad se cerró durante el intercambio.", null)
        pending = null
        io.shutdownNow()
        super.onDestroy()
    }
}

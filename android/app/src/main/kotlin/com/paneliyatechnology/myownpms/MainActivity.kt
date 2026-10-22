package com.paneliyatechnology.myownpms

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private val channelName = "my_own_pms/pdf_storage"
    private val scannerChannelName = "my_own_pms/document_scanner"
    private val storagePermissionRequest = 4104
    private val cameraPermissionRequest = 4105
    private val documentScanRequest = 4106
    private var pendingResult: MethodChannel.Result? = null
    private var pendingCameraResult: MethodChannel.Result? = null
    private var pendingScanResult: MethodChannel.Result? = null
    private val scanReplied = AtomicBoolean(false)
    private var pendingName: String? = null
    private var pendingPath: String? = null
    private var pendingMime: String? = null
    private var pendingForcePdf: Boolean = true

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "savePdf" && call.method != "saveDownload") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val forcePdf = call.method == "savePdf"
                    val name = call.argument<String>("name") ?: if (forcePdf) "guest-folio.pdf" else "gst-report.xlsx"
                    val path = call.argument<String>("path")
                    val mime = call.argument<String>("mime")
                        ?: if (forcePdf) "application/pdf" else "application/octet-stream"
                    if (path.isNullOrBlank() || !File(path).exists()) {
                        result.error("invalid", "Missing file", null)
                        return@setMethodCallHandler
                    }
                    if (needsLegacyStoragePermission()) {
                        pendingResult = result
                        pendingName = name
                        pendingPath = path
                        pendingMime = mime
                        pendingForcePdf = forcePdf
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                            storagePermissionRequest,
                        )
                        return@setMethodCallHandler
                    }
                    saveAndReply(result, name, path, mime, forcePdf)
                } catch (error: Exception) {
                    result.error("save_failed", error.message ?: "Could not save the file.", null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, scannerChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepare" -> prepareDocumentScanner(result)
                    "scan" -> startDocumentScan(call.argument<Int>("pageLimit") ?: 10, result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == cameraPermissionRequest) {
            val cameraResult = pendingCameraResult
            pendingCameraResult = null
            if (cameraResult == null) return
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (!granted) {
                cameraResult.success(mapOf("camera" to false, "scanner" to false))
                return
            }
            ensurePlayServices(cameraResult)
            return
        }
        if (requestCode != storagePermissionRequest) return
        val result = pendingResult
        val name = pendingName
        val path = pendingPath
        val mime = pendingMime ?: "application/pdf"
        val forcePdf = pendingForcePdf
        pendingResult = null
        pendingName = null
        pendingPath = null
        pendingMime = null
        pendingForcePdf = true
        if (result == null || name == null || path == null) return
        if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            saveAndReply(result, name, path, mime, forcePdf)
        } else {
            result.error("permission", "Storage permission is required to save the file.", null)
        }
    }

    private fun prepareDocumentScanner(result: MethodChannel.Result) {
        val granted = ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            pendingCameraResult = result
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CAMERA),
                cameraPermissionRequest,
            )
            return
        }
        ensurePlayServices(result)
    }

    private fun ensurePlayServices(result: MethodChannel.Result) {
        val availability = GoogleApiAvailability.getInstance()
        val status = availability.isGooglePlayServicesAvailable(this)
        val replied = AtomicBoolean(false)
        fun reply(scannerReady: Boolean) {
            if (!replied.compareAndSet(false, true)) return
            runOnUiThread {
                runCatching { result.success(mapOf("camera" to true, "scanner" to scannerReady)) }
            }
        }
        if (status == ConnectionResult.SUCCESS) {
            reply(true)
            return
        }
        availability.makeGooglePlayServicesAvailable(this)
            .addOnSuccessListener { reply(true) }
            .addOnFailureListener { reply(false) }
    }

    private fun startDocumentScan(pageLimit: Int, result: MethodChannel.Result) {
        if (pendingScanResult != null) {
            result.success(mapOf("ok" to false, "cancelled" to false, "images" to emptyList<String>()))
            return
        }
        scanReplied.set(false)
        pendingScanResult = result
        val options = GmsDocumentScannerOptions.Builder()
            .setGalleryImportAllowed(true)
            .setPageLimit(pageLimit.coerceIn(1, 10))
            .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
            .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
            .build()
        GmsDocumentScanning.getClient(options)
            .getStartScanIntent(this)
            .addOnSuccessListener { intentSender ->
                runOnUiThread {
                    try {
                        startIntentSenderForResult(intentSender, documentScanRequest, null, 0, 0, 0)
                    } catch (_: Exception) {
                        replyScan(ok = false, cancelled = false, images = emptyList())
                    }
                }
            }
            .addOnFailureListener {
                replyScan(ok = false, cancelled = false, images = emptyList())
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == documentScanRequest) {
            if (resultCode != Activity.RESULT_OK || data == null) {
                replyScan(ok = true, cancelled = true, images = emptyList())
                return
            }
            val pages = GmsDocumentScanningResult.fromActivityResultIntent(data)?.pages
            val images = pages?.mapNotNull { copyScanImage(it.imageUri) } ?: emptyList()
            replyScan(ok = true, cancelled = false, images = images)
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    private fun replyScan(ok: Boolean, cancelled: Boolean, images: List<String>) {
        if (!scanReplied.compareAndSet(false, true)) return
        val pending = pendingScanResult
        pendingScanResult = null
        if (pending == null) return
        val payload = mapOf("ok" to ok, "cancelled" to cancelled, "images" to images)
        runOnUiThread {
            runCatching { pending.success(payload) }
        }
    }

    private fun copyScanImage(uri: Uri?): String? {
        if (uri == null) return null
        if (uri.scheme == "file") {
            val path = uri.path
            if (!path.isNullOrBlank() && File(path).exists()) return path
        }
        return try {
            val file = File(cacheDir, "id-scan-${System.currentTimeMillis()}.jpg")
            contentResolver.openInputStream(uri)?.use { input ->
                file.outputStream().use { output -> input.copyTo(output) }
            } ?: return uri.path
            file.absolutePath
        } catch (_: Exception) {
            uri.path
        }
    }

    private fun needsLegacyStoragePermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
    }

    private fun saveAndReply(
        result: MethodChannel.Result,
        name: String,
        path: String,
        mime: String = "application/pdf",
        forcePdf: Boolean = true,
    ) {
        try {
            result.success(savePdfToDownloads(name, File(path), mime, forcePdf))
        } catch (error: Exception) {
            result.error("save_failed", error.message ?: "Could not save the file.", null)
        }
    }

    private fun savePdfToDownloads(
        fileName: String,
        source: File,
        mime: String = "application/pdf",
        forcePdf: Boolean = true,
    ): String {
        val safeName = if (forcePdf) sanitizePdfName(fileName) else sanitizeDownloadName(fileName)
        val bytes = source.readBytes()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val saved = runCatching { insertIntoDownloads(safeName, bytes, mime) }.getOrNull()
            if (saved != null) return saved
        }
        val publicFile = writePublicDownload(safeName, bytes, mime)
        if (publicFile != null) return publicFile.absolutePath
        val appDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: throw IllegalStateException("Could not open device storage")
        if (!appDir.exists()) appDir.mkdirs()
        val appFile = File(appDir, safeName)
        appFile.writeBytes(bytes)
        return appFile.absolutePath
    }

    private fun insertIntoDownloads(safeName: String, bytes: ByteArray, mime: String = "application/pdf"): String {
        val resolver = applicationContext.contentResolver
        val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, safeName)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/")
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("Could not create the download")
        try {
            resolver.openOutputStream(uri)?.use { stream -> stream.write(bytes) }
                ?: throw IllegalStateException("Could not write the download")
            val published = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(uri, published, null, null)
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }
        return safeName
    }

    private fun writePublicDownload(safeName: String, bytes: ByteArray, mime: String = "application/pdf"): File? {
        return try {
            val directory = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!directory.exists() && !directory.mkdirs()) return null
            val file = File(directory, safeName)
            file.writeBytes(bytes)
            MediaScannerConnection.scanFile(this, arrayOf(file.absolutePath), arrayOf(mime), null)
            file
        } catch (_: Exception) {
            null
        }
    }

    private fun sanitizeDownloadName(fileName: String): String {
        return File(fileName).name
            .replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), "_")
            .trim()
            .ifBlank { "gst-report.xlsx" }
    }

    private fun sanitizePdfName(fileName: String): String {
        val base = File(fileName).name
            .replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), "_")
            .trim()
            .ifBlank { "guest-folio.pdf" }
        return if (base.lowercase().endsWith(".pdf")) base else "$base.pdf"
    }
}

package com.aniways.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.DocumentsContract
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.math.roundToInt
import pl.hasoft.better_player.BetterPlayerApi

class MainActivity : FlutterActivity() {
    companion object {
        private var mainEngine: FlutterEngine? = null
        private var mainActivity: MainActivity? = null

        /**
         * Restores BetterPlayerApi static references (textureRegistry and activity)
         * to the active MainActivity FlutterEngine. This fixes a critical bug where
         * background FlutterEngines (e.g. WorkManager BackgroundWorker) wipe out
         * BetterPlayerApi.textureRegistry on shutdown, causing subsequent video
         * creation to fail silently and time out after 30 seconds.
         */
        fun ensureBetterPlayerReady() {
            try {
                mainActivity?.let { act ->
                    BetterPlayerApi.activity = act
                }
                mainEngine?.let { engine ->
                    BetterPlayerApi.textureRegistry = engine.renderer
                }
            } catch (_: Exception) {}
        }
    }
    private val DEVICE_CHANNEL = "com.aniways.app/device_control"
    private val SAF_CHANNEL = "com.aniways.app/saf"
    private val INSTALLER_CHANNEL = "com.aniways.app/app_installer"
    private val REQUEST_CODE_SAF_TREE = 4221
    private var pendingTreeResult: MethodChannel.Result? = null
    private var audioManager: AudioManager? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes.layoutInDisplayCutoutMode =
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
        }
        audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        mainEngine = flutterEngine
        mainActivity = this
        ensureBetterPlayerReady()

        // 1. Device control channel (volume & brightness)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getVolume" -> {
                    try {
                        val am = audioManager ?: (getSystemService(Context.AUDIO_SERVICE) as? AudioManager)
                        if (am != null) {
                            val current = am.getStreamVolume(AudioManager.STREAM_MUSIC)
                            val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                            result.success(if (max > 0) current.toDouble() / max.toDouble() else 0.5)
                        } else {
                            result.success(0.5)
                        }
                    } catch (e: Exception) {
                        result.success(0.5)
                    }
                }
                "setVolume" -> {
                    try {
                        val volume = call.argument<Double>("volume") ?: 0.5
                        val am = audioManager ?: (getSystemService(Context.AUDIO_SERVICE) as? AudioManager)
                        if (am != null) {
                            val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                            val target = (volume * max).roundToInt().coerceIn(0, max)
                            am.setStreamVolume(AudioManager.STREAM_MUSIC, target, 0)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getBrightness" -> {
                    try {
                        val lp = window.attributes
                        val cur = lp.screenBrightness
                        if (cur >= 0f) {
                            result.success(cur.toDouble())
                        } else {
                            val sys = Settings.System.getInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS, 128)
                            result.success(sys.toDouble() / 255.0)
                        }
                    } catch (e: Exception) {
                        result.success(0.5)
                    }
                }
                "setBrightness" -> {
                    try {
                        val brightness = call.argument<Double>("brightness") ?: 0.5
                        val lp = window.attributes
                        // 0.001f prevents screen from turning completely black/off
                        lp.screenBrightness = brightness.toFloat().coerceIn(0.001f, 1.0f)
                        window.attributes = lp
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "resetBrightness" -> {
                    try {
                        val lp = window.attributes
                        lp.screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                        window.attributes = lp
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "openBatterySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "isIgnoringBatteryOptimizations" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
                            val ignoring = pm?.isIgnoringBatteryOptimizations(packageName) ?: false
                            result.success(ignoring)
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "ensureBetterPlayerReady" -> {
                    ensureBetterPlayerReady()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Storage Access Framework (SAF) channel - Mihon/Tachiyomi architecture
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SAF_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDirectory" -> {
                    if (pendingTreeResult != null) {
                        pendingTreeResult?.error("CANCELLED", "New request initiated", null)
                        pendingTreeResult = null
                    }
                    pendingTreeResult = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                            addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                                Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
                            )
                        }
                        startActivityForResult(intent, REQUEST_CODE_SAF_TREE)
                    } catch (e: Exception) {
                        pendingTreeResult = null
                        result.error("SAF_ERROR", "Failed to launch folder picker: ${e.message}", null)
                    }
                }

                "createFile" -> {
                    try {
                        val treeUriStr = call.argument<String>("treeUri")
                            ?: throw IllegalArgumentException("Missing treeUri")
                        val fileName = call.argument<String>("fileName")
                            ?: throw IllegalArgumentException("Missing fileName")
                        val bytes = call.argument<ByteArray>("bytes")
                            ?: throw IllegalArgumentException("Missing bytes")
                        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"

                        val treeUri = Uri.parse(treeUriStr)
                        val rootDir = DocumentFile.fromTreeUri(this, treeUri)
                            ?: throw IllegalStateException("Cannot access directory via tree URI")

                        val dir = resolveBackupDir(rootDir)
                        if (!dir.canWrite()) {
                            throw IllegalStateException("Directory is not writable: ${dir.uri}")
                        }

                        // Remove existing file with same name to cleanly overwrite
                        val existing = dir.findFile(fileName)
                        if (existing != null && existing.exists()) {
                            existing.delete()
                        }

                        val newFile = dir.createFile(mimeType, fileName)
                            ?: throw IllegalStateException("Failed to create file: $fileName")

                        contentResolver.openOutputStream(newFile.uri)?.use { os ->
                            os.write(bytes)
                            os.flush()
                        } ?: throw IllegalStateException("Cannot open output stream for: ${newFile.uri}")

                        result.success(mapOf(
                            "uri" to newFile.uri.toString(),
                            "name" to (newFile.name ?: fileName),
                            "size" to bytes.size.toLong()
                        ))
                    } catch (e: Exception) {
                        result.error("SAF_WRITE_ERROR", e.message, null)
                    }
                }

                "listFiles" -> {
                    try {
                        val treeUriStr = call.argument<String>("treeUri")
                            ?: throw IllegalArgumentException("Missing treeUri")
                        val extension = call.argument<String>("extension")

                        val treeUri = Uri.parse(treeUriStr)
                        val rootDir = DocumentFile.fromTreeUri(this, treeUri)
                        if (rootDir == null || !rootDir.exists() || !rootDir.canRead()) {
                            result.success(emptyList<Map<String, Any>>())
                            return@setMethodCallHandler
                        }

                        val backupDir = resolveBackupDir(rootDir)
                        val filesList = mutableListOf<Map<String, Any>>()

                        backupDir.listFiles().forEach { f ->
                            val name = f.name ?: ""
                            if (f.isFile && (extension == null || name.endsWith(".$extension", ignoreCase = true))) {
                                filesList.add(mapOf(
                                    "uri" to f.uri.toString(),
                                    "name" to name,
                                    "size" to f.length(),
                                    "lastModified" to f.lastModified()
                                ))
                            }
                        }
                        result.success(filesList)
                    } catch (e: Exception) {
                        result.error("SAF_LIST_ERROR", e.message, null)
                    }
                }

                "readFile" -> {
                    try {
                        val uriStr = call.argument<String>("uri")
                            ?: throw IllegalArgumentException("Missing uri")
                        val uri = Uri.parse(uriStr)
                        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                            ?: throw IllegalStateException("Cannot open input stream for: $uriStr")
                        result.success(bytes)
                    } catch (e: Exception) {
                        result.error("SAF_READ_ERROR", e.message, null)
                    }
                }

                "deleteFile" -> {
                    try {
                        val uriStr = call.argument<String>("uri")
                            ?: throw IllegalArgumentException("Missing uri")
                        val uri = Uri.parse(uriStr)
                        val doc = DocumentFile.fromSingleUri(this, uri)
                        val deleted = doc?.delete() ?: false
                        result.success(deleted)
                    } catch (e: Exception) {
                        result.error("SAF_DELETE_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // 3. App installer channel for in-app updates
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALLER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canRequestPackageInstalls" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            result.success(packageManager.canRequestPackageInstalls())
                        } catch (e: Exception) {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "openInstallPermissionSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        try {
                            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "installApk" -> {
                    try {
                        val filePath = call.argument<String>("filePath")
                            ?: throw IllegalArgumentException("Missing filePath")
                        val file = File(filePath)
                        if (!file.exists()) {
                            throw IllegalStateException("APK file does not exist: $filePath")
                        }

                        val contentUri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )

                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(contentUri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }

                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_SAF_TREE) {
            val callback = pendingTreeResult
            pendingTreeResult = null
            if (callback == null) return

            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val treeUri = data.data!!
                val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                try {
                    contentResolver.takePersistableUriPermission(treeUri, takeFlags)
                } catch (_: Exception) {}

                var displayPath = treeUri.lastPathSegment ?: "Aniways"
                try {
                    val docId = DocumentsContract.getTreeDocumentId(treeUri)
                    displayPath = if (docId.startsWith("primary:")) {
                        docId.substringAfter("primary:")
                    } else {
                        docId
                    }
                } catch (_: Exception) {}

                callback.success(mapOf(
                    "treeUri" to treeUri.toString(),
                    "displayPath" to displayPath
                ))
            } else {
                callback.success(null)
            }
        }
    }

    private fun resolveBackupDir(rootDir: DocumentFile): DocumentFile {
        val rootName = rootDir.name?.lowercase() ?: ""
        if (rootName == "backups" || rootName == "backup") {
            return rootDir
        }

        // Check if a "backups" subfolder exists
        val backupsDir = rootDir.findFile("backups")
        if (backupsDir != null && backupsDir.isDirectory) {
            return backupsDir
        }

        // Check if a "backup" subfolder exists
        val backupDir = rootDir.findFile("backup")
        if (backupDir != null && backupDir.isDirectory) {
            return backupDir
        }

        // Neither exists: create "backups" directory inside rootDir
        try {
            val created = rootDir.createDirectory("backups")
            if (created != null && created.isDirectory) {
                return created
            }
        } catch (_: Exception) {}

        return rootDir
    }

    override fun onResume() {
        super.onResume()
        ensureBetterPlayerReady()
    }

    override fun onPostResume() {
        super.onPostResume()
        ensureBetterPlayerReady()
    }

    override fun onDestroy() {
        if (mainActivity == this) {
            mainActivity = null
            mainEngine = null
        }
        super.onDestroy()
    }
}

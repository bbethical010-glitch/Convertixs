package com.allformat.convertix

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import androidx.documentfile.provider.DocumentFile

class MainActivity : FlutterActivity() {

    private lateinit var filePickerChannel: FilePickerChannel
    private var pendingResult: MethodChannel.Result? = null
    private var pendingToolName: String? = null
    private var allowMultiple: Boolean = false

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == FOLDER_PICK_REQUEST) {
            val result = pendingResult ?: return
            pendingResult = null
            if (resultCode != Activity.RESULT_OK || data == null || data.data == null) {
                result.success(null)
                return
            }
            val uri = data.data!!
            try {
                val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                contentResolver.takePersistableUriPermission(uri, takeFlags)
                result.success(uri.toString())
            } catch (e: Exception) {
                result.error("PERMISSION_FAILED", "Failed to take persistable permission", null)
            }
            return
        }

        if (requestCode != PICK_REQUEST) return

        val result = pendingResult ?: return
        val toolName = pendingToolName
        pendingResult = null
        pendingToolName = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return
        }

        if (toolName != null) {
            filePickerChannel.onPickResult(toolName, data)
        }

        Thread {
            try {
                val picked = mutableListOf<Map<String, String>>()

                fun processUri(uri: Uri) {
                    val name = getDisplayName(uri) ?: uri.lastPathSegment ?: "file"
                    val dest = copyToCache(uri, name)
                    if (dest != null) {
                        picked.add(mapOf("path" to dest.absolutePath, "name" to dest.name))
                    }
                }

                if (allowMultiple && data.clipData != null) {
                    val clip = data.clipData!!
                    for (i in 0 until clip.itemCount) processUri(clip.getItemAt(i).uri)
                } else {
                    data.data?.let { processUri(it) }
                }

                runOnUiThread { result.success(picked) }
            } catch (e: Exception) {
                runOnUiThread {
                    result.error("PICK_FAILED", e.message ?: "Unknown error", null)
                }
            }
        }.start()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        filePickerChannel = FilePickerChannel(this)

        // Phase 5A — output placement.
        MethodChannel(messenger, MEDIA_STORE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToCollection" -> handleSaveToCollection(call, result)
                "showInFolder" -> handleShowInFolder(call, result)
                "deleteOutputs" -> handleDeleteOutputs(call, result)
                "renameOutput" -> handleRenameOutput(call, result)
                "shareOutput" -> handleShareOutput(call, result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "com.allformat.convertix/media").setMethodCallHandler { call, result ->
            when (call.method) {
                "getMediaDuration" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        result.success(getMediaDurationMs(path))
                    } else {
                        result.error("bad_arguments", "getMediaDuration requires path", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, PICKER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchPicker", "pickFiles" -> {
                    if (pendingResult != null) {
                        result.error("PICK_IN_PROGRESS", "Another file picker is already open", null)
                        return@setMethodCallHandler
                    }

                    val toolName = call.argument<String>("toolName") ?: "default"
                    val mimeType = call.argument<String>("mimeType") ?: "*/*"
                    allowMultiple = call.argument<Boolean>("allowMultiple") ?: false
                    pendingResult = result
                    pendingToolName = toolName

                    try {
                        filePickerChannel.launchPicker(toolName, mimeType, allowMultiple, PICK_REQUEST)
                    } catch (e: android.content.ActivityNotFoundException) {
                        pendingResult = null
                        pendingToolName = null
                        result.error(
                            "PICK_FAILED",
                            "No app found that can open this file type. Please install a file manager like Files by Google.",
                            null,
                        )
                    }
                }
                "getPreferences" -> {
                    result.success(filePickerChannel.getPreferences())
                }
                "resetPreference" -> {
                    val toolName = call.argument<String>("toolName")
                    if (toolName != null) {
                        filePickerChannel.resetPreference(toolName)
                    }
                    result.success(true)
                }
                "resetAllPreferences" -> {
                    filePickerChannel.resetAllPreferences()
                    result.success(true)
                }
                "pickFolder" -> {
                    if (pendingResult != null) {
                        result.error("PICK_IN_PROGRESS", "Another picker is already open", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                    intent.addFlags(
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or 
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or 
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                    )
                    try {
                        startActivityForResult(intent, FOLDER_PICK_REQUEST)
                    } catch (e: Exception) {
                        pendingResult = null
                        result.error("PICK_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    // --- Phase 5A ---------------------------------------------------------------------------

    private fun handleSaveToCollection(call: MethodCall, result: MethodChannel.Result) {
        val sourcePath = call.argument<String>("sourcePath")
        val collection = call.argument<String>("collection")
        val relativeDir = call.argument<String>("relativeDir")
        val displayName = call.argument<String>("displayName")
        val customFolderUri = call.argument<String>("customFolderUri")

        if (sourcePath == null || collection == null || relativeDir == null || displayName == null) {
            result.error(
                "bad_arguments",
                "saveToCollection requires sourcePath, collection, relativeDir and displayName",
                null,
            )
            return
        }

        when (
            val outcome = MediaStoreWriter(applicationContext)
                .save(sourcePath, collection, relativeDir, displayName, customFolderUri)
        ) {
            is MediaStoreWriter.Result.Success -> result.success(
                mapOf(
                    "uri" to outcome.uri,
                    "displayName" to outcome.displayName,
                    "relativeDir" to outcome.relativeDir,
                ),
            )

            is MediaStoreWriter.Result.Failure -> result.error(
                outcome.code,
                outcome.message,
                null,
            )
        }
    }

    private fun handleShowInFolder(call: MethodCall, result: MethodChannel.Result) {
        val relativeDir = call.argument<String>("relativeDir")
        if (relativeDir == null) {
            result.error("bad_arguments", "showInFolder requires relativeDir", null)
            return
        }

        try {
            val uri = android.provider.DocumentsContract.buildDocumentUri(
                "com.android.externalstorage.documents", 
                "primary:$relativeDir"
            )
            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(uri, "vnd.android.document/directory")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("launch_failed", e.message, null)
        }
    }

    private fun handleDeleteOutputs(call: MethodCall, result: MethodChannel.Result) {
        val uris = call.argument<List<String>>("uris")
        if (uris == null) {
            result.error("bad_arguments", "deleteOutputs requires uris", null)
            return
        }
        result.success(MediaStoreWriter(applicationContext).delete(uris))
    }

    private fun handleRenameOutput(call: MethodCall, result: MethodChannel.Result) {
        val uri = call.argument<String>("uri")
        val newName = call.argument<String>("newName")
        if (uri == null || newName == null) {
            result.error("bad_arguments", "renameOutput requires uri and newName", null)
            return
        }
        result.success(MediaStoreWriter(applicationContext).rename(uri, newName))
    }

    private fun handleShareOutput(call: MethodCall, result: MethodChannel.Result) {
        val uriString = call.argument<String>("uri")
        if (uriString == null) {
            result.error("bad_arguments", "shareOutput requires uri", null)
            return
        }

        try {
            val uri = Uri.parse(uriString)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = contentResolver.getType(uri) ?: "*/*"
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, "Share with"))
            result.success(true)
        } catch (e: Exception) {
            result.error("share_failed", e.message, null)
        }
    }

    private fun getDisplayName(uri: Uri): String? {
        var name: String? = null
        contentResolver.query(uri, null, null, null, null)?.use { cursor: Cursor ->
            if (cursor.moveToFirst()) {
                val col = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (col >= 0) name = cursor.getString(col)
            }
        }
        return name
    }

    private fun copyToCache(uri: Uri, name: String): File? {
        return try {
            val dir = File(cacheDir, "convertix_picks").also { it.mkdirs() }
            var dest = File(dir, name)
            var counter = 1
            while (dest.exists()) {
                val stem = name.substringBeforeLast('.', name)
                val ext = name.substringAfterLast('.', "")
                val suffix = if (ext.isEmpty()) "" else ".$ext"
                dest = File(dir, "$stem-$counter$suffix")
                counter++
            }
            contentResolver.openInputStream(uri)?.use { input ->
                dest.outputStream().use { output -> input.copyTo(output) }
            }
            dest
        } catch (e: Exception) {
            null
        }
    }

    private fun getMediaDurationMs(path: String): Long {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(path)
            retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION
            )?.toLong() ?: 0L
        } catch (e: Exception) { 0L }
        finally { retriever.release() }
    }

    private companion object {
        const val MEDIA_STORE_CHANNEL = "com.allformat.convertix/media_store"
        private const val PICKER_CHANNEL = "com.allformat.convertix/file_picker"
        private const val PICK_REQUEST = 7001
        private const val FOLDER_PICK_REQUEST = 7002
    }
}

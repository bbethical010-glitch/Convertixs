package com.allformat.convertix

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.annotation.RequiresApi
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException
import androidx.documentfile.provider.DocumentFile

/**
 * Writes finished conversion outputs into Android's public media collections.
 *
 * Two write paths, chosen by API level — a single mechanism cannot cover minSdk 24 → targetSdk 36:
 *
 *  - API 29+  : MediaStore insert with RELATIVE_PATH (scoped storage). IS_PENDING guards the
 *               partial file so other apps never index a half-written output.
 *  - API 24-28: direct write beneath the external storage root, followed by a
 *               MediaScannerConnection scan so Gallery/Files pick it up.
 *
 * Both paths return a `content://` URI. The Dart side never receives a raw filesystem path —
 * Phase 5D's Open / Share actions consume the URI directly.
 */
class MediaStoreWriter(private val context: Context) {

    sealed class Result {
        data class Success(
            val uri: String,
            val displayName: String,
            val relativeDir: String,
        ) : Result()

        data class Failure(val code: String, val message: String) : Result()
    }

    /**
     * Copies [sourcePath] into [relativeDir] under the public [collection].
     *
     * @param collection one of `images`, `video`, `audio`, `documents`.
     * @param relativeDir e.g. `DCIM/Images (Convertix)` or `Documents/Convertix/Merge PDF`.
     * @param requestedName bare filename (`name_timestamp.ext`) from Dart's `buildOutputPath`.
     *                      Suffixed with ` (1)`, ` (2)`… if it already exists — never overwritten.
     */
    fun save(
        sourcePath: String,
        collection: String,
        relativeDir: String,
        requestedName: String,
        customFolderUri: String? = null,
    ): Result {
        val source = File(sourcePath)
        if (!source.exists() || !source.isFile) {
            return Result.Failure("source_missing", "Source file does not exist: $sourcePath")
        }

        val required = source.length()
        val free = availableBytes()
        if (free >= 0 && free < required) {
            return Result.Failure(
                "insufficient_storage",
                "Need ${required} bytes, only ${free} available",
            )
        }

        return try {
            if (customFolderUri != null) {
                saveToCustomFolder(source, customFolderUri, requestedName)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveViaMediaStore(source, collection, relativeDir, requestedName)
            } else {
                saveViaLegacyFile(source, relativeDir, requestedName)
            }
        } catch (e: FileNotFoundException) {
            Result.Failure("source_missing", e.message ?: "Source disappeared during write")
        } catch (e: SecurityException) {
            Result.Failure("permission_denied", e.message ?: "Storage permission denied")
        } catch (e: IOException) {
            Result.Failure("io_error", e.message ?: "Write failed")
        }
    }

    // --- Custom Folder : DocumentFile -----------------------------------------------------
    private fun saveToCustomFolder(source: File, customFolderUri: String, requestedName: String): Result {
        val treeUri = Uri.parse(customFolderUri)
        val dir = DocumentFile.fromTreeUri(context, treeUri)
            ?: return Result.Failure("permission_denied", "Cannot access the selected custom folder")
            
        if (!dir.canWrite()) {
            return Result.Failure("permission_denied", "Do not have write permission for custom folder")
        }

        val stem = requestedName.substringBeforeLast('.', requestedName)
        val ext = requestedName.substringAfterLast('.', "")
        val suffix = if (ext.isEmpty()) "" else ".$ext"

        var candidateName = requestedName
        var counter = 1
        while (dir.findFile(candidateName) != null) {
            candidateName = "$stem ($counter)$suffix"
            counter++
        }

        val mimeType = mimeTypeFor(candidateName)
        val newFile = dir.createFile(mimeType, candidateName)
            ?: return Result.Failure("io_error", "Failed to create file in custom folder")

        context.contentResolver.openOutputStream(newFile.uri)?.use { out ->
            source.inputStream().use { input -> input.copyTo(out) }
        } ?: return Result.Failure("io_error", "Could not open stream to custom folder")

        return Result.Success(newFile.uri.toString(), candidateName, "Custom Folder")
    }

    // --- API 29+ : MediaStore -------------------------------------------------------------

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun saveViaMediaStore(
        source: File,
        collection: String,
        relativeDir: String,
        requestedName: String,
    ): Result {
        val collectionUri = contentUriFor(collection)
        val normalizedDir = relativeDir.trimEnd('/')
        val displayName = uniqueMediaStoreName(collectionUri, normalizedDir, requestedName)

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeTypeFor(displayName))
            put(MediaStore.MediaColumns.RELATIVE_PATH, "$normalizedDir/")
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        // MediaStore creates the directory implicitly from RELATIVE_PATH, so a folder the user
        // deleted is silently recreated on the next save. No existence check needed.
        val itemUri = context.contentResolver.insert(collectionUri, values)
            ?: return Result.Failure("insert_failed", "MediaStore rejected the insert for $normalizedDir")

        try {
            context.contentResolver.openOutputStream(itemUri)?.use { out ->
                source.inputStream().use { input -> input.copyTo(out) }
            } ?: throw IOException("Could not open output stream for $itemUri")
        } catch (e: Exception) {
            // Roll back the pending row so a failed write leaves no phantom entry.
            runCatching { context.contentResolver.delete(itemUri, null, null) }
            throw e
        }

        context.contentResolver.update(
            itemUri,
            ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
            null,
            null,
        )

        return Result.Success(itemUri.toString(), displayName, normalizedDir)
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun contentUriFor(collection: String): Uri = when (collection) {
        "images" -> MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        "video" -> MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        "audio" -> MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        "documents" -> MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        else -> throw IllegalArgumentException("Unknown collection: $collection")
    }

    /**
     * MediaStore's own de-duplication is not contractual, so collisions are resolved explicitly:
     * `report.pdf` → `report (1).pdf`. Never overwrites an existing output.
     */
    @RequiresApi(Build.VERSION_CODES.Q)
    private fun uniqueMediaStoreName(
        collectionUri: Uri,
        relativeDir: String,
        requestedName: String,
    ): String {
        val stem = requestedName.substringBeforeLast('.', requestedName)
        val ext = requestedName.substringAfterLast('.', "")
        val suffix = if (ext.isEmpty()) "" else ".$ext"

        var candidate = requestedName
        var counter = 1
        while (mediaStoreNameExists(collectionUri, relativeDir, candidate)) {
            candidate = "$stem ($counter)$suffix"
            counter++
        }
        return candidate
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun mediaStoreNameExists(
        collectionUri: Uri,
        relativeDir: String,
        displayName: String,
    ): Boolean {
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection =
            "${MediaStore.MediaColumns.RELATIVE_PATH}=? AND ${MediaStore.MediaColumns.DISPLAY_NAME}=?"
        val args = arrayOf("$relativeDir/", displayName)
        context.contentResolver.query(collectionUri, projection, selection, args, null)
            ?.use { cursor -> return cursor.count > 0 }
        return false
    }

    // --- API 24-28 : direct file write + media scan ---------------------------------------

    private fun saveViaLegacyFile(
        source: File,
        relativeDir: String,
        requestedName: String,
    ): Result {
        @Suppress("DEPRECATION")
        val root = Environment.getExternalStorageDirectory()
            ?: return Result.Failure("no_external_storage", "External storage unavailable")

        val targetDir = File(root, relativeDir.trimEnd('/'))
        // Covers both "folder does not exist yet" and "user deleted the folder manually".
        if (!targetDir.exists() && !targetDir.mkdirs()) {
            return Result.Failure("mkdir_failed", "Could not create ${targetDir.absolutePath}")
        }

        val target = uniqueLegacyFile(targetDir, requestedName)
        source.inputStream().use { input ->
            target.outputStream().use { out -> input.copyTo(out) }
        }

        val scanned = scanForUri(target)
        return Result.Success(
            scanned ?: Uri.fromFile(target).toString(),
            target.name,
            relativeDir.trimEnd('/'),
        )
    }

    private fun uniqueLegacyFile(dir: File, requestedName: String): File {
        val stem = requestedName.substringBeforeLast('.', requestedName)
        val ext = requestedName.substringAfterLast('.', "")
        val suffix = if (ext.isEmpty()) "" else ".$ext"

        var candidate = File(dir, requestedName)
        var counter = 1
        while (candidate.exists()) {
            candidate = File(dir, "$stem ($counter)$suffix")
            counter++
        }
        return candidate
    }

    /**
     * Media indexing is asynchronous. The scan is requested so the file appears in
     * Gallery/Files, but the returned URI is best-effort — callers fall back to file://.
     */
    private fun scanForUri(file: File): String? {
        var result: String? = null
        val latch = java.util.concurrent.CountDownLatch(1)
        MediaScannerConnection.scanFile(
            context,
            arrayOf(file.absolutePath),
            arrayOf(mimeTypeFor(file.name)),
        ) { _, uri ->
            result = uri?.toString()
            latch.countDown()
        }
        // Bounded wait — never hang the platform-channel call on a slow scanner.
        runCatching { latch.await(3, java.util.concurrent.TimeUnit.SECONDS) }
        return result
    }

    // --- rename & rollback -------------------------------------------------------------------------

    fun rename(uriString: String, newName: String): Boolean {
        return runCatching {
            val uri = Uri.parse(uriString)
            if (uri.scheme == "file") {
                val file = File(uri.path ?: return@runCatching false)
                val newFile = File(file.parentFile, newName)
                file.renameTo(newFile)
            } else {
                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, newName)
                }
                context.contentResolver.update(uri, values, null, null) > 0
            }
        }.getOrDefault(false)
    }

    /**
     * Best-effort removal of outputs this app previously wrote, used to roll back a
     * multi-file publish that failed part-way through (Split PDF), or user deletes.
     */
    fun delete(uris: List<String>): Int {
        var removed = 0
        for (raw in uris) {
            val ok = runCatching {
                val uri = Uri.parse(raw)
                if (uri.scheme == "file") {
                    uri.path?.let { File(it).delete() } ?: false
                } else {
                    context.contentResolver.delete(uri, null, null) > 0
                }
            }.getOrDefault(false)
            if (ok) removed++
        }
        return removed
    }

    // --- shared helpers -------------------------------------------------------------------

    private fun mimeTypeFor(name: String): String {
        val ext = name.substringAfterLast('.', "").lowercase()
        if (ext.isEmpty()) return FALLBACK_MIME
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext)
            ?: EXTRA_MIME_TYPES[ext]
            ?: FALLBACK_MIME
    }

    /** Free bytes on external storage, or -1 when it cannot be determined. */
    private fun availableBytes(): Long = runCatching {
        @Suppress("DEPRECATION")
        val root = Environment.getExternalStorageDirectory() ?: return -1L
        val stat = StatFs(root.absolutePath)
        stat.availableBlocksLong * stat.blockSizeLong
    }.getOrDefault(-1L)

    private companion object {
        const val FALLBACK_MIME = "application/octet-stream"

        /** Extensions MimeTypeMap does not reliably resolve on older Android versions. */
        val EXTRA_MIME_TYPES = mapOf(
            "zip" to "application/zip",
            "webp" to "image/webp",
            "heic" to "image/heic",
            "m4a" to "audio/mp4",
            "opus" to "audio/opus",
            "flac" to "audio/flac",
            "mkv" to "video/x-matroska",
            "docx" to "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "pptx" to "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "xlsx" to "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        )
    }
}

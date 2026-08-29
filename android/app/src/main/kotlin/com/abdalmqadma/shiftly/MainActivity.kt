package com.abdalmqadma.shiftly

import android.app.Activity
import android.content.Intent
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.media.RingtoneManager
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {
    private val channelName = "com.abdalmqadma.shiftly/ringtone"
    private val ringtoneRequest = 6101
    private val mediaRequest = 6102
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickSystemRingtone" -> pickSystemRingtone(result)
                "pickMediaTone" -> pickMediaTone(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pickSystemRingtone(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("PICKER_BUSY", "A picker is already open", null)
            return
        }
        pendingResult = result
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_TYPE,
                RingtoneManager.TYPE_ALARM
            )
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
        }
        startActivityForResult(intent, ringtoneRequest)
    }

    private fun pickMediaTone(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("PICKER_BUSY", "A picker is already open", null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("audio/*", "video/*")
            )
        }
        startActivityForResult(intent, mediaRequest)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)
        val result = pendingResult ?: return
        if (requestCode != ringtoneRequest && requestCode != mediaRequest) return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        try {
            val uri = if (requestCode == ringtoneRequest) {
                data?.getParcelableExtra<Uri>(
                    RingtoneManager.EXTRA_RINGTONE_PICKED_URI
                )
            } else {
                data?.data
            }

            if (uri == null) {
                result.success(null)
                return
            }

            val choice = if (requestCode == ringtoneRequest) {
                copySystemRingtone(uri)
            } else {
                copyMediaTone(uri)
            }
            result.success(choice)
        } catch (error: Exception) {
            result.error("TONE_ERROR", error.message, null)
        }
    }

    private fun copySystemRingtone(uri: Uri): Map<String, String> {
        val title = RingtoneManager.getRingtone(this, uri)
            ?.getTitle(this)
            ?: "نغمة من الهاتف"
        val target = newToneFile("system_tone", ".ogg")
        contentResolver.openInputStream(uri).use { input ->
            requireNotNull(input) { "Unable to open ringtone" }
            target.outputStream().use { output -> input.copyTo(output) }
        }
        return mapOf("path" to target.absolutePath, "name" to title)
    }

    private fun copyMediaTone(uri: Uri): Map<String, String> {
        val mime = contentResolver.getType(uri).orEmpty()
        val originalName = displayName(uri)
        return if (mime.startsWith("video/")) {
            val target = newToneFile("video_audio", ".m4a")
            extractAudio(uri, target)
            mapOf(
                "path" to target.absolutePath,
                "name" to "صوت $originalName"
            )
        } else {
            val extension = originalName.substringAfterLast('.', "mp3")
            val target = newToneFile("custom_audio", ".$extension")
            contentResolver.openInputStream(uri).use { input ->
                requireNotNull(input) { "Unable to open audio file" }
                target.outputStream().use { output -> input.copyTo(output) }
            }
            mapOf("path" to target.absolutePath, "name" to originalName)
        }
    }

    private fun extractAudio(uri: Uri, target: File) {
        val extractor = MediaExtractor()
        val descriptor = contentResolver.openAssetFileDescriptor(uri, "r")
            ?: error("Unable to open video")
        descriptor.use {
            extractor.setDataSource(
                it.fileDescriptor,
                it.startOffset,
                it.length
            )
        }

        var audioTrack = -1
        var format: MediaFormat? = null
        for (index in 0 until extractor.trackCount) {
            val candidate = extractor.getTrackFormat(index)
            val mime = candidate.getString(MediaFormat.KEY_MIME).orEmpty()
            if (mime.startsWith("audio/")) {
                audioTrack = index
                format = candidate
                break
            }
        }
        require(audioTrack >= 0 && format != null) {
            "The selected video has no audio track"
        }

        extractor.selectTrack(audioTrack)
        val muxer = MediaMuxer(
            target.absolutePath,
            MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4
        )
        val outputTrack = muxer.addTrack(format)
        muxer.start()

        val maxSize = if (format.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
            format.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE)
        } else {
            1024 * 1024
        }
        val buffer = ByteBuffer.allocate(maxSize.coerceAtLeast(256 * 1024))
        val info = MediaCodec.BufferInfo()

        try {
            while (true) {
                buffer.clear()
                val size = extractor.readSampleData(buffer, 0)
                if (size < 0) break
                info.offset = 0
                info.size = size
                info.presentationTimeUs = extractor.sampleTime
                info.flags = extractor.sampleFlags
                muxer.writeSampleData(outputTrack, buffer, info)
                extractor.advance()
            }
        } finally {
            extractor.release()
            muxer.stop()
            muxer.release()
        }
    }

    private fun displayName(uri: Uri): String {
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getString(0)
            }
        }
        return "ملف مخصص"
    }

    private fun newToneFile(prefix: String, extension: String): File {
        filesDir.listFiles()
            ?.filter { it.name.startsWith("shiftly_tone_") }
            ?.forEach { it.delete() }
        return File(
            filesDir,
            "shiftly_tone_${prefix}_${System.currentTimeMillis()}$extension"
        )
    }
}

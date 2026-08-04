package org.godotengine.plugin.quickactionsappshortcuts

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.Toast

/**
 * Opens a mailto: composer from a static app shortcut and finishes immediately.
 * Must never initialize the Godot engine.
 */
class FeedbackShortcutActivity : Activity() {
	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)

		try {
			val meta = applicationInfo.metaData
			if (meta == null) {
				showErrorAndFinish(getString(R.string.qaas_error_missing_config))
				return
			}

			val recipient = meta.getString(META_RECIPIENT)?.trim().orEmpty()
			if (recipient.isEmpty()) {
				showErrorAndFinish(getString(R.string.qaas_error_missing_config))
				return
			}

			// Templates come from localized string resources (export overlay + AAR fallbacks).
			val subjectTemplate = localizedTemplate(
				R.string.qaas_subject_template,
				R.string.qaas_default_subject_template,
			)
			val bodyTemplate = localizedTemplate(
				R.string.qaas_body_template,
				R.string.qaas_default_body_template,
			)

			val values = diagnosticValues()
			val subject = applyTemplate(subjectTemplate, values)
			val body = applyTemplate(bodyTemplate, values)

			// ACTION_SENDTO + mailto: scheme is what mail apps filter on.
			// Prefer extras over stuffing the URI so clients parse reliably.
			val intent = Intent(Intent.ACTION_SENDTO).apply {
				data = Uri.parse("mailto:")
				putExtra(Intent.EXTRA_EMAIL, arrayOf(recipient))
				putExtra(Intent.EXTRA_SUBJECT, subject)
				putExtra(Intent.EXTRA_TEXT, body)
			}

			try {
				startActivity(intent)
			} catch (_: ActivityNotFoundException) {
				showErrorAndFinish(getString(R.string.qaas_error_no_mail_client))
				return
			}
		} catch (error: Exception) {
			Log.e(TAG, "Failed to open feedback mailto", error)
			showErrorAndFinish(getString(R.string.qaas_error_generic))
			return
		}

		finish()
	}

	private fun localizedTemplate(primaryRes: Int, fallbackRes: Int): String {
		return runCatching {
			val value = getString(primaryRes)
			if (value.isBlank() || value == primaryRes.toString()) {
				getString(fallbackRes)
			} else {
				value
			}
		}.getOrElse {
			getString(fallbackRes)
		}
	}

	private fun diagnosticValues(): Map<String, String> {
		val appName = runCatching {
			val appInfo: ApplicationInfo = applicationInfo
			packageManager.getApplicationLabel(appInfo).toString()
		}.getOrDefault(packageName)

		val version = runCatching {
			val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
				packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
			} else {
				@Suppress("DEPRECATION")
				packageManager.getPackageInfo(packageName, 0)
			}
			info.versionName ?: ""
		}.getOrDefault("")

		val osVersion = "Android ${Build.VERSION.RELEASE}"
		val deviceModel = listOf(Build.MANUFACTURER, Build.MODEL)
			.filter { it.isNotBlank() }
			.joinToString(" ")
			.ifBlank { Build.MODEL }

		return mapOf(
			"{{APP_NAME}}" to appName,
			"{{APP_VERSION}}" to version,
			"{{OS_VERSION}}" to osVersion,
			"{{DEVICE_MODEL}}" to deviceModel,
		)
	}

	private fun applyTemplate(template: String, values: Map<String, String>): String {
		var result = template
		values.forEach { (key, value) ->
			result = result.replace(key, value)
		}
		return result
	}

	private fun showErrorAndFinish(message: String) {
		Toast.makeText(applicationContext, message, Toast.LENGTH_LONG).show()
		finish()
	}

	companion object {
		private const val TAG = "QAASFeedbackShortcut"
		private const val META_RECIPIENT =
			"org.godotengine.plugin.quickactionsappshortcuts.RECIPIENT"
	}
}

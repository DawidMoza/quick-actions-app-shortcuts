extends RefCounted
class_name QuickActionsAppShortcuts

const FeedbackConfig = preload("res://addons/QuickActionsAppShortcutsPlugin/feedback_config.gd")


# Returns localized feedback values without opening the mail client.
# subject/body have diagnostic placeholders filled; *_template retain the raw config values.
static func get_feedback_data(locale: String = "") -> Dictionary:
	var config: QuickActionsFeedbackConfig = FeedbackConfig.load_from_project()
	if config == null or not config.present or not config.load_error.is_empty():
		return {}
	if config.recipient.is_empty():
		return {}

	var selected_locale := _best_locale(config, locale)
	var strings: Dictionary = config.strings_for_locale(selected_locale)
	var values := diagnostic_values()
	var subject_template := str(strings["subject_template"])
	var body_template := str(strings["body_template"])
	return {
		"recipient": config.recipient,
		"locale": selected_locale,
		"subject_template": subject_template,
		"body_template": body_template,
		"subject": _apply_template(subject_template, values),
		"body": _apply_template(body_template, values),
	}


static func get_recipient() -> String:
	return str(get_feedback_data().get("recipient", ""))


static func is_configured() -> bool:
	return not get_recipient().is_empty()


static func diagnostic_values() -> Dictionary:
	var app_name := str(ProjectSettings.get_setting("application/config/name", ""))
	var version := str(ProjectSettings.get_setting("application/config/version", "")).strip_edges()
	# Export-preset version is not available at runtime; fall back to the installed
	# package version when Project Settings version is left empty.
	if version.is_empty():
		version = _native_app_version()
	var os_version := "%s %s" % [OS.get_name(), OS.get_version()]
	var device := OS.get_model_name()
	if device.is_empty():
		device = OS.get_name()
	return {
		"{{APP_NAME}}": app_name,
		"{{APP_VERSION}}": version,
		"{{OS_VERSION}}": os_version,
		"{{DEVICE_MODEL}}": device,
	}


static func _native_app_version() -> String:
	match OS.get_name():
		"Android":
			return _android_app_version()
		_:
			return ""


static func _android_app_version() -> String:
	var android_runtime = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		return ""
	var activity = android_runtime.getActivity()
	if activity == null:
		return ""
	var package_manager = activity.getPackageManager()
	var package_name = activity.getPackageName()
	if package_manager == null or str(package_name).is_empty():
		return ""
	var package_info = package_manager.getPackageInfo(package_name, 0)
	if package_info == null:
		return ""
	var version_name = package_info.versionName
	if version_name == null:
		return ""
	return str(version_name).strip_edges()


static func _apply_template(template: String, values: Dictionary) -> String:
	var result := template
	for key in values.keys():
		result = result.replace(str(key), str(values[key]))
	return result


static func _best_locale(config: QuickActionsFeedbackConfig, preferred: String) -> String:
	var locale := preferred
	if locale.is_empty():
		locale = TranslationServer.get_locale()
	locale = locale.replace("-", "_")
	if config.localizations.has(locale):
		return locale
	var lang := locale.get_slice("_", 0)
	if config.localizations.has(lang):
		return lang
	return locale

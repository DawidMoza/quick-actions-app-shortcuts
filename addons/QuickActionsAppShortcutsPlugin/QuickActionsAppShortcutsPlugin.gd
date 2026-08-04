@tool
extends EditorPlugin

const PLUGIN_NAME := "QuickActionsAppShortcutsPlugin"
const PLUGIN_PATH := "res://addons/QuickActionsAppShortcutsPlugin"
const FeedbackConfig = preload("res://addons/QuickActionsAppShortcutsPlugin/feedback_config.gd")
const GENERATED_IOS_DIR := "res://addons/QuickActionsAppShortcutsPlugin/generated/ios"

const ANDROID_ACTIVITY_METADATA := """
<meta-data
	android:name="android.app.shortcuts"
	android:resource="@xml/quick_actions_app_shortcuts" />
"""

const ANDROID_APPLICATION_METADATA_TEMPLATE := """
<meta-data
	android:name="org.godotengine.plugin.quickactionsappshortcuts.RECIPIENT"
	android:value="%s" />
"""

const ANDROID_SHORTCUTS_XML_TEMPLATE := """<?xml version="1.0" encoding="utf-8"?>
<shortcuts xmlns:android="http://schemas.android.com/apk/res/android">
	<shortcut
		android:shortcutId="qaas_send_feedback"
		android:enabled="true"
		android:icon="@drawable/%s"
		android:shortcutShortLabel="@string/qaas_shortcut_feedback_short"
		android:shortcutLongLabel="@string/qaas_shortcut_feedback_long">
		<intent
			android:action="android.intent.action.VIEW"
			android:targetPackage="%s"
			android:targetClass="org.godotengine.plugin.quickactionsappshortcuts.FeedbackShortcutActivity" />
	</shortcut>
</shortcuts>
"""

const ANDROID_STRINGS_XML_TEMPLATE := """<?xml version="1.0" encoding="utf-8"?>
<resources>
	<string name="qaas_shortcut_feedback_short">%s</string>
	<string name="qaas_shortcut_feedback_long">%s</string>
	<string name="qaas_subject_template">%s</string>
	<string name="qaas_body_template">%s</string>
</resources>
"""

const IOS_SHORTCUT_PLIST_TEMPLATE := """
<key>UIApplicationShortcutItems</key>
<array>
	<dict>
		<key>UIApplicationShortcutItemType</key>
		<string>%s</string>
		<key>UIApplicationShortcutItemTitle</key>
		<string>%s</string>
		<key>UIApplicationShortcutItemIconType</key>
		<string>%s</string>
	</dict>
</array>
<key>QAASFeedbackRecipient</key>
<string>%s</string>
"""

var android_export_plugin: AndroidExportPlugin
var ios_export_plugin: IosExportPlugin


func _enter_tree() -> void:
	android_export_plugin = AndroidExportPlugin.new()
	ios_export_plugin = IosExportPlugin.new()
	add_export_plugin(android_export_plugin)
	add_export_plugin(ios_export_plugin)


func _exit_tree() -> void:
	if android_export_plugin:
		remove_export_plugin(android_export_plugin)
		android_export_plugin = null
	if ios_export_plugin:
		remove_export_plugin(ios_export_plugin)
		ios_export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	var _config: QuickActionsFeedbackConfig
	var _config_loaded := false

	func _get_name() -> String:
		return PLUGIN_NAME

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		_ensure_config()
		if _config == null or not _config.present:
			return PackedStringArray()
		var variant := "debug" if debug else "release"
		return PackedStringArray(["%s/bin/%s/%s-%s.aar" % [PLUGIN_NAME, variant, PLUGIN_NAME, variant]])

	func _get_android_manifest_activity_element_contents(
		_platform: EditorExportPlatform, _debug: bool
	) -> String:
		_ensure_config()
		if _config == null or not _config.present:
			return ""
		return ANDROID_ACTIVITY_METADATA

	func _get_android_manifest_application_element_contents(
		_platform: EditorExportPlatform, _debug: bool
	) -> String:
		_ensure_config()
		if _config == null or not _config.present:
			return ""
		return ANDROID_APPLICATION_METADATA_TEMPLATE % _config.xml_escape(_config.recipient)

	func _export_begin(_features: PackedStringArray, is_debug: bool, _path: String, _flags: int) -> void:
		# Godot may invoke every export plugin; only act on Android presets.
		if not _supports_platform(get_export_platform()):
			return
		_config_loaded = false
		_ensure_config()
		if _config == null:
			return
		if not _config.load_error.is_empty():
			_export_error(_config.load_error)
			return
		if not _config.present:
			return
		if not get_option("gradle_build/use_gradle_build"):
			_export_error("Android Gradle Build must be enabled to ship the feedback shortcut AAR.")
			return
		var variant := "debug" if is_debug else "release"
		var aar_path := "%s/bin/%s/%s-%s.aar" % [PLUGIN_PATH, variant, PLUGIN_NAME, variant]
		if not FileAccess.file_exists(aar_path):
			_export_error("Missing Android library at %s. Build it with scripts/build_android.sh." % aar_path)
			return

		var write_error := _write_android_overlay_resources()
		if not write_error.is_empty():
			_export_error(write_error)

	func _write_android_overlay_resources() -> String:
		var res_root := _android_res_root()
		if res_root.is_empty():
			return "Android build template not found. Use Project → Install Android Build Template, then export again."

		var xml_dir := res_root.path_join("xml")
		var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(xml_dir))
		if err != OK and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(xml_dir)):
			return "Could not create %s." % xml_dir

		var package_name := str(get_option("package/unique_name")).strip_edges()
		if package_name.is_empty():
			return "Android package/unique_name is empty; cannot bind the feedback shortcut intent."

		var shortcuts_path := xml_dir.path_join("quick_actions_app_shortcuts.xml")
		err = _write_text(
			shortcuts_path,
			ANDROID_SHORTCUTS_XML_TEMPLATE % [_config.android_icon_drawable(), package_name]
		)
		if err != OK:
			return "Could not write %s." % shortcuts_path

		var default_strings := {
			"title": _config.title,
			"subject_template": _config.resolved_subject_template(),
			"body_template": _config.resolved_body_template(),
		}
		err = _write_android_strings("values", default_strings)
		if err != OK:
			return "Could not write default Android shortcut strings."

		for locale in _config.localizations.keys():
			var folder := _config.android_values_folder(str(locale))
			err = _write_android_strings(folder, _config.strings_for_locale(str(locale)))
			if err != OK:
				return "Could not write Android shortcut strings for locale '%s'." % locale
		return ""

	func _write_android_strings(values_folder: String, strings: Dictionary) -> Error:
		var res_root := _android_res_root()
		var dir_path := res_root.path_join(values_folder)
		var mk := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
		if mk != OK and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
			return mk
		var title := _config.xml_escape(str(strings["title"]))
		var subject := _config.xml_escape(str(strings["subject_template"]))
		var body := _config.xml_escape(str(strings["body_template"]))
		return _write_text(
			dir_path.path_join("qaas_strings.xml"),
			ANDROID_STRINGS_XML_TEMPLATE % [title, title, subject, body]
		)

	func _android_res_root() -> String:
		var candidates: PackedStringArray = [
			"res://android/build/src/main/res",
			"res://android/build/res",
		]
		for candidate in candidates:
			var parent: String = candidate.get_base_dir()
			if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(parent)):
				return candidate
		return ""

	func _write_text(path: String, contents: String) -> Error:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			return FileAccess.get_open_error()
		file.store_string(contents)
		return OK

	func _export_error(message: String) -> void:
		get_export_platform().add_message(
			EditorExportPlatform.EXPORT_MESSAGE_ERROR,
			PLUGIN_NAME,
			message
		)

	func _ensure_config() -> void:
		if _config_loaded:
			return
		_config = FeedbackConfig.load_from_project()
		_config_loaded = true


class IosExportPlugin extends EditorExportPlugin:
	var _config: QuickActionsFeedbackConfig
	var _config_loaded := false

	func _get_name() -> String:
		return PLUGIN_NAME

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		if platform is EditorExportPlatformIOS:
			return true
		return platform.get_os_name() == "iOS"

	func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
		if not _supports_platform(get_export_platform()):
			return
		_config_loaded = false
		_ensure_config()
		if _config == null:
			return
		if not _config.load_error.is_empty():
			_export_error(_config.load_error)
			return
		if not _config.present:
			return

		var xcframework := "res://ios/plugins/QuickActionsAppShortcutsPlugin.xcframework"
		var gdip := "res://ios/plugins/QuickActionsAppShortcutsPlugin.gdip"
		if not FileAccess.file_exists(gdip):
			_export_error("Missing iOS plugin at %s." % gdip)
			return
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(xcframework)):
			_export_error("Missing iOS xcframework at %s. Build it with scripts/build_ios.sh." % xcframework)
			return
		if not get_option("plugins/QuickActionsAppShortcutsPlugin"):
			_export_error(
				"Enable QuickActionsAppShortcutsPlugin under the iOS export preset's Plugins options."
			)
			return

		add_apple_embedded_platform_plist_content(
			IOS_SHORTCUT_PLIST_TEMPLATE % [
				FeedbackConfig.SHORTCUT_TYPE,
				_config.plist_escape(_config.title),
				_config.ios_icon_type(),
				_config.plist_escape(_config.recipient),
			]
		)

		var gen_error := _write_ios_localization_files()
		if not gen_error.is_empty():
			_export_error(gen_error)
			return

	func _write_ios_localization_files() -> String:
		var abs_root := ProjectSettings.globalize_path(GENERATED_IOS_DIR)
		var mk := DirAccess.make_dir_recursive_absolute(abs_root)
		if mk != OK and not DirAccess.dir_exists_absolute(abs_root):
			return "Could not create %s." % GENERATED_IOS_DIR

		var locales := {"en": _config.strings_for_locale("en")}
		# strings_for_locale("en") falls back to defaults when no [feedback.en] — good.
		for locale in _config.localizations.keys():
			locales[str(locale)] = _config.strings_for_locale(str(locale))

		for locale in locales.keys():
			var strings: Dictionary = locales[locale]
			var lproj := _config.ios_lproj_name(str(locale))
			var dir_res := GENERATED_IOS_DIR.path_join("%s.lproj" % lproj)
			var dir_abs := ProjectSettings.globalize_path(dir_res)
			mk = DirAccess.make_dir_recursive_absolute(dir_abs)
			if mk != OK and not DirAccess.dir_exists_absolute(dir_abs):
				return "Could not create %s." % dir_res

			var title := str(strings["title"])
			var subject := str(strings["subject_template"])
			var body := str(strings["body_template"])

			# Skip English InfoPlist.strings — Godot's iOS template already ships
			# en.lproj/InfoPlist.strings, and a second copy fails Xcode archive.
			# The English shortcut title comes from the injected Info.plist entry.
			if lproj != "en":
				var info_plist := "\"%s\" = \"%s\";\n" % [
					_config.strings_escape(_config.title),
					_config.strings_escape(title),
				]
				var info_path := dir_res.path_join("InfoPlist.strings")
				if _write_text(info_path, info_plist) != OK:
					return "Could not write %s." % info_path
				add_apple_embedded_platform_bundle_file(info_path)

			var localizable := (
				"\"QAAS_SUBJECT_TEMPLATE\" = \"%s\";\n\"QAAS_BODY_TEMPLATE\" = \"%s\";\n"
				% [_config.strings_escape(subject), _config.strings_escape(body)]
			)
			var localizable_path := dir_res.path_join("Localizable.strings")
			if _write_text(localizable_path, localizable) != OK:
				return "Could not write %s." % localizable_path
			add_apple_embedded_platform_bundle_file(localizable_path)

		return ""

	func _write_text(path: String, contents: String) -> Error:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			return FileAccess.get_open_error()
		file.store_string(contents)
		return OK

	func _export_error(message: String) -> void:
		get_export_platform().add_message(
			EditorExportPlatform.EXPORT_MESSAGE_ERROR,
			PLUGIN_NAME,
			message
		)

	func _ensure_config() -> void:
		if _config_loaded:
			return
		_config = FeedbackConfig.load_from_project()
		_config_loaded = true

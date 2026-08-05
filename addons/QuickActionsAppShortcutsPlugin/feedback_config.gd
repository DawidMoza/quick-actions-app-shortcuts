@tool
extends RefCounted
class_name QuickActionsFeedbackConfig

const CONFIG_PATH := "res://quick_actions_app_shortcuts.cfg"
const SHORTCUT_TYPE := "org.godotengine.plugin.quickactionsappshortcuts.feedback"
const DEFAULT_TITLE := "Send feedback"
const DEFAULT_ICON := "compose"
const DEFAULT_SUBJECT_TEMPLATE := "Feedback for {{APP_NAME}}"
const DEFAULT_BODY_TEMPLATE := "Please share your feedback above this line.\n\nApp: {{APP_NAME}}\nVersion: {{APP_VERSION}}\nOS: {{OS_VERSION}}\nDevice: {{DEVICE_MODEL}}"

const PLACEHOLDERS := [
	"{{APP_NAME}}",
	"{{APP_VERSION}}",
	"{{OS_VERSION}}",
	"{{DEVICE_MODEL}}",
]

# Cross-platform icon ids → Android drawable / iOS UIApplicationShortcutIconType
const ICONS := {
	"compose": {"android": "ic_shortcut_mail", "ios": "UIApplicationShortcutIconTypeCompose"},
	"mail": {"android": "ic_shortcut_mail", "ios": "UIApplicationShortcutIconTypeMail"},
	"message": {"android": "ic_shortcut_message", "ios": "UIApplicationShortcutIconTypeMessage"},
	"love": {"android": "ic_shortcut_love", "ios": "UIApplicationShortcutIconTypeLove"},
	"share": {"android": "ic_shortcut_share", "ios": "UIApplicationShortcutIconTypeShare"},
	"bookmark": {"android": "ic_shortcut_bookmark", "ios": "UIApplicationShortcutIconTypeBookmark"},
	"search": {"android": "ic_shortcut_search", "ios": "UIApplicationShortcutIconTypeSearch"},
	"home": {"android": "ic_shortcut_home", "ios": "UIApplicationShortcutIconTypeHome"},
}

# True when the project config file exists and was loaded for export injection.
var present: bool = false
var recipient: String = ""
var subject_template: String = ""
var body_template: String = ""
var title: String = DEFAULT_TITLE
var icon: String = DEFAULT_ICON
# locale code -> { "title", "subject_template", "body_template" } (only set keys present)
var localizations: Dictionary = {}
var load_error: String = ""


# Loads project-root feedback config. Missing file is a clean no-op (disable the plugin instead).
static func load_from_project() -> QuickActionsFeedbackConfig:
	var config := QuickActionsFeedbackConfig.new()
	if not FileAccess.file_exists(CONFIG_PATH):
		return config

	var file := ConfigFile.new()
	var err := file.load(CONFIG_PATH)
	if err != OK:
		config.load_error = "Failed to load %s (error %s)." % [CONFIG_PATH, error_string(err)]
		return config

	if not file.has_section("feedback"):
		config.load_error = "%s is missing a [feedback] section." % CONFIG_PATH
		return config

	config.present = true
	config.recipient = str(file.get_value("feedback", "recipient", "")).strip_edges()
	config.subject_template = str(file.get_value("feedback", "subject_template", "")).strip_edges()
	config.body_template = str(file.get_value("feedback", "body_template", "")).strip_edges()
	config.title = str(file.get_value("feedback", "title", DEFAULT_TITLE)).strip_edges()
	if config.title.is_empty():
		config.title = DEFAULT_TITLE
	config.icon = str(file.get_value("feedback", "icon", DEFAULT_ICON)).strip_edges().to_lower()
	if config.icon.is_empty():
		config.icon = DEFAULT_ICON

	for section in file.get_sections():
		if section == "feedback":
			continue
		if not section.begins_with("feedback."):
			continue
		var locale := section.substr("feedback.".length()).strip_edges()
		if locale.is_empty():
			config.load_error = "Invalid localization section [%s]." % section
			return config

		var entry := {}
		var localized_title := str(file.get_value(section, "title", "")).strip_edges()
		var localized_subject := str(file.get_value(section, "subject_template", "")).strip_edges()
		var localized_body := str(file.get_value(section, "body_template", "")).strip_edges()
		if localized_title.is_empty() and localized_subject.is_empty() and localized_body.is_empty():
			config.load_error = "[%s] must set at least one of: title, subject_template, body_template." % section
			return config
		if not localized_title.is_empty():
			entry["title"] = localized_title
		if not localized_subject.is_empty():
			entry["subject_template"] = localized_subject
		if not localized_body.is_empty():
			entry["body_template"] = localized_body
		config.localizations[locale] = entry

	config.load_error = config._validate()
	return config


func resolved_subject_template() -> String:
	return subject_template if not subject_template.is_empty() else DEFAULT_SUBJECT_TEMPLATE


func resolved_body_template() -> String:
	return body_template if not body_template.is_empty() else DEFAULT_BODY_TEMPLATE


# Merged strings for a locale (falls back to default [feedback] values).
func strings_for_locale(locale: String) -> Dictionary:
	var entry: Dictionary = localizations.get(locale, {})
	return {
		"title": str(entry.get("title", title)),
		"subject_template": str(entry.get("subject_template", resolved_subject_template())),
		"body_template": str(entry.get("body_template", resolved_body_template())),
	}


func _validate() -> String:
	if recipient.is_empty():
		return "feedback.recipient is required."
	if not _is_valid_email(recipient):
		return "feedback.recipient must be a valid email address."
	if not ICONS.has(icon):
		return "feedback.icon must be one of: %s" % ", ".join(ICONS.keys())

	var subject_err := _validate_placeholders(subject_template, "subject_template")
	if not subject_err.is_empty():
		return subject_err
	var body_err := _validate_placeholders(body_template, "body_template")
	if not body_err.is_empty():
		return body_err

	for locale in localizations.keys():
		var entry: Dictionary = localizations[locale]
		if entry.has("subject_template"):
			subject_err = _validate_placeholders(str(entry["subject_template"]), "%s.subject_template" % locale)
			if not subject_err.is_empty():
				return subject_err
		if entry.has("body_template"):
			body_err = _validate_placeholders(str(entry["body_template"]), "%s.body_template" % locale)
			if not body_err.is_empty():
				return body_err
	return ""


func _validate_placeholders(text: String, field_name: String) -> String:
	if text.is_empty():
		return ""
	var re := RegEx.new()
	re.compile("\\{\\{[^}]+\\}\\}")
	for m in re.search_all(text):
		var token := m.get_string()
		if token not in PLACEHOLDERS:
			return "Unsupported placeholder %s in feedback.%s. Supported: %s" % [
				token, field_name, ", ".join(PLACEHOLDERS)
			]
	return ""


func _is_valid_email(value: String) -> bool:
	var re := RegEx.new()
	re.compile("^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$")
	return re.search(value.to_upper()) != null


func android_icon_drawable() -> String:
	return ICONS[icon]["android"]


func ios_icon_type() -> String:
	return ICONS[icon]["ios"]


# Maps cfg locale codes to Android values-XX folder suffixes.
func android_values_folder(locale: String) -> String:
	var normalized := locale.replace("-", "_")
	match normalized:
		"zh_CN", "zh_Hans", "zh":
			return "values-zh-rCN"
		"zh_TW", "zh_Hant":
			return "values-zh-rTW"
		"pt_BR":
			return "values-pt-rBR"
		"pt_PT":
			return "values-pt-rPT"
		_:
			if "_" in normalized:
				var parts := normalized.split("_")
				return "values-%s-r%s" % [parts[0], parts[1]]
			return "values-%s" % normalized


# Maps cfg locale codes to iOS .lproj directory names.
func ios_lproj_name(locale: String) -> String:
	var normalized := locale.replace("-", "_")
	match normalized:
		"zh_CN", "zh":
			return "zh-Hans"
		"zh_TW":
			return "zh-Hant"
		"pt_BR":
			return "pt-BR"
		"pt_PT":
			return "pt-PT"
		_:
			return normalized.replace("_", "-")


# Escape for Android <string> resources / XML attribute values.
# Real newlines must become \n escapes — aapt collapses raw whitespace otherwise.
func xml_escape(value: String) -> String:
	return (
		value
		.replace("\\", "\\\\")
		.replace("\n", "\\n")
		.replace("\t", "\\t")
		.replace("&", "&amp;")
		.replace("\"", "&quot;")
		.replace("'", "&apos;")
		.replace("<", "&lt;")
		.replace(">", "&gt;")
	)


func plist_escape(value: String) -> String:
	return (
		value
		.replace("&", "&amp;")
		.replace("<", "&lt;")
		.replace(">", "&gt;")
	)


func strings_escape(value: String) -> String:
	return (
		value
		.replace("\\", "\\\\")
		.replace("\"", "\\\"")
		.replace("\n", "\\n")
	)

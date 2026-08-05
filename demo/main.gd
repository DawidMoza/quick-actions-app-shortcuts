extends Control

@onready var _status: Label = $Margin/VBox/Status
@onready var _send_button: Button = $Margin/VBox/SendFeedbackButton


func _ready() -> void:
	_send_button.pressed.connect(_on_send_feedback_pressed)
	_refresh_status()


func _refresh_status() -> void:
	var feedback := QuickActionsAppShortcuts.get_feedback_data()
	if feedback.is_empty():
		_status.text = "No feedback config found.\n\nCopy quick_actions_app_shortcuts.cfg.example to res://quick_actions_app_shortcuts.cfg."
		_send_button.disabled = true
		return
	_send_button.disabled = false
	_status.text = (
		"Home-screen shortcut: long-press the app icon → Send feedback (no game code).\n\n"
		+ "In-game API: tap the button below. Same config via QuickActionsAppShortcuts.get_feedback_data().\n\n"
		+ "recipient: %s\nlocale: %s\nsubject: %s"
		% [
			feedback.get("recipient", ""),
			feedback.get("locale", ""),
			feedback.get("subject", ""),
		]
	)


func _on_send_feedback_pressed() -> void:
	var feedback := QuickActionsAppShortcuts.get_feedback_data()
	if feedback.is_empty():
		_refresh_status()
		return
	var recipient := str(feedback.get("recipient", ""))
	var subject := str(feedback.get("subject", ""))
	var body := str(feedback.get("body", ""))
	if OS.get_name() == "Android" and _open_android_email(recipient, subject, body):
		return
	OS.shell_open(_build_mailto(feedback))


# Prefer Android ACTION_SENDTO so the draft survives better than a raw mailto URL.
func _open_android_email(recipient: String, subject: String, body: String) -> bool:
	var android_runtime = Engine.get_singleton("AndroidRuntime")
	if android_runtime == null:
		return false
	var activity = android_runtime.getActivity()
	var intent_class = JavaClassWrapper.wrap("android.content.Intent")
	var uri_class = JavaClassWrapper.wrap("android.net.Uri")
	if activity == null or intent_class == null or uri_class == null:
		return false
	var intent = intent_class.Intent()
	intent.setAction(intent_class.ACTION_SENDTO)
	intent.setData(uri_class.parse("mailto:"))
	intent.addFlags(intent_class.FLAG_ACTIVITY_NEW_DOCUMENT)
	intent.addFlags(intent_class.FLAG_ACTIVITY_MULTIPLE_TASK)
	intent.putExtra(intent_class.EXTRA_EMAIL, PackedStringArray([recipient]))
	intent.putExtra(intent_class.EXTRA_SUBJECT, subject)
	intent.putExtra(intent_class.EXTRA_TEXT, body)
	var open_email := func() -> void:
		activity.startActivity(intent)
	activity.runOnUiThread(android_runtime.createRunnableFromGodotCallable(open_email))
	return true


func _build_mailto(feedback: Dictionary) -> String:
	var recipient := str(feedback.get("recipient", ""))
	var subject := str(feedback.get("subject", ""))
	var body := str(feedback.get("body", ""))
	# RFC 6068: use CRLF in mailto bodies so clients keep line breaks.
	body = body.replace("\r\n", "\n").replace("\r", "\n").replace("\n", "\r\n")
	return "mailto:%s?subject=%s&body=%s" % [
		recipient,
		subject.uri_encode(),
		body.uri_encode(),
	]

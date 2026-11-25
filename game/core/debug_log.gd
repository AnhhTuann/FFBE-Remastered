class_name DebugLog
extends RefCounted

## Small logging facade. The settings scene toggles `enabled` at runtime.

static var enabled: bool = true


static func info(message: String) -> void:
	if enabled:
		print("[FFBE] ", message)


static func warn(message: String) -> void:
	push_warning("[FFBE] " + message)


static func error(message: String) -> void:
	push_error("[FFBE] " + message)

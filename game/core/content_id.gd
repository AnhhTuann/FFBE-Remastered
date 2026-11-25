class_name ContentId
extends RefCounted

## Region-aware, form-discriminated content identity.
## Format: kind:REGION:native_id@form

const FORM_SEPARATOR := "@"

var kind: String = ""
var region: String = ""
var native_id: String = ""
var form: String = "base"


func _init(p_kind: String = "", p_region: String = "", p_native_id: String = "", p_form: String = "base") -> void:
	kind = p_kind.strip_edges().to_lower()
	region = p_region.strip_edges().to_upper()
	native_id = p_native_id.strip_edges()
	form = p_form.strip_edges().to_lower()
	if form.is_empty():
		form = "base"


func as_text() -> String:
	return "%s:%s:%s%s%s" % [kind, region, native_id, FORM_SEPARATOR, form]


func to_base_text() -> String:
	return "%s:%s:%s" % [kind, region, native_id]


func is_valid() -> bool:
	return not kind.is_empty() and (region == "GL" or region == "JP") and not native_id.is_empty() and not form.is_empty()


static func parse(value: String) -> ContentId:
	var parts: PackedStringArray = value.strip_edges().split(":", true)
	if parts.size() < 3:
		return null

	var native_and_form: String = parts[2]
	var form: String = "base"
	if native_and_form.find(FORM_SEPARATOR) != -1:
		var subparts: PackedStringArray = native_and_form.split(FORM_SEPARATOR, true, 1)
		native_and_form = subparts[0]
		if subparts.size() > 1 and not subparts[1].strip_edges().is_empty():
			form = subparts[1].strip_edges()

	return ContentId.new(parts[0], parts[1], native_and_form, form)

class_name UnitRecord
extends RefCounted

## Typed, immutable view of a normalized unit fixture. Player state is not stored here.

var id: String = ""
var content_id: ContentId = null
var region: String = ""
var native_id: String = ""
var form: String = "base"
var display_name: String = ""
var verification_status: String = "UNVERIFIED"
var rarity: int = 0
var stats: Dictionary = {}
var abilities: Array = []
var atlas_path: String = ""
var animation_id: String = ""
var provenance: Dictionary = {}


static func from_dict(data: Dictionary) -> UnitRecord:
	var record := UnitRecord.new()
	record.id = str(data.get("id", ""))
	record.content_id = ContentId.parse(record.id)
	record.region = str(data.get("region", ""))
	record.native_id = str(data.get("native_id", ""))
	record.form = str(data.get("form", "base"))
	record.display_name = str(data.get("display_name", record.id))
	record.verification_status = str(data.get("verification_status", "UNVERIFIED"))
	record.rarity = int(data.get("rarity", 0))

	var stats_variant: Variant = data.get("stats", {})
	if stats_variant is Dictionary:
		record.stats = stats_variant.duplicate(true)

	var abilities_variant: Variant = data.get("abilities", [])
	if abilities_variant is Array:
		record.abilities = abilities_variant.duplicate(true)

	var refs_variant: Variant = data.get("asset_refs", {})
	if refs_variant is Dictionary:
		var refs: Dictionary = refs_variant
		record.atlas_path = str(refs.get("atlas", ""))
		record.animation_id = str(refs.get("animation_id", ""))

	var provenance_variant: Variant = data.get("provenance", {})
	if provenance_variant is Dictionary:
		record.provenance = provenance_variant.duplicate(true)

	return record


func is_synthetic_fixture() -> bool:
	return verification_status == "SYNTHETIC_FIXTURE"


func display_id() -> String:
	return "%s / %s / %s" % [region, native_id, form]

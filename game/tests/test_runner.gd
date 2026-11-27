extends SceneTree

## Headless GDScript test runner.
## godot --headless --path game --script res://tests/test_runner.gd
## Exit code is non-zero when any check fails.
## Autoloads are resolved by node path at runtime so this script compiles even
## when invoked directly with --script.

const TESTS := [
	"test_project_config",
	"test_content_repository",
	"test_composite_identity",
	"test_animation_validation_valid_clips",
	"test_animation_validation_invalid_examples",
	"test_animation_validation_allows_holds",
	"test_viewer_scene_behavior",
	"test_synthetic_atlas",
	"test_save_roundtrip",
	"test_save_backup_recovery",
	"test_save_migration",
	"test_newer_save_refused",
	"test_settings_persistence",
	"test_missing_animation_fixture",
	"test_export_presets",
	"test_battle_engine",
	"test_phase3_suite",
	"test_hardening_layout_suite",
	"test_hardening_ui_flow_suite",
	"test_phase3_economy_suite",
	"test_prompt06_world_suite",
	"test_prompt07_event_suite",
	"test_negative_control"
]

const EXPECTED_SAVE_VERSION := 2
const EXPECTED_SLOT_COUNT := 3

var passed := 0
var failed := 0
var _repository: Node = null
var _saves: Node = null
var _locale: Node = null
var _content_id_script: Script = null
var _validator_script: Script = null
var _battle_suite_script: Script = null
var _phase3_suite_script: Script = null
var _hardening_layout_suite_script: Script = null
var _hardening_ui_flow_suite_script: Script = null
var _phase3_economy_suite_script: Script = null
var _prompt06_world_suite_script: Script = null
var _prompt07_event_suite_script: Script = null


func _initialize() -> void:
	_repository = root.get_node_or_null("ContentRepository")
	_saves = root.get_node_or_null("SaveManager")
	_locale = root.get_node_or_null("LocaleManager")
	_content_id_script = load("res://core/content_id.gd") as Script
	_validator_script = load("res://core/animation_validator.gd") as Script
	_battle_suite_script = load("res://tests/battle_test_suite.gd") as Script
	_phase3_suite_script = load("res://tests/phase3_test_suite.gd") as Script
	_hardening_layout_suite_script = load("res://tests/hardening_layout_test_suite.gd") as Script
	_hardening_ui_flow_suite_script = load("res://tests/hardening_ui_flow_test_suite.gd") as Script
	_phase3_economy_suite_script = load("res://tests/phase3_economy_test_suite.gd") as Script
	_prompt06_world_suite_script = load("res://tests/prompt06_world_test_suite.gd") as Script
	_prompt07_event_suite_script = load("res://tests/prompt07_event_test_suite.gd") as Script

	if _repository == null or _saves == null or _locale == null or _content_id_script == null or _validator_script == null or _battle_suite_script == null or _phase3_suite_script == null or _hardening_layout_suite_script == null or _hardening_ui_flow_suite_script == null or _phase3_economy_suite_script == null or _prompt06_world_suite_script == null or _prompt07_event_suite_script == null:
		push_error("FAIL services are unavailable")
		quit(1)
		return

	_clean_user_files()
	_repository.call("load_content")
	for test_name: String in TESTS:
		var result: Variant = null
		if test_name == "test_hardening_ui_flow_suite" or test_name == "test_prompt06_world_suite" or test_name == "test_prompt07_event_suite":
			result = await call(test_name)
		else:
			result = call(test_name)
		if result != true:
			failed += 1
			push_error("FAIL %s: did not finish (runtime error?)" % test_name)
	_clean_user_files()
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func assert_true(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected true" % label)


func assert_false(condition: bool, label: String) -> void:
	assert_true(not condition, label)


func assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		passed += 1
	else:
		failed += 1
		push_error("FAIL %s: expected %s, got %s" % [label, expected, actual])


func test_phase3_suite() -> bool:
	var suite: RefCounted = _phase3_suite_script.new(self) as RefCounted
	if suite == null:
		push_error("FAIL phase3 suite could not be constructed")
		return false
	return bool(suite.call("run"))


func test_hardening_layout_suite() -> bool:
	var suite: RefCounted = _hardening_layout_suite_script.new(self) as RefCounted
	if suite == null:
		push_error("FAIL hardening layout suite could not be constructed")
		return false
	return bool(suite.call("run"))


func test_hardening_ui_flow_suite() -> bool:
	var suite: RefCounted = _hardening_ui_flow_suite_script.new(self) as RefCounted
	if suite == null:
		push_error("FAIL hardening UI flow suite could not be constructed")
		return false
	var result: Variant = await suite.call("run")
	return result == true


func test_phase3_economy_suite() -> bool:
	var suite: RefCounted = _phase3_economy_suite_script.new(self) as RefCounted
	if suite == null:
		push_error("FAIL phase3 economy suite could not be constructed")
		return false
	return bool(suite.call("run"))


func test_prompt06_world_suite() -> bool:
	var suite: RefCounted = _prompt06_world_suite_script.new(self) as RefCounted
	if suite == null:
		push_error("FAIL prompt06 world suite could not be constructed")
		return false
	var result: Variant = await suite.call("run")
	return result == true


func test_prompt07_event_suite() -> bool:
	var suite: RefCounted = _prompt07_event_suite_script.new(self) as RefCounted
	if suite == null:
		push_error("FAIL prompt07 event suite could not be constructed")
		return false
	var result: Variant = await suite.call("run")
	return result == true


func test_negative_control() -> bool:
	if OS.get_environment("FFBE_TEST_NEGATIVE_CONTROL") == "1":
		assert_true(false, "FFBE_TEST_NEGATIVE_CONTROL deliberate failure")
	return true


func test_project_config() -> bool:
	assert_eq(ProjectSettings.get_setting("application/config/name", ""), "FFBE Remastered", "project name")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width", 0), 1280, "viewport width")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height", 0), 720, "viewport height")
	assert_eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter", -1), 0, "nearest filter")
	assert_true(InputMap.has_action("viewer_toggle_playback"), "playback input action")
	assert_true(InputMap.has_action("viewer_restart_animation"), "restart input action")
	for path: String in [
		"res://scenes/boot/boot.tscn",
		"res://scenes/menu/main_menu.tscn",
		"res://scenes/settings/settings.tscn",
		"res://scenes/viewer/character_viewer.tscn",
		"res://scenes/battle/battle_scene.tscn"
	]:
		assert_true(FileAccess.file_exists(path), "scene exists: %s" % path)
	return true


func test_content_repository() -> bool:
	assert_true(bool(_repository.get("loaded")), "repository loaded")
	var summary: Dictionary = _repository.call("summary")
	assert_eq(str(summary.get("fixture_marker", "")), "SYNTHETIC_FIXTURE", "fixture marker")
	assert_eq(int(summary.get("unit_count", 0)), 4, "unit count")
	var gl: Array = _repository.call("get_units_for_region", "GL")
	var jp: Array = _repository.call("get_units_for_region", "JP")
	assert_eq(gl.size(), 3, "GL unit count")
	assert_eq(jp.size(), 1, "JP unit count")
	return true


func test_composite_identity() -> bool:
	var gl: Object = _content_id_script.call("parse", "unit:GL:900001@base")
	var jp: Object = _content_id_script.call("parse", "unit:JP:900001@base")
	var invalid: Object = _content_id_script.call("parse", "unit:ZZ:1@base")
	assert_true(gl != null and bool(gl.call("is_valid")), "GL identity parses")
	assert_true(jp != null and bool(jp.call("is_valid")), "JP identity parses")
	assert_true(str(gl.call("as_text")) != str(jp.call("as_text")), "same native ID remains distinct across regions")
	assert_eq(str(gl.call("as_text")), "unit:GL:900001@base", "identity round trip")
	assert_true(invalid == null or not bool(invalid.call("is_valid")), "invalid region rejected")
	return true


func test_animation_validation_valid_clips() -> bool:
	var atlas: Dictionary = _repository.call("get_atlas_info")
	var width: int = int(atlas.get("width", 0))
	var height: int = int(atlas.get("height", 0))
	var checked := 0
	var units: Array = _repository.call("get_units")
	for unit in units:
		var clip_names: Array = _repository.call("get_clip_names", unit.get("animation_id"))
		for clip_name: String in clip_names:
			var clip: Dictionary = _repository.call("get_animation_clip", unit.get("animation_id"), clip_name)
			var diagnostics: Array = _validator_script.call("validate_clip", clip, width, height)
			assert_true(diagnostics.is_empty(), "valid clip %s/%s: %s" % [str(unit.get("id")), clip_name, diagnostics])
			checked += 1
	assert_eq(checked, 12, "clip count")
	return true


func test_animation_validation_invalid_examples() -> bool:
	var atlas: Dictionary = _repository.call("get_atlas_info")
	var width: int = int(atlas.get("width", 0))
	var height: int = int(atlas.get("height", 0))
	var animations: Dictionary = _read_json_dict("res://data/animations.json")
	var examples: Dictionary = animations.get("validation_examples", {})
	assert_false(
		(_validator_script.call("validate_clip", examples.get("out_of_bounds", {}), width, height) as Array).is_empty(),
		"out-of-bounds example fails validation"
	)
	assert_false(
		(_validator_script.call("validate_clip", examples.get("zero_duration", {}), width, height) as Array).is_empty(),
		"zero-duration example fails validation"
	)
	return true


func test_animation_validation_allows_holds() -> bool:
	var atlas: Dictionary = _repository.call("get_atlas_info")
	var width: int = int(atlas.get("width", 0))
	var height: int = int(atlas.get("height", 0))
	var animations: Dictionary = _read_json_dict("res://data/animations.json")
	var examples: Dictionary = animations.get("validation_examples", {})
	var diagnostics: Array = _validator_script.call(
		"validate_clip", examples.get("hold_oscillation", {}), width, height
	)
	assert_true(diagnostics.is_empty(), "repeated and non-monotonic frame IDs are allowed: %s" % [diagnostics])
	return true


func test_viewer_scene_behavior() -> bool:
	# The diagnostic assertion below is a stable English contract; isolate it
	# from the user's persisted locale without changing that persisted setting.
	var original_locale: String = str(_locale.get("current_locale"))
	_locale.call("set_locale", "en", false)
	var packed: PackedScene = load("res://scenes/viewer/character_viewer.tscn") as PackedScene
	assert_true(packed != null, "viewer scene loads")
	if packed == null:
		_locale.call("set_locale", original_locale, false)
		return true

	var viewer: Control = packed.instantiate() as Control
	root.add_child(viewer)
	# In a --script SceneTree run, deferred _ready notifications arrive on the
	# next frame. Invoke it explicitly; the node is freed before that frame.
	viewer.call("_ready")
	var unit_option: OptionButton = viewer.get("unit_option") as OptionButton
	var sprite: AnimatedSprite2D = viewer.get("sprite") as AnimatedSprite2D
	var diagnostics_label: Label = viewer.get("diagnostics_label") as Label
	var selected_unit: Object = viewer.get("_current_unit") as Object

	assert_eq(unit_option.get_item_count(), 4, "viewer lists all units")
	assert_eq(str(selected_unit.get("id")), "unit:GL:900001@base", "viewer first selection")
	assert_true(sprite.is_playing(), "viewer starts playback")
	assert_eq(sprite.sprite_frames.get_frame_count("idle"), 4, "idle frame count")

	viewer.call("_on_region_selected", 2)
	assert_eq(unit_option.get_item_count(), 1, "JP region filter")
	selected_unit = viewer.get("_current_unit") as Object
	assert_eq(str(selected_unit.get("id")), "unit:JP:900001@base", "JP unit selected")

	viewer.call("_toggle_playback")
	assert_false(sprite.is_playing(), "playback pauses")
	viewer.call("_restart_animation")
	assert_true(sprite.is_playing(), "playback restarts")

	viewer.call("_on_clip_selected", 1)
	assert_eq(sprite.animation, "attack", "clip switches to attack")
	assert_false(sprite.sprite_frames.get_animation_loop("attack"), "attack does not loop")

	viewer.call("_on_region_selected", 0)
	for index: int in range(unit_option.get_item_count()):
		if str(unit_option.get_item_metadata(index)) == "unit:GL:900003@base":
			viewer.call("_on_unit_selected", index)
			break
	assert_true(
		diagnostics_label.text.contains("Missing animation metadata"),
		"missing animation is reported visibly: %s" % diagnostics_label.text
	)
	assert_false(sprite.is_playing(), "invalid clip stops playback")

	root.remove_child(viewer)
	viewer.free()
	_locale.call("set_locale", original_locale, false)
	return true


func test_synthetic_atlas() -> bool:
	var texture: Texture2D = load("res://assets/sprites/synthetic_pixel_atlas.png") as Texture2D
	assert_true(texture != null, "atlas loads")
	if texture != null:
		assert_eq(texture.get_size(), Vector2(128, 128), "atlas size")
	return true


func test_save_roundtrip() -> bool:
	var state: Dictionary = _saves.call("build_viewer_state", "unit:JP:900001@base", ["unit:GL:900001@base"])
	assert_true(bool(_saves.call("validate_state", state)), "state validates")
	assert_eq(_saves.call("save_slot", 0, state), OK, "slot 0 save")
	var loaded: Dictionary = _saves.call("load_slot", 0)
	assert_eq(int(loaded.get("version", 0)), EXPECTED_SAVE_VERSION, "loaded version")
	var profile: Dictionary = loaded.get("profile", {})
	assert_eq(str(profile.get("selected_unit_id", "")), "unit:JP:900001@base", "loaded selection")
	return true


func test_save_backup_recovery() -> bool:
	var first: Dictionary = _saves.call("build_viewer_state", "unit:GL:900001@base", [])
	var second: Dictionary = _saves.call("build_viewer_state", "unit:GL:900001@brave_shift", [])
	assert_eq(_saves.call("save_slot", 1, first), OK, "backup first save")
	assert_eq(_saves.call("save_slot", 1, second), OK, "backup second save")
	assert_true(FileAccess.file_exists("user://save_slot_1.json.bak"), "backup file exists")

	var corrupt: FileAccess = FileAccess.open("user://save_slot_1.json", FileAccess.WRITE)
	assert_true(corrupt != null, "corrupt primary opened")
	if corrupt != null:
		corrupt.store_string("{\"version\": 2, \"pro")
		corrupt.close()

	var recovered: Dictionary = _saves.call("load_slot", 1)
	var profile: Dictionary = recovered.get("profile", {})
	assert_eq(str(profile.get("selected_unit_id", "")), "unit:GL:900001@base", "backup recovery")
	return true


func test_save_migration() -> bool:
	var fixture: Dictionary = _read_json_dict("res://data/save_fixtures/v1_save_slot_0.json")
	var migrated: Dictionary = _saves.call("migrate_to_current", fixture)
	assert_eq(int(migrated.get("version", 0)), EXPECTED_SAVE_VERSION, "migrated version")
	assert_true(bool(_saves.call("validate_state", migrated)), "migrated state validates")
	var profile: Dictionary = migrated.get("profile", {})
	assert_eq(str(profile.get("selected_unit_id", "")), "unit:GL:900001@base", "renamed field migrated")
	return true


func test_newer_save_refused() -> bool:
	var future: Dictionary = {
		"version": EXPECTED_SAVE_VERSION + 10,
		"profile": {"selected_unit_id": "unit:GL:1@base", "favorites": []}
	}
	assert_true((_saves.call("migrate_to_current", future) as Dictionary).is_empty(), "newer save refused")
	return true


func test_settings_persistence() -> bool:
	assert_eq(_saves.call("update_settings", {"debug_logging": false, "last_region": "JP"}), OK, "settings save")
	var settings: Dictionary = _saves.call("load_settings")
	assert_false(bool(settings.get("debug_logging", true)), "debug setting persisted")
	assert_eq(str(settings.get("last_region", "")), "JP", "region setting persisted")
	return true


func test_missing_animation_fixture() -> bool:
	var unit: Object = _repository.call("get_unit", "unit:GL:900003@base")
	assert_true(unit != null, "diagnostic fixture exists")
	if unit != null:
		assert_true((_repository.call("get_clip_names", unit.get("animation_id")) as Array).is_empty(), "missing animation has no clips")
	return true


func test_export_presets() -> bool:
	var file: FileAccess = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	assert_true(file != null, "export presets file opens")
	if file == null:
		return true
	var text: String = file.get_as_text()
	file.close()
	assert_true(text.contains("name=\"Windows Desktop\""), "Windows preset present")
	assert_true(text.contains("platform=\"Windows Desktop\""), "Windows platform present")
	assert_true(text.contains("name=\"Linux\""), "Linux preset present")
	assert_true(text.contains("include_filter=\"*.json"), "JSON files included in export")
	return true


func test_battle_engine() -> bool:
	var suite: RefCounted = _battle_suite_script.new(self) as RefCounted
	return bool(suite.call("run"))


func _read_json_dict(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	var error: Error = parser.parse(file.get_as_text())
	file.close()
	if error != OK or not parser.data is Dictionary:
		return {}
	return parser.data


func _clean_user_files() -> void:
	for suffix: String in ["", ".bak", ".tmp", ".mig.bak"]:
		_remove_absolute_if_exists("user://settings.json" + suffix)
		_remove_absolute_if_exists("user://battle_progress.json" + suffix)
		_remove_absolute_if_exists("user://player_state_v3.json" + suffix)
		for slot: int in range(EXPECTED_SLOT_COUNT):
			_remove_absolute_if_exists("user://save_slot_%d.json%s" % [slot, suffix])


func _remove_absolute_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

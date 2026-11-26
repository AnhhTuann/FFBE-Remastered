class_name WorldContext
extends RefCounted

## Scene-transition context. Godot destroys the outgoing scene on a scene
## change, so metadata on the persistent SceneTree root carries encounter,
## return-path and battle-result metadata. Metadata avoids add_child/remove_child
## during a child's _ready(), when the root may still be setting up children.

const NODE_NAME := "world_context"
const META_PREFIX := "ffbe_world_context_"

const WORLD_MAP_PATH := "res://scenes/world/world_map.tscn"
const EXPLORATION_PATH := "res://scenes/world/exploration_area.tscn"
const BATTLE_PATH := "res://scenes/battle/battle_scene.tscn"

const META_KEYS: Array[String] = [
	"location_id", "encounter_id", "return_scene", "trigger_id", "battle_result"
]


static func write(values: Dictionary) -> void:
	var loop: Variant = Engine.get_main_loop()
	if not loop is SceneTree:
		return
	var root: Node = (loop as SceneTree).root
	clear()
	for key: String in META_KEYS:
		if values.has(key):
			root.set_meta(META_PREFIX + key, values[key])


static func peek() -> Dictionary:
	var result: Dictionary = {}
	var loop: Variant = Engine.get_main_loop()
	if not loop is SceneTree:
		return result
	var root: Node = (loop as SceneTree).root
	for key: String in META_KEYS:
		var meta_name := META_PREFIX + key
		if root.has_meta(meta_name):
			result[key] = root.get_meta(meta_name)
	return result


static func consume() -> Dictionary:
	var result: Dictionary = peek()
	clear()
	return result


static func clear() -> void:
	var loop: Variant = Engine.get_main_loop()
	if not loop is SceneTree:
		return
	var root: Node = (loop as SceneTree).root
	for key: String in META_KEYS:
		var meta_name := META_PREFIX + key
		if root.has_meta(meta_name):
			root.remove_meta(meta_name)

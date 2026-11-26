class_name ExplorationController
extends RefCounted

## UI-independent 2D movement, collision and boundary logic. The scene owns
## sprites and input events; this controller only resolves positions.

const DEFAULT_SPEED := 260.0
const DEFAULT_RADIUS := 18.0

var position: Vector2 = Vector2.ZERO
var bounds: Rect2 = Rect2(0, 0, 1280, 720)
var speed: float = DEFAULT_SPEED
var radius: float = DEFAULT_RADIUS
var colliders: Array[Rect2] = []
var move_target: Vector2 = Vector2.INF
var last_movement: Vector2 = Vector2.ZERO


func configure(start_position: Vector2, area_bounds: Rect2, obstacle_rects: Array[Rect2] = []) -> void:
	position = start_position
	bounds = area_bounds
	colliders = obstacle_rects.duplicate()
	move_target = Vector2.INF
	last_movement = Vector2.ZERO


func can_occupy(point: Vector2) -> bool:
	if point.x - radius < bounds.position.x or point.x + radius > bounds.end.x:
		return false
	if point.y - radius < bounds.position.y or point.y + radius > bounds.end.y:
		return false
	var player_rect := Rect2(point.x - radius, point.y - radius, radius * 2.0, radius * 2.0)
	for obstacle: Rect2 in colliders:
		if player_rect.intersects(obstacle):
			return false
	return true


func move(delta: float, direction: Vector2) -> Vector2:
	var original: Vector2 = position
	if delta <= 0.0 or direction.length_squared() <= 0.0:
		last_movement = Vector2.ZERO
		return position
	var step: Vector2 = direction.normalized() * speed * delta
	var desired: Vector2 = position + step
	if can_occupy(desired):
		position = desired
	else:
		var x_only := Vector2(desired.x, position.y)
		if can_occupy(x_only):
			position = x_only
		else:
			var y_only := Vector2(position.x, desired.y)
			if can_occupy(y_only):
				position = y_only
	last_movement = position - original
	return position


func set_move_target(target: Vector2) -> void:
	move_target = target.clamp(
		Vector2(bounds.position.x + radius, bounds.position.y + radius),
		Vector2(bounds.end.x - radius, bounds.end.y - radius)
	)


func clear_move_target() -> void:
	move_target = Vector2.INF


func move_to_target(delta: float) -> Vector2:
	if delta <= 0.0 or not is_finite_vector(move_target):
		return position
	var offset: Vector2 = move_target - position
	if offset.length() <= 2.0:
		clear_move_target()
		return position
	return move(delta, offset)


func is_finite_vector(value: Vector2) -> bool:
	return value.x == value.x and value.y == value.y and absf(value.x) < 1.0e30 and absf(value.y) < 1.0e30


func add_obstacle(rect: Rect2) -> void:
	colliders.append(rect)

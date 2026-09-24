extends Node2D
class_name Moveable

var tile := Vector2i.ZERO
var start_tile := Vector2i.ZERO
var tween: Tween
var active: bool = true
var inactive_reason: String = ""

func _enter_tree() -> void:
	add_to_group("Moveable")

func _ready() -> void:
	tile = Level.world_to_tile(position)
	position = Level.tile_to_world(tile)
	start_tile = tile

func is_player_piece() -> bool:
	return false

func is_metal_crate() -> bool:
	return false

func is_animating() -> bool:
	return tween != null and tween.is_running()

func can_move(direction: Vector2i, is_player: bool = false) -> bool:
	if not active:
		return false

	var target_tile := tile + direction
	if not Level.can_moveable_enter_tile(self, target_tile):
		return false

	var moveable := Level.get_moveable_at_tile(target_tile)
	if moveable:
		# Una caja no puede empujar otra caja. El jugador sí puede intentar empujar una.
		if not is_player:
			return false
		return moveable.can_move(direction, false)

	return true

func move(direction: Vector2i) -> bool:
	if not active:
		return false

	var moveable := Level.get_moveable_at_tile(tile + direction)
	if moveable:
		moveable.move(direction)

	slide(direction)
	return false

func slide(direction: Vector2i) -> void:
	tile += direction
	var target := Level.tile_to_world(tile)

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.tween_property(self, "position", target, 0.08)
	Level.on_moveable_entered_tile(self)

func move_on_conveyor(direction: Vector2i) -> bool:
	return move(direction)

func teleport_to_tile(destination: Vector2i) -> void:
	# Cancelamos el movimiento hacia la entrada para que no arrastre la caja
	# de vuelta después del transporte. start_tile y el estado se conservan.
	if tween and tween.is_running():
		tween.kill()
	tile = destination
	position = Level.tile_to_world(destination)

func deactivate(reason: String) -> void:
	active = false
	inactive_reason = reason
	visible = false

func reset_to_start() -> void:
	# Una caja retirada por la puerta no puede revivir por un efecto pendiente.
	# Z restaura el snapshot directamente; R vuelve a crear la escena.
	if not active:
		return
	if tween and tween.is_running():
		tween.kill()
	tile = start_tile
	position = Level.tile_to_world(start_tile)
	active = true
	inactive_reason = ""
	visible = true
	modulate = Color.WHITE
	scale = Vector2.ONE
	_on_reset_to_start()
	Level.evaluate_pressure_plates()

func _on_reset_to_start() -> void:
	pass

func capture_state() -> Dictionary:
	return {
		"tile": tile,
		"active": active,
		"inactive_reason": inactive_reason,
		"visible": visible,
		"scale": scale,
		"modulate": modulate,
		"extra": capture_extra_state()
	}

func capture_extra_state() -> Dictionary:
	return {}

func restore_state(state: Dictionary) -> void:
	if tween and tween.is_running():
		tween.kill()

	tile = state["tile"]
	position = Level.tile_to_world(tile)
	active = state["active"]
	inactive_reason = state["inactive_reason"]
	visible = state["visible"]
	scale = state["scale"]
	modulate = state["modulate"]
	restore_extra_state(state.get("extra", {}))

func restore_extra_state(_state: Dictionary) -> void:
	pass

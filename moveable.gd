extends Node2D
class_name Moveable

var tile := Vector2i.ZERO
var start_tile := Vector2i.ZERO
var tween: Tween
var current_slide_dir := Vector2i.ZERO
var is_teleporting: bool = false # Bandera para evitar bucles de TP

func _enter_tree() -> void:
	Level.moveables.append(self)
	
func _exit_tree() -> void:
	Level.moveables.erase(self)

func _ready() -> void:
	tile = Vector2i(position / 128.0)
	position = Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	start_tile = tile
	
func can_move(direction: Vector2i, is_player: bool = false) -> bool:
	if Level.is_tile_wall(tile + direction):
		return false
	var moveable := Level.get_moveable_at_tile(tile + direction)
	if moveable:
		if !is_player:
			return false
		return moveable.can_move(direction, false)
	return true
	
func move(direction: Vector2i) -> bool:
	var start_pos := tile
	var moveable := Level.get_moveable_at_tile(tile + direction)
	if moveable:
		moveable.move(direction)
		
	slide(direction)
	Level.add_move_to_turn(self, start_pos)
	return false

func slide(direction: Vector2i) -> void:
	var old_tile := tile
	is_teleporting = false
	current_slide_dir = direction
	tile += direction
	var target := Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(self, "position", target, 0.08)
	
	# Al terminar de moverse visualmente a la casilla:
	tween.tween_callback(func():
		# 1. Notificar al agujero que dejó libre por si había algo esperando
		var prev_hole := Level.get_hole_at_tile(old_tile)
		if prev_hole:
			prev_hole.notify_freed()
			
		# 2. Revisar si la casilla a la que llegó es un agujero
		check_hole_teleport()
	)

func check_hole_teleport() -> void:
	if is_teleporting:
		return
		
	var hole := Level.get_hole_at_tile(tile)
	if hole and hole.paired_hole:
		var destination_tile := hole.paired_hole.tile
		if Level.get_moveable_at_tile(destination_tile) == null:
			teleport_to(destination_tile)

func teleport_to(new_tile: Vector2i) -> void:
	is_teleporting = true
	var old_tile := tile
	tile = new_tile
	var destination_pos := Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.08)
	tween.tween_callback(func():
		position = destination_pos
		# Al salir del agujero de origen, avisa si había otro esperando atrás
		var prev_hole := Level.get_hole_at_tile(old_tile)
		if prev_hole:
			prev_hole.notify_freed()
	)
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)
	tween.tween_callback(on_teleport_complete)

func on_teleport_complete() -> void:
	pass

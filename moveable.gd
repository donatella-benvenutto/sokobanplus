extends Node2D
class_name Moveable

var tile := Vector2i.ZERO
var start_tile := Vector2i.ZERO
var tween: Tween

func _enter_tree() -> void:
	Level.moveables.append(self)
	
func _exit_tree() -> void:
	Level.moveables.erase(self)

func _ready() -> void:
	tile = position / 128
	position = tile * 128.0 + Vector2(64.0, 64.0)
	start_tile = tile
	
func can_move(direction: Vector2i, is_player: bool = false) -> bool:
	if Level.is_tile_wall(tile + direction):
		return false
	var moveable := Level.get_moveable_at_tile(tile + direction)
	if moveable:
		# no se permite empujar a una segunda caja seguidas.
		if !is_player:
			return false
		# Si es el jugador, delega la verificación a la caja con is_player = false
		return moveable.can_move(direction, false)
	return true
	
func move(direction: Vector2i) -> bool:
	var moveable := Level.get_moveable_at_tile(tile + direction)
	if moveable:
		moveable.move(direction)
	slide(direction)
	
	Level.add_move_to_turn(self, direction)
	return false # Por defecto, ninguna otra caja explota

func slide(direction: Vector2i) -> void:
	tile += direction
	var target := Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	
	# Cancela el tween anterior si sigue activo para evitar el error de append
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(self, "position", target, 0.08)

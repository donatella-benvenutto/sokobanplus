extends Node2D
class_name Moveable

var tile := Vector2i.ZERO
var tween: Tween

func _ready() -> void:
	tile = position / 128
	position = tile * 128.0 + Vector2(64.0, 64.0)
	
func can_move(direction: Vector2i) -> bool:
	if Level.is_tile_wall(tile + direction):
		return false
	return true
	
func move(direction: Vector2i) -> void:
	slide(direction)
	
#func slide(direction: Vector2i) -> void:
#	tile += direction
#	var target := Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
#	tween = create_tween()
#	tween.tween_property(self, "position", target, 0.08)
func slide(direction: Vector2i) -> void:
	position = tile * 128.0 + Vector2(64.0, 64.0)
	tile += direction
	
	var target := tile * 128.0 + Vector2(64.0, 64.0)
	tween = create_tween()
	tween.tween_property(self, "position", target, 0.08)

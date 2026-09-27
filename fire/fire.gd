class_name Fire
extends Node2D

var tile: Vector2i

func _ready() -> void:
	tile = Vector2i(position / 128.0)
	position = Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	
	if "fires" in Level:
		Level.fires.append(self)

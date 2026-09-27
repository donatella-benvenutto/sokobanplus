class_name RedirectTile
extends Node2D

@export var direction: Vector2i = Vector2i.RIGHT

var tile := Vector2i.ZERO

func _ready() -> void:
	# 1. Calcular de inmediato la casilla exacta en la grilla
	tile = Vector2i((position / 128.0).floor())
	position = Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	
	# 2. Registrar en la lista global de Level
	if Level and not Level.redirect_tiles.has(self):
		Level.redirect_tiles.append(self)
		
	queue_redraw()

func _enter_tree() -> void:
	# Asegurar registro si el nodo reingresa al árbol de escena
	if Level and not Level.redirect_tiles.has(self):
		Level.redirect_tiles.append(self)

func _exit_tree() -> void:
	if Level and Level.redirect_tiles.has(self):
		Level.redirect_tiles.erase(self)

func _draw() -> void:
	var rect = Rect2(-64, -64, 128, 128)
	draw_rect(rect, Color(0.35, 0.35, 0.38, 0.8), true)
	draw_rect(rect, Color(0.6, 0.6, 0.65, 1.0), false, 4.0)

	var arrow_color := Color(0.9, 0.9, 0.95, 0.9)
	var dir_v := Vector2(direction)
	var start_p := -dir_v * 30.0
	var end_p := dir_v * 30.0

	draw_line(start_p, end_p, arrow_color, 8.0)

	var perp := Vector2(-dir_v.y, dir_v.x) * 16.0
	var head_left := end_p - dir_v * 20.0 + perp
	var head_right := end_p - dir_v * 20.0 - perp

	draw_polyline([head_left, end_p, head_right], arrow_color, 8.0)

class_name GateBlock
extends Node2D
## Bloque de pared que baja cuando TODOS los botones de su mismo channel están presionados.
## Si "inverted" es true hace lo contrario: está abajo y SUBE cuando se presionan.

@export var channel: int = 0
@export var inverted: bool = false

var tile: Vector2i
var _closed := true
var _anim: Tween

# 0.0 = bloque arriba (cerrado), 1.0 = bloque abajo (abierto). Al cambiar, se redibuja.
var openness: float = 0.0:
	set(value):
		openness = value
		queue_redraw()

func _ready() -> void:
	tile = Vector2i(position / 128.0)
	position = Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	add_to_group("gates")

func should_be_open() -> bool:
	var my_buttons := get_tree().get_nodes_in_group("buttons").filter(
		func(b): return b.channel == channel)
	if my_buttons.is_empty():
		return inverted
	var all_pressed: bool = my_buttons.all(func(b): return b.is_pressed())
	return all_pressed != inverted

func is_closed() -> bool:
	if should_be_open():
		return false
	# Quiere subir, pero si hay algo encima espera a que se libere la casilla
	return Level.get_moveable_at_tile(tile) == null

func _process(_delta: float) -> void:
	var closed := is_closed()
	if closed != _closed:
		_closed = closed
		if _anim:
			_anim.kill()
		_anim = create_tween()
		_anim.tween_property(self, "openness", 0.0 if closed else 1.0, 0.2)

func _draw() -> void:
	var c: Color = Level.channel_color(channel)
	var size := lerpf(120.0, 70.0, openness)
	var rect := Rect2(Vector2(-size, -size) / 2.0, Vector2(size, size))
	var fill := c.darkened(0.35)
	fill.a = lerpf(1.0, 0.25, openness)
	draw_rect(rect, fill)
	draw_rect(rect, c, false, 6.0)
	if openness < 0.5:
		# Rayas tipo ladrillo cuando está arriba
		for y in [-20.0, 20.0]:
			draw_line(Vector2(-size / 2.0, y), Vector2(size / 2.0, y), c.darkened(0.6), 4.0)

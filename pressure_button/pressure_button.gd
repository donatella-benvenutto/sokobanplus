class_name PressureButton
extends Node2D
## Botón en el piso. Está presionado mientras haya una caja/piedra quieta encima.
## Las paredes (GateBlock) con el mismo "channel" bajan cuando se presiona.

@export var channel: int = 0              # Botones y paredes con el mismo número están conectados
@export var player_can_press: bool = false # Si es true, el jugador también lo presiona al pararse

var tile: Vector2i
var _pressed_visual := false

func _ready() -> void:
	tile = Vector2i(position / 128.0)
	position = Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	add_to_group("buttons")
	queue_redraw()

func is_pressed() -> bool:
	var m := Level.get_moveable_at_tile(tile)
	if m == null:
		return false
	if m is Player and not player_can_press:
		return false
	# Si todavía se está moviendo (ej: un hielo pasando de largo) no cuenta
	if m.tween and m.tween.is_running():
		return false
	return true

func _process(_delta: float) -> void:
	var pressed := is_pressed()
	if pressed != _pressed_visual:
		_pressed_visual = pressed
		queue_redraw()

func _draw() -> void:
	var c: Color = Level.channel_color(channel)
	draw_circle(Vector2.ZERO, 48, Color(0.15, 0.15, 0.15))
	if _pressed_visual:
		draw_circle(Vector2(0, 4), 36, c.darkened(0.4))
	else:
		draw_circle(Vector2(0, 6), 38, c.darkened(0.5))
		draw_circle(Vector2(0, -2), 38, c)

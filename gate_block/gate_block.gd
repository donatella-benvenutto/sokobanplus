class_name GateBlock
extends Node2D
## Bloque de pared que baja cuando TODOS los botones de su mismo channel están presionados.
## Si "inverted" es true hace lo contrario: está abajo y SUBE cuando se presionan.

@export var channel: int = 0
@export var inverted: bool = false

@onready var sprite: Sprite2D = $Sprite2D

var tile: Vector2i
var _closed := true
var _anim: Tween

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
		animate(closed)

func animate(closed: bool) -> void:
	if _anim:
		_anim.kill()
	# set_parallel: las dos animaciones (tamaño y transparencia) ocurren a la vez
	_anim = create_tween().set_parallel(true)
	var target_scale: Vector2 = Vector2.ONE if closed else Vector2(0.6, 0.6)
	var target_alpha: float = 1.0 if closed else 0.3
	_anim.tween_property(sprite, "scale", target_scale, 0.2)
	_anim.tween_property(sprite, "modulate:a", target_alpha, 0.2)

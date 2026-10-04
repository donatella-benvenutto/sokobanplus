class_name PressureButton
extends Node2D
## Botón en el piso. Está presionado mientras haya una caja/piedra quieta encima.
## Las paredes (GateBlock) con el mismo "channel" bajan cuando se presiona.
## La imagen la pone el nodo hijo Sprite2D (se elige en el Inspector).

@export var channel: int = 0               # Botones y paredes con el mismo número están conectados
@export var player_can_press: bool = false # Si es true, el jugador también lo presiona al pararse
## Opcional: imagen para cuando está presionado.
## Si la dejás vacía, el botón se oscurece y se achica un poco.
@export var pressed_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

var tile: Vector2i
var _pressed_visual := false
var _normal_texture: Texture2D
var _base_scale: Vector2

func _ready() -> void:
	tile = Vector2i(position / 128.0)
	position = Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	add_to_group("buttons")
	_normal_texture = sprite.texture
	_base_scale = sprite.scale

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
		update_visual()

func update_visual() -> void:
	if pressed_texture:
		# Si hay imagen de "presionado", cambiamos entre las dos imágenes
		sprite.texture = pressed_texture if _pressed_visual else _normal_texture
	else:
		# Si no, lo oscurecemos y achicamos un poco respecto a su tamaño original
		if _pressed_visual:
			sprite.modulate = Color(0.55, 0.55, 0.55)
			sprite.scale = _base_scale * 0.85
		else:
			sprite.modulate = Color.WHITE
			sprite.scale = _base_scale

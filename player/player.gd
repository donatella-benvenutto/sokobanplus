class_name Player
extends Moveable

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	set_idle_sprite()

func _input(event: InputEvent) -> void:
	if !event.is_pressed():
		return
		
	if is_any_moveable_animating():
		return

	var direction := Vector2i.ZERO
	var anim_name := ""

	match event.as_text():
		"Up":
			direction = Vector2i.UP
			anim_name = "walk_up"
		"Down":
			direction = Vector2i.DOWN
			anim_name = "walk_down"
		"Left":
			direction = Vector2i.LEFT
			anim_name = "walk_left"
		"Right":
			direction = Vector2i.RIGHT
			anim_name = "walk_right"
		"Z":
			Level.undo_last_move()
			return
		_:
			return

	if can_move(direction, true):
		# REPRODUCIR ANIMACIÓN SEGÚN LA DIRECCIÓN:
		if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)

		var target_moveable := Level.get_moveable_at_tile(tile + direction)
		
		# Crear un nuevo grupo de movimientos para este turno
		Level.past_turns.append([])
		
		var crate_exploded := false
		if target_moveable:
			crate_exploded = target_moveable.move(direction)
		
		if !crate_exploded:
			var player_start_tile := tile
			slide(direction)
			Level.add_move_to_turn(self, player_start_tile)

func slide(direction: Vector2i) -> void:
	super.slide(direction)
	# AL TERMINAR EL PASO, VOLVER A LA VISTA FRONTAL:
	if tween:
		tween.finished.connect(set_idle_sprite, CONNECT_ONE_SHOT)

func set_idle_sprite() -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("idle_down"):
			animated_sprite.play("idle_down")
		elif animated_sprite.sprite_frames.has_animation("walk_down"):
			animated_sprite.play("walk_down")
			animated_sprite.stop()
			animated_sprite.frame = 0

func is_any_moveable_animating() -> bool:
	for moveable in Level.moveables:
		if is_instance_valid(moveable) and moveable.tween and moveable.tween.is_running():
			return true
	return false

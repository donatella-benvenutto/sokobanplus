extends Moveable

func _input(event: InputEvent) -> void:
	if !event.is_pressed():
		return
		
	if is_any_moveable_animating():
		return

	var direction := Vector2i.ZERO
	match event.as_text():
		"Up":
			direction = Vector2i.UP
		"Down":
			direction = Vector2i.DOWN
		"Left":
			direction = Vector2i.LEFT
		"Right":
			direction = Vector2i.RIGHT
		"Z":
			Level.undo_last_move()
			return
		_:
			return

	if can_move(direction, true):
		var target_moveable := Level.get_moveable_at_tile(tile + direction)
		
		Level.past_turns.append([])
		
		var crate_exploded := false
		if target_moveable:
			crate_exploded = target_moveable.move(direction)
		
		if !crate_exploded:
			slide(direction)
			Level.add_move_to_turn(self, direction)

func is_any_moveable_animating() -> bool:
	for moveable in Level.moveables:
		if is_instance_valid(moveable) and moveable.tween and moveable.tween.is_running():
			return true
	return false

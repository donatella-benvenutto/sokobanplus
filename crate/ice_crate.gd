class_name IceCrate
extends Moveable

func slide(direction: Vector2i) -> void:
	current_slide_dir = direction
	tile += direction
	var target := Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(self, "position", target, 0.08)
	tween.tween_callback(on_step_finished)

func on_step_finished() -> void:
	var hole := Level.get_hole_at_tile(tile)
	if hole and hole.paired_hole:
		var dest := hole.paired_hole.tile
		if Level.get_moveable_at_tile(dest) == null:
			teleport_to(dest)
			return
			
	continue_sliding_if_possible()

func on_teleport_complete() -> void:
	continue_sliding_if_possible()

func continue_sliding_if_possible() -> void:
	if can_move(current_slide_dir, false):
		slide(current_slide_dir)

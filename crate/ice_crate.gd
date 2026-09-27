class_name IceCrate
extends Moveable

func slide(direction: Vector2i) -> void:
	is_teleporting = false
	current_slide_dir = direction
	tile += direction
	var target := Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(self, "position", target, 0.08)
	tween.tween_callback(on_step_finished)

func on_step_finished() -> void:
	# 1. Verificar si la casilla actual tiene FUEGO
	var fire := Level.get_fire_at_tile(tile)
	if fire:
		melt_and_reset()
		return

	# 2. Verificar PISO DE REDIRECCIÓN
	var redirect: Variant = Level.get_redirect_at_tile(tile)
	if redirect:
		current_slide_dir = redirect.direction
		# Si al reorientarse choca directamente contra un obstáculo rígido
		if not can_move(current_slide_dir, false):
			# Si choca contra el jugador, empujar al jugador
			var target_moveable := Level.get_moveable_at_tile(tile + current_slide_dir)
			if target_moveable and target_moveable.get_script() != null and target_moveable.get_script().resource_path.ends_with("player.gd"):
				if target_moveable.can_move(current_slide_dir, true):
					target_moveable.slide(current_slide_dir)
					slide(current_slide_dir)
					return

	# 3. Verificar si la casilla actual es un AGUJERO
	if not is_teleporting:
		var hole := Level.get_hole_at_tile(tile)
		if hole and hole.paired_hole:
			var dest := hole.paired_hole.tile
			if Level.get_moveable_at_tile(dest) == null:
				teleport_to(dest)
				return
			
	continue_sliding_if_possible()

func melt_and_reset() -> void:
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	
	# 1. Animación de derretido (se aplasta y desvanece como charco de agua)
	tween.tween_property(self, "modulate", Color(1.0, 0.4, 0.2, 0.0), 0.25)
	tween.parallel().tween_property(self, "scale", Vector2(1.3, 0.0), 0.25)
	
	# 2. Resetear posición cuando termina de derretirse
	tween.tween_callback(func():
		is_teleporting = false
		Level.clear_spawn_for_player(start_tile)
		
		tile = start_tile
		position = Vector2(start_tile) * 128.0 + Vector2(64.0, 64.0)
		scale = Vector2.ZERO
		modulate = Color.WHITE
	)
	
	# 3. Animación de reaparición (crece suavemente en el spawn)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)

func on_teleport_complete() -> void:
	continue_sliding_if_possible()

func continue_sliding_if_possible() -> void:
	if can_move(current_slide_dir, false):
		slide(current_slide_dir)
	else:
		is_teleporting = false

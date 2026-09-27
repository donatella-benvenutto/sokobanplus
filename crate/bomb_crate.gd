class_name BombCrate
extends Moveable

@export var moves_left: int = 4

@onready var count_label: Label = $CountLabel

func _ready() -> void:
	super._ready()
	update_label()

func update_label() -> void:
	if count_label:
		count_label.text = str(moves_left)

func move(direction: Vector2i) -> bool:
	# 1. Ejecuta el movimiento a la siguiente casilla en la grilla
	super.move(direction)
	
	# 2. Resta el contador
	moves_left -= 1
	update_label()
	
	# 3. Si llega a 0, espera a que termine de deslizarse y luego explota
	if moves_left <= 0:
		if tween and tween.is_running():
			# Espera a que la caja termine de moverse físicamente a la nueva casilla
			tween.finished.connect(explode, CONNECT_ONE_SHOT)
		else:
			explode()
		return false # Devuelve false para que el jugador SÍ camine a la casilla que la caja dejó libre
		
	return false

func restore_move() -> void:
	moves_left += 1
	update_label()

func explode() -> void:
	Level.clear_history()
	
	# 1. Posiciones adyacentes (8 casillas alrededor de la bomba)
	var adjacent_offsets: Array[Vector2i] = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)
	]
	
	var affected_crates: Array[Moveable] = [self]
	
	# 2. Agregar cajas directamente golpeadas por la explosión
	for offset in adjacent_offsets:
		var target_tile: Vector2i = tile + offset
		var moveable := Level.get_moveable_at_tile(target_tile)
		if moveable and moveable != self:
			var is_player: bool = moveable.get_script() != null and moveable.get_script().resource_path.ends_with("player.gd")
			if not is_player and not affected_crates.has(moveable):
				affected_crates.append(moveable)

	# 3. REACCIÓN EN CADENA POR CONFLICTO DE ORIGEN (SPAWN)
	# Si la casilla start_tile de alguna caja a resetear está ocupada por otra caja,
	# esa otra caja debe resetearse también para liberar el espacio.
	var checking := true
	while checking:
		checking = false
		for crate in affected_crates:
			var occupant := Level.get_moveable_at_tile(crate.start_tile)
			# Si la casilla inicial está ocupada por otra caja que NO estaba en el grupo de reseteo:
			if occupant and occupant != crate and not affected_crates.has(occupant):
				var is_player: bool = occupant.get_script() != null and occupant.get_script().resource_path.ends_with("player.gd")
				if not is_player:
					affected_crates.append(occupant)
					checking = true # Repetir verificación para ver si esta nueva caja libera u ocupa otra

	# 4. Animar y resetear las posiciones de todas las cajas en la cadena
	for crate in affected_crates:
		animate_reset_crate(crate)

func animate_reset_crate(crate: Moveable) -> void:
	if crate.tween and crate.tween.is_running():
		crate.tween.kill()
		
	crate.tween = create_tween()
	
	# Efecto visual de parpadeo rojo por explosión/reacción en cadena
	for i in range(3):
		crate.tween.tween_property(crate, "modulate", Color(3.0, 0.2, 0.2, 0.2), 0.08)
		crate.tween.tween_property(crate, "modulate", Color.WHITE, 0.08)
	
	crate.tween.tween_callback(func():
		crate.is_teleporting = false
		Level.clear_spawn_for_player(crate.start_tile)
		crate.tile = crate.start_tile
		var start_pos := Vector2(crate.start_tile) * 128.0 + Vector2(64.0, 64.0)
		crate.position = start_pos
		
		# Si la caja reseteada es una bomba, restaurar su contador
		if crate is BombCrate:
			crate.moves_left = 4
			crate.update_label()
	)

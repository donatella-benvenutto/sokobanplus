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
	# 1. Posiciones adyacentes (8 casillas alrededor)
	var adjacent_offsets: Array[Vector2i] = [
		Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)
	]
	
	var affected_crates: Array[Moveable] = [self]
	
	# 2. Buscar únicamente CAJAS alrededor (ignorando al jugador)
	for offset in adjacent_offsets:
		var target_tile: Vector2i = tile + offset
		for moveable in Level.moveables:
			# Asignación explícita declarada como bool para evitar errores de inferencia
			var is_player: bool = moveable.get_script() != null and moveable.get_script().resource_path.ends_with("player.gd")
			
			if moveable != self and moveable.tile == target_tile and not is_player:
				affected_crates.append(moveable)
				
	# 3. Animar reseteo solo de las cajas
	for crate in affected_crates:
		animate_reset_crate(crate)

func animate_reset_crate(crate: Moveable) -> void:
	if crate.tween and crate.tween.is_running():
		crate.tween.kill()
		
	crate.tween = create_tween()
	
	for i in range(3):
		crate.tween.tween_property(crate, "modulate", Color(3.0, 0.2, 0.2, 0.2), 0.08)
		crate.tween.tween_property(crate, "modulate", Color.WHITE, 0.08)
	
	crate.tween.tween_callback(func():
		crate.tile = crate.start_tile
		var start_pos := Vector2(crate.start_tile) * 128.0 + Vector2(64.0, 64.0)
		crate.position = start_pos
		
		if crate is BombCrate:
			crate.moves_left = 4
			crate.update_label()
	)

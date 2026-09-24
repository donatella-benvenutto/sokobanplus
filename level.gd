extends Node

signal crates_changed(exited: int, total: int)
signal timer_changed(elapsed_seconds: float)
signal move_count_changed(move_count: int)
signal level_completed(elapsed_seconds: float, move_count: int)

const TILE_SIZE := 128
const HALF_TILE := Vector2(64.0, 64.0)
const MAX_UNDO_STATES := 100

var tilemap: TileMapLayer
var moveables: Array[Moveable] = []

var past_states: Array[Dictionary] = []
var elapsed_seconds: float = 0.0
var move_count: int = 0
var total_crates: int = 0
var crates_exited: int = 0
var is_completed: bool = false

var _doors: Dictionary = {}
var _holes: Dictionary = {}
var _fires: Dictionary = {}
var _conveyors: Dictionary = {}
var _barriers: Dictionary = {}

func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_refresh_level")

func _process(delta: float) -> void:
	if tilemap == null or is_completed:
		return
	elapsed_seconds += delta
	timer_changed.emit(elapsed_seconds)

func _on_scene_changed() -> void:
	call_deferred("_refresh_level")

func _refresh_level() -> void:
	tilemap = get_tree().get_first_node_in_group("LevelTileMap") as TileMapLayer
	_rebuild_moveables()
	_rebuild_interactables()

	past_states.clear()
	elapsed_seconds = 0.0
	move_count = 0
	is_completed = false
	total_crates = 0
	for moveable in moveables:
		if is_instance_valid(moveable) and not moveable.is_player_piece():
			total_crates += 1

	_recalculate_crates_exited()
	move_count_changed.emit(move_count)
	timer_changed.emit(elapsed_seconds)
	crates_changed.emit(crates_exited, total_crates)
	evaluate_pressure_plates()

func _rebuild_moveables() -> void:
	moveables.clear()
	for node in get_tree().get_nodes_in_group("Moveable"):
		if node is Moveable:
			moveables.append(node)

func _rebuild_interactables() -> void:
	_doors.clear()
	_holes.clear()
	_fires.clear()
	_conveyors.clear()
	_barriers.clear()

	for node in get_tree().get_nodes_in_group("ExitDoor"):
		_doors[node.get_tile()] = node
	for node in get_tree().get_nodes_in_group("Hole"):
		_holes[node.get_tile()] = node
	for node in get_tree().get_nodes_in_group("Fire"):
		_fires[node.get_tile()] = node
	for node in get_tree().get_nodes_in_group("Conveyor"):
		_conveyors[node.get_tile()] = node
	for node in get_tree().get_nodes_in_group("Barrier"):
		_barriers[node.get_tile()] = node

func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(floor(world_position.x / TILE_SIZE), floor(world_position.y / TILE_SIZE))

func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile) * TILE_SIZE + HALF_TILE

func is_tile_wall(tile: Vector2i) -> bool:
	if tilemap == null:
		return true

	# También tratamos como pared cualquier celda fuera del área del nivel.
	# Esto evita que jugador/cajas puedan escaparse fuera de la ventana.
	if not tilemap.get_used_rect().has_point(tile):
		return true

	return tilemap.get_cell_source_id(tile) == 0

func get_moveable_at_tile(tile: Vector2i) -> Moveable:
	for node in moveables:
		if is_instance_valid(node) and node.active and node.tile == tile:
			return node
	return null

func is_fire_tile(tile: Vector2i) -> bool:
	return _fires.has(tile)

func is_hole_tile(tile: Vector2i) -> bool:
	return _holes.has(tile)

func is_exit_door_tile(tile: Vector2i) -> bool:
	return _doors.has(tile)

func is_conveyor_tile(tile: Vector2i) -> bool:
	return _conveyors.has(tile)

func can_continue_on_conveyor(moveable: Moveable) -> bool:
	if not moveable.active or is_completed:
		return false
	var conveyor = _conveyors.get(moveable.tile)
	return conveyor != null and moveable.can_move(conveyor.direction, false)

func can_moveable_enter_tile(moveable: Moveable, target_tile: Vector2i) -> bool:
	if is_tile_wall(target_tile):
		return false

	var barrier = _barriers.get(target_tile)
	if barrier != null and barrier.is_closed():
		return false

	# El jugador puede pisar los portales para recuperar las cajas que salen.
	# Solo las cajas se teletransportan; la puerta sigue bloqueando al jugador.
	if moveable.is_player_piece():
		return not _doors.has(target_tile)

	if _holes.has(target_tile):
		var destination = get_hole_destination(target_tile)
		if destination == null or is_tile_wall(destination):
			return false
		var exit_barrier = _barriers.get(destination)
		if exit_barrier != null and exit_barrier.is_closed():
			return false
		# Reservamos la salida: no se apilan cajas ni se pisa al personaje.
		if get_moveable_at_tile(destination) != null:
			return false
	return true

func get_hole_destination(entrance: Vector2i) -> Variant:
	var hole = _holes.get(entrance)
	if hole == null:
		return null
	var partner := hole.get_node_or_null(hole.linked_hole) as SokobanHole
	if partner == null or partner == hole:
		return null
	var destination := partner.get_tile()
	if _holes.get(destination) != partner:
		return null
	return destination

func begin_turn() -> void:
	if is_completed:
		return

	var piece_states: Array[Dictionary] = []
	for moveable in moveables:
		if is_instance_valid(moveable):
			piece_states.append({
				"node": moveable,
				"state": moveable.capture_state()
			})

	past_states.append({
		"pieces": piece_states,
		"elapsed_seconds": elapsed_seconds,
		"move_count": move_count,
		"is_completed": is_completed
	})

	if past_states.size() > MAX_UNDO_STATES:
		past_states.pop_front()

func finish_player_turn() -> void:
	move_count += 1
	move_count_changed.emit(move_count)
	evaluate_pressure_plates()

func undo_last_move() -> void:
	if past_states.is_empty():
		return

	var snapshot: Dictionary = past_states.pop_back()
	for entry: Dictionary in snapshot["pieces"]:
		var node: Moveable = entry["node"]
		if is_instance_valid(node):
			node.restore_state(entry["state"])

	elapsed_seconds = snapshot["elapsed_seconds"]
	move_count = snapshot["move_count"]
	is_completed = snapshot["is_completed"]
	_recalculate_crates_exited()
	evaluate_pressure_plates()

	timer_changed.emit(elapsed_seconds)
	move_count_changed.emit(move_count)
	crates_changed.emit(crates_exited, total_crates)

func clear_history() -> void:
	past_states.clear()

func restart_level() -> void:
	get_tree().reload_current_scene()

func on_moveable_entered_tile(moveable: Moveable, allow_conveyor: bool = true) -> void:
	if not moveable.active:
		return

	# Los agujeros están conectados en ambos sentidos. La llegada no vuelve a
	# disparar este método: el bloque queda en la salida hasta otro empujón.
	if _holes.has(moveable.tile) and not moveable.is_player_piece():
		var destination = get_hole_destination(moveable.tile)
		if destination != null and can_moveable_enter_tile(moveable, moveable.tile):
			moveable.teleport_to_tile(destination)
		evaluate_pressure_plates()
		return

	# Puerta: las cajas salen del nivel. El jugador no puede usarla.
	if _doors.has(moveable.tile) and not moveable.is_player_piece():
		moveable.deactivate("door")
		_recalculate_crates_exited()
		evaluate_pressure_plates()
		_check_victory()
		return

	# Fuego: la caja de hielo se derrite y luego reaparece en su posición inicial.
	if _fires.has(moveable.tile) and moveable.has_method("melt_and_return_to_start"):
		moveable.melt_and_return_to_start()

	evaluate_pressure_plates()

	# Las flechas desplazan cajas automáticamente, pero no al jugador.
	if allow_conveyor and not moveable.is_player_piece() and _conveyors.has(moveable.tile):
		var conveyor = _conveyors[moveable.tile]
		call_deferred("_apply_conveyor", moveable, conveyor.direction)

func _apply_conveyor(moveable: Moveable, direction: Vector2i) -> void:
	if not is_instance_valid(moveable) or not moveable.active or is_completed:
		return

	if moveable.tween and moveable.tween.is_running():
		await moveable.tween.finished

	if not is_instance_valid(moveable) or not moveable.active:
		return

	var conveyor = _conveyors.get(moveable.tile)
	if conveyor == null or conveyor.direction != direction:
		return

	if moveable.can_move(direction, false):
		moveable.move_on_conveyor(direction)

func _recalculate_crates_exited() -> void:
	# Conservamos el nombre crates_exited para no romper la UI existente, pero
	# ahora representa todas las cajas retiradas por la puerta.
	# Los portales mantienen las cajas activas y no aumentan el contador.
	crates_exited = 0
	for moveable in moveables:
		if is_instance_valid(moveable) and not moveable.is_player_piece() and not moveable.active:
			crates_exited += 1
	crates_changed.emit(crates_exited, total_crates)

func _check_victory() -> void:
	if is_completed or total_crates <= 0:
		return

	# El nivel termina cuando ya no queda ninguna caja activa en el tablero.
	# Los portales solo transportan cajas; hay que retirarlas por la puerta.
	for moveable in moveables:
		if is_instance_valid(moveable) and not moveable.is_player_piece() and moveable.active:
			return

	is_completed = true
	level_completed.emit(elapsed_seconds, move_count)

func evaluate_pressure_plates() -> void:
	var any_changed := false
	for plate in get_tree().get_nodes_in_group("PressurePlate"):
		if plate.has_method("refresh_pressed_state"):
			any_changed = plate.refresh_pressed_state() or any_changed

	for barrier in get_tree().get_nodes_in_group("Barrier"):
		if barrier.has_method("refresh_from_plates"):
			barrier.refresh_from_plates()

	if any_changed:
		_rebuild_interactables()

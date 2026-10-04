extends Node

class Move:
	var node: Moveable
	var direction: Vector2i

var tilemap: TileMapLayer
var moveables: Array[Moveable]

var holes: Array[Hole] = []
var fires: Array[Fire] = []
var redirect_tiles: Array[Node2D] = []
var past_turns: Array[Array] = []

signal level_completed

# Casilla "fuera del mapa" donde mandamos las cajas que ya salieron
const OUT_TILE := Vector2i(-1000, -1000)

# Colores para conectar botones con paredes (channel 0, 1, 2, 3)
const CHANNEL_COLORS = [Color.GOLD, Color.DODGER_BLUE, Color.MEDIUM_ORCHID, Color.SPRING_GREEN]


func _ready() -> void:
	get_tree().scene_changed.connect(level_changed)
	level_changed()
	
func level_changed() -> void:
	tilemap = get_tree().get_first_node_in_group("LevelTileMap")
	past_turns.clear()
	holes.clear()
	fires.clear()
	redirect_tiles.clear()
	
	# Buscar e integrar baldosas de redirección que ya existan en el nivel cargado
	get_tree().create_timer(0.01).timeout.connect(func():
		for node in get_tree().get_nodes_in_group("RedirectTiles"):
			if node is RedirectTile and not redirect_tiles.has(node):
				redirect_tiles.append(node)
	)

func is_tile_wall(tile: Vector2i) -> bool:
	if tilemap == null:
		return false
	# Devuelve true si la celda tiene una pared dibujada
	return tilemap.get_cell_source_id(tile) == 0
	
func get_moveable_at_tile(tile:Vector2i) -> Moveable:
	for node: Moveable in moveables:
		if node.tile == tile:
			return node
	return null

# Registrar el estado previo completo de un objeto en el turno actual
func add_move_to_turn(moveable: Moveable, previous_tile: Vector2i) -> void:
	if past_turns.is_empty():
		past_turns.append([])
	past_turns[-1].append({"object": moveable, "from_tile": previous_tile})
	
	
func undo_last_move() -> void:
	if past_turns.is_empty():
		return
		
	var last_turn: Array = past_turns.pop_back()
	
	# Revertir las posiciones exactas registradas en el turno
	for entry in last_turn:
		var moveable: Moveable = entry["object"]
		var from_tile: Vector2i = entry["from_tile"]
		
		if is_instance_valid(moveable):
			moveable.tile = from_tile
			moveable.position = Vector2(from_tile) * 128.0 + Vector2(64.0, 64.0)
			
			# Si es una caja bomba, restaurar su contador si aplica
			if moveable.has_method("restore_move"):
				moveable.restore_move()
					
func clear_history() -> void:
	past_turns.clear()
	
func get_hole_at_tile(target_tile: Vector2i) -> Hole:
	for hole in holes:
		if hole.tile == target_tile:
			return hole
	return null
	
func get_fire_at_tile(target_tile: Vector2i) -> Fire:
	for fire in fires:
		if fire.tile == target_tile:
			return fire
	return null
	
func is_tile_empty(check_tile: Vector2i) -> bool:
	if is_tile_wall(check_tile):
		return false
	if get_moveable_at_tile(check_tile) != null:
		return false
	return true

func clear_spawn_for_player(spawn_tile: Vector2i) -> void:
	# Buscar el nodo del jugador entre los moveables
	var player: Moveable = null
	for m in moveables:
		if m.get_script() != null and m.get_script().resource_path.ends_with("player.gd"):
			player = m
			break

	# Si el jugador está justo en la casilla donde va a reaparecer la caja:
	if player and player.tile == spawn_tile:
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in directions:
			var target_tile = spawn_tile + dir
			if is_tile_empty(target_tile):
				player.tile = target_tile
				player.position = Vector2(target_tile) * 128.0 + Vector2(64.0, 64.0)
				break
				
func get_redirect_at_tile(target_tile: Vector2i) -> Node2D:
	for rt in redirect_tiles:
		if rt.tile == target_tile:
			return rt
	return null


func channel_color(channel: int) -> Color:
	return CHANNEL_COLORS[posmod(channel, CHANNEL_COLORS.size())]

func get_door_at_tile(t: Vector2i) -> ExitDoor:
	for door in get_tree().get_nodes_in_group("exit_doors"):
		if door.tile == t:
			return door
	return null

func get_gate_at_tile(t: Vector2i) -> GateBlock:
	for gate in get_tree().get_nodes_in_group("gates"):
		if gate.tile == t:
			return gate
	return null

# ¿Esta cosa es una caja que hay que sacar por la puerta?
func is_exit_crate(m: Node) -> bool:
	return not (m is Player) and not (m is Stone)

# ¿Hay algo nuevo (pared cerrada o puerta) que impida a "mover" entrar a la casilla t?
func is_blocked_for(mover: Node, t: Vector2i) -> bool:
	var gate := get_gate_at_tile(t)
	if gate and gate.is_closed():
		return true
	var door := get_door_at_tile(t)
	if door and not is_exit_crate(mover):
		return true
	return false

func count_crates_remaining() -> int:
	var count := 0
	for m in moveables:
		if is_instance_valid(m) and is_exit_crate(m) and m.tile != OUT_TILE:
			count += 1
	return count

func check_level_complete() -> void:
	if count_crates_remaining() > 0:
		return
	level_completed.emit()
	show_message("¡Nivel completado!")

func show_message(text: String) -> void:
	var layer := CanvasLayer.new()
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(label)
	get_tree().current_scene.add_child(layer)

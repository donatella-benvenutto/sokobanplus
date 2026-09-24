extends Node

class Move:
	var node: Moveable
	var direction: Vector2i

var tilemap: TileMapLayer
var moveables: Array[Moveable]

var holes: Array[Hole] = []
var past_turns: Array[Array] = []

func _ready() -> void:
	get_tree().scene_changed.connect(level_changed)
	level_changed()
	
func level_changed() -> void:
	tilemap = get_tree().get_first_node_in_group("LevelTileMap")
	past_turns.clear()

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

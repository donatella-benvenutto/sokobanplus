#class_name IceCrate
#extends Moveable
#
#func move(direction: Vector2i) -> void:
	## Realiza el primer movimiento que activó el jugador
	#slide(direction)
	#Level.add_move_to_turn(self, direction)
	#
	## Continúa deslizándose paso a paso hasta encontrar un obstáculo
	#while can_slide_further(direction):
		#slide(direction)
		#Level.add_move_to_turn(self, direction)
#
#func can_slide_further(direction: Vector2i) -> bool:
	#var next_tile := tile + direction
	#
	## Si la casilla siguiente es una pared, se detiene
	#if Level.is_tile_wall(next_tile):
		#return false
		#
	## Si la casilla siguiente tiene cualquier otro objeto (caja o jugador), se detiene
	#if Level.get_moveable_at_tile(next_tile) != null:
		#return false
		#
	#return true

class_name IceCrate
extends Moveable

@export var ice_slide_duration: float = 0.25

func slide(direction: Vector2i) -> void:
	tile += direction
	var target := Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(self, "position", target, ice_slide_duration)\
		 .set_trans(Tween.TRANS_LINEAR)
		
func move(direction: Vector2i) -> void:
	# Bucle que continúa desplazando la caja de hielo mientras el frente esté libre
	while true:
		var next_tile := tile + direction
		
		# Se detiene si la siguiente casilla es una pared o si hay otra caja/jugador
		if Level.is_tile_wall(next_tile) or Level.get_moveable_at_tile(next_tile) != null:
			break
			
		slide(direction)
		Level.add_move_to_turn(self, direction)

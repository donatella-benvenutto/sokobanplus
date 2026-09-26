class_name Hole
extends Node2D

@export var paired_hole: Hole
@export var hole_color: Color = Color(0.1, 0.1, 0.2)
@export var border_color: Color = Color(0.4, 0.6, 1.0)

var tile: Vector2i

func _ready() -> void:
	tile = Vector2i(position / 128.0)
	position = Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	
	if "holes" in Level:
		Level.holes.append(self)

# Se ejecuta cuando una caja que estaba encima del agujero intenta teletransportarse (ej. si el destino se liberó)
func try_teleport_occupant() -> void:
	if not paired_hole:
		return
		
	var moveable := Level.get_moveable_at_tile(tile)
	if moveable and not moveable.is_teleporting:
		if Level.get_moveable_at_tile(paired_hole.tile) == null:
			moveable.teleport_to(paired_hole.tile)
			
# Se llama cuando este agujero se acaba de liberar para avisarle a la pareja que intente enviar su caja
func notify_freed() -> void:
	if paired_hole:
		paired_hole.try_teleport_occupant()
		
func _draw() -> void:
	var radius := 40.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.2, 0.6))
	draw_circle(Vector2.ZERO, radius + 4.0, border_color)
	draw_circle(Vector2.ZERO, radius, hole_color)

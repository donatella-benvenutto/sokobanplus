class_name Hole
extends Node2D

# Pareja de este agujero para el teletransporte
@export var paired_hole: Hole
@export var hole_color: Color = Color(0.1, 0.1, 0.2) # Color oscuro para el centro
@export var border_color: Color = Color(0.4, 0.6, 1.0) # Borde de color (ej. azul)

var tile: Vector2i

func _ready() -> void:
	# Convertimos la posición inicial en pantalla a coordenadas de grilla
	tile = Vector2i(position / 128.0)
	# Centramos el dibujo en la casilla de 128x128
	position = Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	
	# Registrar el agujero en la lógica global del nivel si existe el arreglo
	if "holes" in Level:
		Level.holes.append(self)

func _draw() -> void:
	# Dibujamos una elipse/óvalo acostado mediante un círculo escalado en Y
	var radius := 40.0
	
	# Dibujar el borde exterior del óvalo
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.2, 0.6))
	draw_circle(Vector2.ZERO, radius + 4.0, border_color)
	
	# Dibujar el centro oscuro del óvalo
	draw_circle(Vector2.ZERO, radius, hole_color)

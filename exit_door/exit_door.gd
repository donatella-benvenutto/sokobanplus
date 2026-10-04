class_name ExitDoor
extends Node2D
## Puerta de salida: cualquier caja que llegue a esta casilla sale del nivel.
## El jugador y las piedras (Stone) no pueden pisarla (eso lo decide Level.is_blocked_for).

var tile: Vector2i

func _ready() -> void:
	# Igual que el fuego: calcula su casilla y se centra en ella
	tile = Vector2i(position / 128.0)
	position = Vector2(tile) * 128.0 + Vector2(64.0, 64.0)
	add_to_group("exit_doors")

func _process(_delta: float) -> void:
	# Cada frame revisamos todas las cosas que se mueven del nivel
	for m in Level.moveables:
		if not is_instance_valid(m):
			continue

		# Caja que ya había salido, pero el Undo (Z) la devolvió al tablero: la volvemos a mostrar
		if m.get_meta("exited", false):
			if m.tile != Level.OUT_TILE:
				restore_crate(m)
			continue

		# Una caja llegó a la puerta: sale
		if m.tile == tile and Level.is_exit_crate(m):
			take_out(m)

func take_out(crate: Moveable) -> void:
	crate.set_meta("exited", true)

	# Cortamos cualquier animación que tuviera (por ejemplo una caja de hielo deslizándose)
	if crate.tween and crate.tween.is_running():
		crate.tween.kill()

	# La mandamos a una casilla "fuera del mapa" para que nada la vuelva a encontrar
	crate.tile = Level.OUT_TILE

	# Animación: entra a la puerta, se achica y desaparece
	crate.tween = crate.create_tween()
	crate.tween.tween_property(crate, "position", position, 0.1)
	crate.tween.tween_property(crate, "scale", Vector2(0.2, 0.2), 0.25)
	crate.tween.parallel().tween_property(crate, "modulate:a", 0.0, 0.25)
	crate.tween.tween_callback(func():
		crate.visible = false
		Level.check_level_complete()
	)

func restore_crate(crate: Moveable) -> void:
	crate.set_meta("exited", false)
	crate.visible = true
	crate.scale = Vector2.ONE
	crate.modulate = Color.WHITE

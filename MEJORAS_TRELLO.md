# Sokoban Plus — mejoras implementadas desde Trello

Esta copia conserva el proyecto original y agrega una primera implementación de las features que estaban en el tablero.

## Ya implementado en esta versión

- **Puerta de salida para cajas**: está ubicada en el borde derecho del nivel. El jugador no puede atravesarla. Las cajas sí pueden entrar y quedan marcadas como fuera del nivel.
- **Contador de cajas**: HUD con `Cajas: salidas / total`.
- **Condición de victoria**: cuando todas las cajas salen por la puerta se muestra el panel de nivel completado.
- **Agujeros conectados**: una caja que entra en uno aparece en el otro y queda allí, sin volver automáticamente. Funciona con todos los tipos de caja. Si la salida está ocupada, no se puede entrar. El jugador puede pisarlos pero no se teletransporta, para poder empujar las cajas que salen.
- **Fuego + caja de hielo**: la caja se desliza hasta el fuego, se derrite y luego reaparece en su posición inicial.
- **Piso con flechas**: desplaza automáticamente una caja hacia la dirección de la flecha mientras haya otro piso con flecha y espacio libre.
- **Undo mejorado (`Z`)**: ahora guarda el estado completo de las cajas, incluyendo cajas que salieron o atravesaron portales, contador de bomba y estado derretido.
- **Reiniciar (`R`)**: recarga el nivel.
- **WASD + flechas** para mover al personaje.
- **Límites del tablero**: una celda fuera del `used_rect` del TileMap se considera pared, evitando que jugador/cajas salgan del mapa.
- **Ventana corregida**: viewport lógico de 1920×1152 (15×9 tiles de 128) y ventana inicial de 1280×768 manteniendo la proporción.
- **Timer y movimientos** en HUD.
- **Cámara** centrada en el tablero.
- **Background** simple como placeholder.

## Demo colocada en el nivel actual

Para que las mecánicas puedan probarse inmediatamente al abrir el proyecto:

- Puerta: tile `(14, 6)`. Se quitó la pared exterior de esa celda.
- Flechas: tiles `(11, 6)`, `(12, 6)`, `(13, 6)`, apuntando a la puerta.
- Fuego: tile `(8, 4)`, en la trayectoria de la caja de hielo que ya estaba en `(6, 4)`.
- Agujeros: tiles `(4, 4)` y `(12, 4)`, conectados en ambos sentidos mediante `linked_hole` (campo Linked Hole en el Inspector).

Todo esto se puede mover visualmente desde Godot; no está hardcodeado en `level.gd`.

## Nice-to-have preparado (no colocado en el nivel)

Se agregaron escenas listas para arrastrar desde FileSystem:

- `crate/timed_crate.tscn`: caja con temporizador. El contador arranca con el primer empujón; si llega a 0 vuelve al inicio.
- `crate/metal_crate.tscn`: caja metálica.
- `interactables/pressure_plate.tscn`: botón que sólo detecta una caja metálica.
- `interactables/barrier.tscn`: barrera vinculable con el botón mediante `link_id` (por defecto `A`).

Para usar botón + barrera: colocar ambos, dejar el mismo `link_id` y colocar una `MetalCrate` en el nivel.

## Controles

- Flechas o WASD: mover / empujar.
- `Z`: deshacer el último turno.
- `R`: reiniciar el nivel.

## Archivos principales cambiados

- `level.gd`: manejo de nivel, hazards, puerta, victoria, timer, contador y undo por snapshots.
- `moveable.gd`: base común de movimiento/estado.
- `player/player.gd`: controles y turnos.
- `crate/bomb_crate.gd`: reset usa el valor inicial configurado, ya no asume siempre 4.
- `crate/ice_crate.gd`: deslizamiento + interacción con fuego aun al pasar por encima.
- `ui/game_ui.*`: HUD y victoria.
- `interactables/*`: puerta, agujero, fuego, flechas, botón y barrera.

## Importante al abrirlo

Esta versión fue preparada sobre el proyecto que enviaron. Conviene abrirla como una copia/branch y probarla en la misma versión de Godot del proyecto antes de mergearla al `main` del equipo. Los dibujos de puerta, fuego, agujero y flechas son placeholders hechos por código para poder validar las mecánicas; después pueden reemplazarlos por sprites propios sin tocar la lógica.

## Recuperación de jugadas

Las cajas sólo se empujan, como en el Sokoban clásico. Si una queda atrapada o la jugada no conviene, `Z` restaura el estado completo del turno anterior.


## Pantalla de nivel completo
- El nivel termina automáticamente cuando ya no queda ninguna caja activa.
- Solo cuentan como retiradas las cajas que salen por la puerta; atravesar un portal no elimina cajas.
- Al retirar la última caja, el cronómetro se congela.
- Aparece una pantalla central **¡NIVEL COMPLETO!** con el tiempo final y la cantidad de movimientos.
- `R` permite reiniciar el nivel desde esa pantalla.

## Corrección de cajas, flechas y salida

- La caja con contador consume un movimiento por empujón del jugador. El transporte automático de las flechas no consume movimientos adicionales.
- Si el último empujón disponible deja la caja sobre una flecha, se completa primero el transporte. Si llega a la puerta, queda retirada; si la cinta está bloqueada o termina fuera de la puerta, se activa el reinicio por contador agotado.
- El hielo se detiene en la primera flecha que toca durante el deslizamiento y continúa en la dirección de esa flecha, incluso al entrar de costado.
- La puerta retira también el hielo y la caja con contador. Los efectos pendientes no pueden hacer reaparecer una caja retirada.
- El parpadeo del reinicio queda registrado como animación de la caja para evitar nuevos empujones durante ese efecto.
- Z restaura el estado previo al empujón y al recorrido automático; R reinicia el nivel.

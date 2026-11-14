# 0.20 — movimiento, intervención y avance histórico

La prioridad es jugar desde el mapa: **Jugar**, **Construir**, **Explorar** e **Intervenir**, conservando la autonomía. Las acciones permanecen disponibles durante los guardados de la reproducción; la confirmación espera la escritura pendiente.

## Movimiento real y representación colectiva

`LocalLife` v1 guarda posición, posición anterior, destino, camino y espera de cada habitante destacado. Decide visitas a lugares existentes y avanza diariamente sin depender de la cámara. Replanifica ante nuevas huellas, retira fallecidos y conserva rutas al cargar. Las visitas no producen materiales, no asignan oficios ficticios ni consumen el PRNG del mundo.

Las figuras comunes representan grupos incluidos en los adultos disponibles y en el trabajo productivo confirmado. Caminan por rutas locales, trabajan, transportan y descansan como presentación de esa contabilidad. No son personas adicionales ni asignaciones individuales persistentes. Los caminos evitan edificios; todavía no completan toda la logística física de M3. Los personajes destacados se dibujan desde posiciones persistentes, con interpolación visual y seguimiento de cámara. El marcador de ciudad depende de sus construcciones, no de personas que caminan.

Los mundos nuevos incluyen vida local. Cargar una partida anterior conserva su estado: pulsar Jugar activa la extensión de posiciones y guarda previamente un punto de recuperación. No inventa genealogías ni cambia recursos, biología o conocimientos. Se mantiene mundo 1, checkpoint 3 y reglas materiales 11; la extensión tiene versión propia y rechaza versiones desconocidas.

## Saltos

Se reutiliza contenido ya validado y fijado, validando cada mundo nuevo y sus eventos pendientes. Se conserva la validación completa al importar o cambiar paquetes. Los cálculos enteros comunes tienen una ruta rápida exacta y recurren a BigInt fuera del intervalo seguro. Las rutas locales tienen cachés acotadas y búsquedas de entradas directas.

El trabajador calcula las mismas jornadas, sin reproducirlas visualmente, envía proyecciones compactas del mapa y confirma por escritura. La fecha calculada y la guardada son distintas. Cada lote tiene hasta cinco años o un presupuesto de cálculo de un segundo, cediendo control cada treinta días. Un cierre puede repetir hasta cinco años de cálculo sin confirmar; mantiene el objetivo y el último checkpoint íntegro. Cancelación y recuperación siguen pendientes de aceptación final sobre el dispositivo de referencia.

Un siglo activo con visitas y catálogo real tardó **32.421 ms en el servidor**, con 27.892 ms de cálculo, 105 ms de proyección y 4.424 ms de confirmación. El candidato anterior tardó 43.714 ms; ambos produjeron el mismo hash completo, incluyendo rutas e historia. Una caché experimental de producción empeoró el resultado a 38.611 ms y fue retirada. **No se ha conseguido ni acreditado un siglo en cinco segundos en el teléfono.** Esa expectativa del usuario permanece pendiente; no se sustituyen reglas por una aproximación silenciosa.

## Continuidad

M3 continúa en curso. Visitas persistentes y equipos visibles no completan todas las asignaciones, reservas, construcción situada ni transporte local. Se conservan los 174 requisitos y los pendientes de M2–M11: territorios, instituciones, eras, especies, inmortalidad, narrativa ampliada y aceptación final. No se declara terminado el juego. Evidencia de compilación, pruebas, Android y descarga: `docs/validation/living/`.

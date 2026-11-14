# Dirección vigente: un planeta autónomo

Aclaración del usuario del 14 de noviembre de 2026: «ellos tienen libre albedrío, yo puedo intervenir a mi gusto pero ellos ya tienen decisiones propias [...] de mí no dependerá su evolución».

Esta instrucción refina el diseño acordado y prevalece sobre la entrada centrada en gestión manual de la comunidad. Se conservan PROJECT_SPEC.md, REDESIGN_SPEC.md y sus identificadores; no se modifican sus hashes ni se eliminan requisitos. Este documento describe dirección y aceptación pendientes, no funciones nuevas ya ejecutadas.

## Experiencia principal

- Planeta → regiones y territorios políticos → asentamientos → habitantes. El acercamiento debe revelar detalle del mismo mundo, con entidades, fecha e historia compartidas. Observar o cambiar de escala no consume azar ni cambia decisiones.
- La representación actual es 2D. Esta aclaración no exige un globo 3D: se priorizan lectura, zoom conectado y rendimiento Android. Los países y fronteras deben surgir de sociedades y territorio real, no de regiones dibujadas sin reglas.
- El jugador observa, sigue historias e interviene cuando lo desea. No necesita asignar oficios o aprobar cada edificio, investigación, relación o crisis para que continúe la partida.
- Todas las sociedades conservan autonomía, incluida la seleccionada o favorecida por el jugador. Sus decisiones dependen de necesidades, conocimientos, instituciones, personalidad, relaciones, recursos y entorno.
- Construcción, aprendizaje, transporte y decisiones difíciles utilizan las mismas restricciones materiales que las intervenciones. La autonomía no recibe recursos ocultos para aparentar progreso.
- El avance histórico puede producir prosperidad, estancamiento, regresión o extinción. No garantiza que todas las sociedades alcancen cada era ni provoca guerras por obligación.
- La población común sigue agregada y los personajes destacados conservan decisiones y vínculos individuales, según el modelo ya acordado. Esta aclaración no introduce control manual de habitantes ni promete una simulación ilimitada por persona.

## Intervención y tiempo

Seleccionar una entidad es inspeccionarla. Intervenir permite emitir una decisión concreta o influir en prioridades, con coste, alcance y consecuencias claros. No debe desactivar de manera persistente el gobierno autónomo. La autoridad para emitir una intervención debe distinguirse del régimen de autonomía.

Las decisiones no atendidas deben tener resolución autónoma coherente y quedar en la crónica. Las pausas por acontecimientos serán una preferencia opcional, no una obligación de responder para continuar. No desaparecen hechos, compromisos o cadenas por ignorarlos.

Se mantienen pausa, reproducción y saltos históricos. Autonomía significa que el mundo actúa mientras avanza el tiempo del juego, sin órdenes rutinarias del usuario. Se conserva la regla de no avanzar por tiempo real al cerrar la aplicación.

La entrada predeterminada debe favorecer observación del planeta y acercamiento libre. Barrio Cero continúa existiendo como comunidad que se puede conocer o favorecer. La guía de diez decisiones será un recorrido opcional de intervenciones: no una condición para que nazcan, construyan o evolucionen las sociedades.

## Diagnóstico histórico de 0.14

| Área | Implementación encontrada | Corrección pendiente |
|---|---|---|
| Escalas | `WorldGame` y `_navigate` presentan mundo, región y asentamiento, con zoom dentro de vistas. | Conectar las escalas por acercamiento y selección, conservando identidad y estado. |
| Inicio | `WorldState.controlledId` empieza en `s0`. | Priorizar observación y desarrollo autónomo del mundo. |
| Autonomía | `_urgentAutonomy`, `_monthly` y otras reglas excluyen a la sociedad controlada cuando no se delegan decisiones. | Inspección e intervención no deben suspender sus decisiones propias. |
| Autoridad | `Simulation.submit` exige el actor controlado; la interfaz invita a asumir dirección para ordenar. | Separar intervención puntual, selección e inteligencia autónoma, con transacción y compatibilidad explícitas. |
| Acontecimientos | Hay decisiones delegadas parciales y `stopOnCrisis` puede detener el avance por asuntos pendientes. | Resolver decisiones no atendidas y evitar bloqueos obligatorios del observador. |
| Territorio y eras | Existen bases parciales; no hay países con fronteras completas ni seis eras funcionales. | Completar E2–E4 y demostrar evolución material sin intervención. |

## Integración 0.15

Los mundos creados por `SessionController.createWorld` empiezan sin sociedad bajo control manual y sin parada obligatoria por crisis. La interfaz abre el mundo y permite observar sin completar una guía. La factoría física de reglas 11 conserva sus valores históricos para compatibilidad; es la creación de la sesión la que selecciona el modo autónomo existente, sin cambiar reglas, mapas antiguos ni esquema de guardado.

`Intervention` utiliza la transacción validada de `Simulation.submit` con autoridad temporal, restaurada antes de confirmar el checkpoint. Los costes, trabajo y recibos pertenecen a la comunidad elegida. No se permite convertir una intervención en toma de control permanente. Una revisión o generación antigua se rechaza en la cola, también si se importó otro mundo antes de ejecutar la orden. Los rechazos, repeticiones y errores de disco tienen pruebas de integridad.

Las partidas manuales se cargan sin alterarlas. La acción explícita Dejar actuar al mundo conserva recursos y compromisos, entrega las decisiones que esperaban al jugador a sus consejos para el siguiente día y desactiva su parada obligatoria. No es una migración de las reglas físicas. Los modos antiguos no se convierten silenciosamente al leerlos.

El zoom semántico enlaza mundo, región y asentamiento, eligiendo una comunidad que esté realmente bajo el foco. Mantiene el punto de acercamiento y vuelve a la escala superior al alejarse. Hay pruebas de gestos reales de dos dedos y de invariancia del estado. Inspeccionar habitantes no detiene la reproducción; las confirmaciones de intervenciones recuperan el estado de reproducción anterior cuando siguen en la misma sesión activa.

La referencia reproducible de un año, creada sin editar existencias ni decisiones, pasa de 42 a 69 sitios y de 0 a 27 tecnologías, con cero órdenes del jugador. Sus 144 habitantes iniciales pasan a 141: se conservan las pérdidas reales. La ejecución Android debe contrastarse contra el mundo completo de referencia, no solo estos contadores. La evidencia está en `docs/validation/observer/`.

Esto no completa los países con celdas propias, instituciones, familias completas, eras, especies o director narrativo ampliado. La región actual es una escala de observación; las áreas de influencia dibujadas no acreditan fronteras políticas reales. Las obligaciones restantes de E1–E6 continúan abiertas.

## Aceptación e integración

1. Un mundo con cero órdenes del jugador construye, investiga, sostiene población y resuelve oportunidades y crisis cuando sus condiciones lo permiten. Los escenarios adecuados demuestran progreso y pérdida de capacidades; los finales válidos se distinguen del bloqueo de una IA.
2. Seleccionar, acercarse y seguir una sociedad no cambia su trayectoria frente al mismo escenario sin cámara ni paneles. La prueba incluye guardado/reanudación y contenido real.
3. Una intervención válida produce exactamente sus efectos, conserva recursos y trabajo y deja actuar después a sus habitantes y gobierno. Un rechazo no cambia el mundo.
4. Ignorar un acontecimiento con plazo produce una resolución autónoma válida, una sola vez, con participantes vivos y consecuencias persistentes. No queda esperando eternamente una pulsación.
5. Cada asentamiento y sus habitantes se localizan desde la escala planetaria. Las fronteras, desplazamientos y transformaciones proceden de la simulación.
6. Las primeras diez decisiones siguen siendo una aceptación del camino de intervención. Se añade como condición transversal que ese camino sea opcional y que el mundo no dependa de completarlo.

Prioridad siguiente: corregir el ciclo observación/intervención/autonomía en E1–E2 antes de seguir ampliando gestión manual o cosmética. Después, integrar territorio, instituciones, eras y director según E2–E5. Los cambios de reglas se versionarán; se preservarán partidas, contenido fijado y copias originales. Las baterías largas se ejecutarán tras estabilizar las reglas, sin reiniciar las existentes por esta documentación.

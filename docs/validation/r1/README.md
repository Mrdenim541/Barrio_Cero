# R0/R1 — primera integración del rediseño

La versión 0.2.0 conserva las reglas y los mundos de reconstrucción existentes. No implementa todavía prehistoria, especies alternativas, eras funcionales ni familias persistentes. No es la entrega completa del juego.

## Cambios verificables

- Registro independiente de 68 requisitos nuevos y continuidad exacta de los 106 bloques originales. `PROJECT_SPEC.md` y `docs/requirements.json` no fueron modificados.
- Navegación Barrio/Mundo/Historia; entrada centrada en el asentamiento y tiempo pausado. Gobierno, conocimiento, exploración y diplomacia siguen accesibles mediante acciones contextuales. Las fichas muestran habitantes, obras, reservas y conocimientos legibles.
- `Simulation.preview` comparte evaluación con `submit`, informa costes, trabajadores y duración sin modificar mundo/PRNG. La confirmación pausa reproducción y exige conservar la revisión mostrada.
- `SessionController` es propietario de mundo, espacio, contenido y ajustes confirmados. La interfaz no escribe checkpoints directamente. Las operaciones se serializan y publican después de la escritura.
- Los resultados históricos llevan generación/revisión/espacio. Todos los lotes esperan confirmación de persistencia, incluido el último. Cancelar no confirma un lote pendiente.

## Evidencia y alcance

- `baseline-tests.log`: 39 pruebas de la base antes de la integración.
- `tests.log`: batería completa de 62 pruebas aprobadas. Incluye diez pruebas nuevas de consultas y diez de sesión/trabajador, más tres tamaños con texto ampliado.
- `ui-tests-final.log`: siete pruebas de interfaz repetidas después de la última corrección visual; flujo crear/construir/avanzar/importar/espacios/reapertura y tamaños 320/360/412 con texto 1,5×. No se presenta esta repetición focalizada como otra batería completa.
- `analyze-final.log`: análisis limpio del código final.
- `content.log`, `original-requirements.log`, `redesign-requirements.log`: validación estructural, no prueba de jugabilidad. El registro ampliado incluye catorce rechazos deliberados.
- `build-profile-final.log`, firma y badging: compilación profile, paquete `com.barriocero.eras`, versión 0.2.0+2 y mínimo API 24. Firma de pruebas, sin publicación en tienda.
- `android-install-final.log` y `android-launch-final.log`: instalación por actualización y arranque, registrados por separado.
- `results.json`: hashes, resultados nativos y límites; consultar este archivo para conocer qué recorridos terminaron.
- `reference-reconstruction-day2.json.gz`: bytes exactos de la partida sintética anterior a actualizar (semilla 42, día interno 2). La actualización inicial conservó su SHA-256. La referencia sirve para futuras regresiones y migraciones.
- `native-smoke-script.txt` conserva la automatización ejecutada con ADB en esta instancia, sus rutas y su partida de referencia. No es un runner genérico para partidas arbitrarias.

## Incidencias encontradas y corregidas

Las pruebas detectaron texto temporal partido, construcción fuera del área visible a 320 puntos y mensajes flotantes que tapaban el avance. Se corrigieron espacio de los controles, tamaño de la ficha y presentación integrada de resultados.

La inspección Android encontró dibujo del mapa fuera de su área, detrás de la ficha. `00-before-map-clip.png` conserva ese fallo; las capturas posteriores al recorte muestran el resultado corregido. Las imágenes proceden de la aplicación ejecutada, no de una ilustración.

## Límites

El emulador Android 10/API 29 funciona por software, sin KVM. No acredita FPS, latencia ni memoria del teléfono de referencia. No se repitieron las baterías de doscientos/mil años en este bloque; sus resultados históricos y sus limitaciones siguen documentados en H1. La selección narrativa sigue usando las reglas existentes hasta R8. El nuevo esquema y la conversión de mundos corresponden a R3/R10; no se cambió silenciosamente la versión de reglas de los guardados actuales.

## Revisión del usuario

El usuario observó que las capturas siguen pareciendo el primer prototipo que rechazó. R1 permanece parcial: una integración técnica aprobada no equivale al rediseño visual y jugable esperado. La próxima iteración debe contrastar composición, escala, detalle e interacción del asentamiento con las láminas objetivo y con el estado real de simulación.

## Recorrido Android completado y repeticiones focalizadas

La consulta de construcción conservó el checkpoint; confirmar añadió una obra y descontó 20 de madera y 5 de piedra. El avance confirmó día interno 2 → 3. Cambiar Historia/Mundo no modificó el guardado. El selector importó la referencia del día 2 y restauró su mundo exacto.

La automatización inicial falló después por una raíz nula de UIAutomator y lectura de jerarquía antigua. Se repitió únicamente reapertura, obteniendo el mismo mundo después de cierre forzado. La exportación nativa creó un documento; la lectura inmediata del primer harness falló, y una lectura posterior verificó el documento completo con el SHA-256 exacto de la referencia. Se conservan ambos fallos de automatización y sus comprobaciones focalizadas; no se declara una ejecución única ininterrumpida aprobada.

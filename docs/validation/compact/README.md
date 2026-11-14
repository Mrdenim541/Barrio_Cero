# Pantalla compacta 0.14

Mejora de presentación dentro de E1. No cierra las diez decisiones completas, la revisión de comprensión ni el resto de E1–E6.

## Cambios comprobables

- La ficha habitual muestra nombre, dirigente, alimento, agua, habitantes y una acción destacada. Los indicadores abren detalles; los costes siguen antes de confirmar.
- Construir, guía, último resultado y vista del mapa se abren desde Más acciones. Las funciones anteriores se conservan.
- Los mensajes temporales no reducen la altura de la escena. Se retiran los rótulos lejanos, el texto duplicado sobre el mapa y dos controles permanentes.
- La vista tiene carga/fallo explícitos. Un borde breve corresponde a un sitio realmente añadido después de una obra; consultar, ordenar o cargar una partida no lo activa.

## Pruebas y procedencia

`integration-results.json` conserva una ejecución del perfil integration: validadores, análisis limpio, 192 pruebas y APK profile. La batería focalizada de 14 casos está incluida en esas 192, no se suma. Las pruebas de interfaz recorren 320/360/412 con texto ampliado, consultan agua y guía sin alterar el mundo, conservan área de escena tras una orden y comprueban guardado/importación/reapertura. El feedback se prueba terminando una construcción mediante el motor, también con movimiento reducido y cambio de mundo.

`simulation-inputs.json` contrasta los 19 archivos congelados de simulación y contenido de reglas 11, sin diferencias. No se reinicia la matriz larga por este cambio de presentación. El esquema de guardado, sesión, trabajador y contenido fijado permanecen iguales.

## Android

El guion `native/` instala el APK, abre el checkpoint prehistórico real producido por 0.13 y comprueba detalle de agua sin escritura, investigación de técnicas de talla y pago de cinco conocimientos sin avanzar el tiempo. Muestra también Más acciones y Construir. Se detuvo intentando pulsar el taller sin desplazar el catálogo: el resultado se conserva como fallo del recorrido, no como aceptación completa.

`continuation/` intentó retomar ese checkpoint, pero el emulador volvió al lanzador antes de abrir la partida. `vulkan-startup-crash.log` registra un SIGSEGV en `IplrVkFenceWait`, hilo del renderizador Vulkan. Se conserva como fallo, no como aceptación. Las partidas originales se restauraron exactamente.

`continuation-retry/` reintenta únicamente esa parte con el mismo APK y el checkpoint exacto que ya había aprendido la técnica. Utiliza la acción contextual Preparar herramientas para cotizar y ordenar el taller, sin repetir investigación ni añadir recursos. Su resultado determina por separado coste material, sitio terminado y reapertura. Los procesos apartan las partidas originales y las restauran comparando todos sus hashes. El éxito de un reintento no elimina el fallo gráfico registrado.

Las capturas de mapa esperan terreno del bioma real en la franja `(8,292)–(260,340)`, que antes ocupaba la ficha extensa. Se rechaza una bienvenida o un mapa vacío; la revisión manual debe confirmar también fecha, edificios y composición. Se conservan los PNG directamente de Android, sin retoque ni generación conceptual.

Es un emulador API29 por software de 320×640. Ni su velocidad ni estas capturas acreditan los objetivos del teléfono de referencia. `results.json` distingue las comprobaciones aprobadas de la parte fallida del primer guion y conserva el SHA-256 del APK.

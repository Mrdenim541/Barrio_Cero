# Experiencia inicial 0.13 — alcance de evidencia

Se conserva reglas 11. Esta integración añade una ficha de necesidades, una sugerencia con coste/requisitos reales, una guía opcional y mejoras de lectura local. E1 permanece parcial; el recorrido completo de las primeras diez decisiones, la comprensión por una persona nueva y la experiencia final ampliada siguen pendientes. No se acredita rendimiento de teléfono físico ni juego terminado.

## Pruebas y compilación

- `focused-tests.log`: 17 casos focalizados aprobados, incluidos guía/navegación con texto ampliado en 320/360/412, acceso a viajes y consultas sin mutación.
- `integration-results.json` y sus logs: una ejecución del perfil integration con validadores, análisis limpio, 191 pruebas y compilación profile. Las 17 focalizadas están incluidas en las 191; no se suman como casos adicionales.
- Tras inspeccionar las capturas se corrigió exclusivamente la superposición de rótulos en `world_game.dart`. `final-sources.json` identifica ese único archivo distinto desde la suite. El ajuste tiene análisis limpio y compilación propios (`final-analyze.log`, `final-build.log`) y comprobación visual en el APK final; no se presenta como una repetición de las 191 pruebas sobre ese ajuste.
- `apk-checks.json`, `package.log` y `signature.log`: paquete/versiones/API/arquitecturas y verificación de firma del APK final. `results.json` identifica el binario exacto por SHA-256.
- `unchanged-simulation-inputs.json`: los 19 archivos de simulación y contenido contrastados con los inputs AOT congelados de reglas 11 coinciden. La matriz larga continúa sin reiniciarse y mantiene su versión/procedencia en `../transit/results.json`.

## Android real ejecutado en emulador

`native-initial-timeout/` conserva el primer arranque fallido: pantalla blanca y falta de jerarquía accesible antes de agotarse la espera. Se restauraron exactamente las partidas originales. No cuenta como recorrido aprobado.

`native/` conserva el recorrido posterior del candidato anterior a la corrección de rótulos: origen prehistórico creado desde la interfaz, guía sin mutación, coste de refugio antes de confirmar, gasto de 8 madera/2 piedra, obra terminada a los treinta días con una ubicación más y capacidad 32, marca de una decisión, navegación Mundo/Historia y reapertura exacta. El SHA-256 registrado corresponde a `build/deliverables/barrio-cero-eras-0.13.0-before-label-fix.apk`, conservado separadamente.

`final-native/` comprueba el binario final después del ajuste exclusivo de rótulos. Reutiliza el checkpoint producido normalmente por el recorrido anterior: no añade materiales, habitantes o decisiones. Comprueba instalación, apertura y reapertura exacta. Sus dos primeras capturas mostraron un mapa vacío antes de terminar la carga y se rechazan como evidencia visual. La tercera muestra el barrio cargado y fue revisada manualmente.

`visual-ready/` intentó esperar la carga mediante variedad de colores. Su primer fotograma resultó ser todavía la bienvenida: esa condición automática era insuficiente y **su resultado automático no acredita preparación del mapa**, aunque el archivo de resultado histórico diga `passed`. La segunda captura sí muestra el asentamiento en encuadre general y fue inspeccionada manualmente.

`render-readiness.json`, ejecutado con `tool/verify_map_capture.py`, rechaza explícitamente las tres capturas prematuras y reconoce terreno del bioma guardado en las dos capturas aprobadas. También registra 13.839 píxeles de mapa distintos entre ambos encuadres; esta comparación se acompaña de inspección manual y no se usa como sustituto de comprobar la fecha, las cuatro viviendas y el estado mostrado. Solo se aprueban `final-native/03-final-real-reopened.png` y `visual-ready/02-ready-real-whole-settlement.png` como capturas finales del mapa.

Los procesos apartan los archivos originales y los restauran comprobando todos sus hashes; mantienen sus fixtures en directorios distintos sin sobrescribirlos. La carga lenta del atlas en el emulador y la falta de un indicador visible siguen siendo un pendiente de presentación, no un objetivo de rendimiento aprobado.

Las imágenes PNG son capturas directas de Android API29 por software, sin retoque ni generación conceptual. Los scripts están archivados para inspección; contienen guardas contra sobrescritura y no deben relanzarse sobre directorios ya conservados.

## Pendientes que no cubre este resultado

No demuestra las diez decisiones completas por disponer de un contador, ni todas las ramas narrativas por mostrar tarjetas. Permanecen pendientes territorio/instituciones/conflictos, genealogía y viajes familiares/colonias, economía y seis eras completas, especies jugables diferenciadas, catálogo/director ampliados, historia por bloques, recuperación extendida, arte final y aceptación Android/rendimiento/entrega. Las obligaciones siguen en `../../execution_batches.json` y no cambian de estado por esta documentación.

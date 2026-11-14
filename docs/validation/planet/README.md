# Integración del planeta y seguimiento — 0.17.0+18

Reglas 11 conservadas. Las láminas de `docs/design/` son dirección artística, no evidencia de esta integración. El mundo continuo representa datos existentes; terreno nuevo, trabajos con rutas reales, instituciones completas, especies y eras continúan en M2–M10.

## Evidencia y alcance

| Registro | Qué demuestra | Límites |
|---|---|---|
| `m0-native-retry/results.json` | 0.16 instalado; año autónomo, intervención, avance, cancelación y reapertura exacta al día 630 con objetivo 36.390 | No valida funciones posteriores; primer intento de arranque conservado en `m0-native/` |
| `integration/full/results.json` | 211 pruebas Flutter y compilación aprobadas; validadores estructurales aprobados | Ese análisis tuvo un aviso de importación innecesaria; el registro conserva el fallo |
| `integration/final-quick/results.json` | Análisis limpio y cinco pruebas de cámara/seguimiento tras corregir el aviso y las acciones de exploración | No repite baterías largas ni acredita teléfono físico |
| `integration/guard-tests.log`, `integration/final-analyze.log` | Cinco pruebas focalizadas aprobadas y análisis limpio; protección al intentar seguir desde una ficha desactualizada | La corrección posterior del minimapa solo mueve su rectángulo visual |
| `m1-native-skia/results.json` | Cámara anterior al seguimiento: planeta, región, ciudad y suelo exterior; checkpoint intacto | Binario diagnóstico anterior, renderizador Skia solicitado; rendimiento bajo por software |
| `m1-native-raster/results.json` | Cinco escenas medidas con caché rasterizada; 32 comunidades lejanas, siete edificios/tres personas locales, culling y checkpoint intacto | **Recorrido completo fallido**: la segunda apertura quedó en pantalla blanca antes de cargar la partida. Se conservaron captura y log; originales restaurados exactamente |
| `m1-final-smoke/results.json` | Instalación, selección de Ana, cierre de proceso, nueva apertura y recuperación del mismo protagonista en el paquete final; contraste byte a byte del checkpoint | Prueba corta; los perfiles de región y desplazamiento no se repiten. Revisar su resultado ejecutado, no inferirlo del APK |

El paquete final y sus fuentes exactas están identificados en `integration/artifact-final.json`; firma y alineación en `apk-final-*.log`. El benchmark raster anterior tiene otra identidad en `integration/artifact.json`. Se conservan ambos binarios en `build/deliverables/` sin publicar.

## Cámara y selección

Las pruebas verifican foco del gesto a través de los niveles de detalle, desplazamiento entre dos ciudades, selección en coordenadas comunes, culling y renderizado de 32 asentamientos válidos. El fixture de carga es explícito: mapa 96, semilla 73, reconstrucción y 32 asentamientos. No es la apertura normal del juego ni recibe ayudas durante la ejecución.

El seguimiento resuelve identidad y nacimiento en el mundo confirmado. Una reubicación cambia el foco a la nueva comunidad; la muerte suspende la cámara y conserva el protagonista para consultar su legado. Explorar pausa el seguimiento y Seguir lo reanuda. El selector, su escritura y su recuperación no conceden autoridad ni consumen azar. Las preferencias `view_0..2` usan una cola independiente de los checkpoints y nunca impiden cargar el mundo si están corruptas.

La reubicación del test de cámara es una proyección preparada para comprobar resolución de identidad y coordenadas. No demuestra un viaje de personaje ejecutado por la simulación; esa integración permanece en M6.

Se revisaron visualmente `m1-native-raster/03-city-in-the-planet.png`, `m1-native-raster/failure.png` y `m1-final-smoke/06-reopened-protagonist.png`: escena local, fallo de inicio y Ana centrada tras reabrir con el minimapa separado de los controles, respectivamente. No constituyen la dirección artística terminada ni prueban actividades que todavía no están modeladas.

## Rendimiento y arranque

API29 x86_64, hardware `ranchu`, emulación por software. La primera ventana planetaria pasó de 1,14 FPS en el diagnóstico sin imágenes cacheadas a 10,45 FPS en el benchmark raster. Región: 14,31 FPS; ciudad: 12,62 FPS. Son ventanas locales secuenciales, con posibles diferencias de carga del host, no una comparación controlada ni aceptación de 30 FPS en Android físico. Las muestras PSS no son memoria máxima.

El arranque Vulkan del emulador mostró pantalla blanca; en API29 o anterior, únicamente para hardware `ranchu`/`goldfish`, el lanzador usa Skia si no hay una selección explícita. Los teléfonos mantienen su configuración habitual. También se conservó un fallo posterior de apertura con EGL/Skia; no se atribuye sin evidencia a la cámara, el guardado o Vulkan. Una repetición aprobada no elimina ese fallo registrado.

## Aceptación pendiente

Los tres estados autorizados —Normal, Sin envejecimiento, Inmortalidad total— están registrados en `docs/PLAYER_FOCUS.md`. **No están implementados en el motor.** Requieren versión nueva, edad biológica, cohortes reconciliadas, todas las vías de mortalidad, viajes, persistencia y pruebas. La fauna individual y los equinos también siguen pendientes.

No se reinició la batería larga de reglas 11 por cambios de presentación. Sus treinta semillas llegaron a 200 años; sus dos escenarios de mil años acabaron en extinción antes de la fecha objetivo. `activeMillenniaVerified=false` sigue vigente. Ninguno de estos resultados cierra la aceptación del juego completo.

Las copias textuales de logs normalizan saltos de línea y espacios finales; se conservan mensajes, fallos y valores. Los checkpoints e inventarios se contrastaron por bytes y SHA-256 sin esa normalización.

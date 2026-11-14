# Presentación 0.18.0+19 — evidencia ejecutada

Entrega de prueba solicitada para gráficos, texturas e interfaz. Dirección y compatibilidad: [ATLAS_RELEASE_018](../../design/ATLAS_RELEASE_018.md). Las capturas de `native-*-final/` proceden del APK; las láminas de diseño siguen siendo referencias.

## Código, recursos y compilación

- `integration-results.json`: todos los checks seleccionados aprobaron, incluidas **216 pruebas Flutter**, análisis, requisitos, contenido y compilación.
- `artifact.json`: APK final, SHA-256 y hashes de todos sus archivos de aplicación. Tras la integración se acotó el dibujo del atlas a la región visible, se añadió compatibilidad del renderizador para el emulador API29 y se sincronizó el rótulo de vista al recuperar un protagonista antes del primer layout. Las tres diferencias de código compilado están enumeradas.
- `focused-final.log` y `analyze-final.log`: ocho pruebas focalizadas y análisis limpio tras esas diferencias, incluida la regresión del rótulo. `build-final.log` acredita su nueva compilación.
- `art-reproduction.json`: el generador reprodujo exactamente imágenes, RGBA, manifiesto e iconos. `test/art_assets_test.dart` coteja también el nuevo paisaje PNG/RGBA.
- `legacy-generation-vectors.jsonl`: cuatro hashes canónicos obtenidos ejecutando el código anterior (`2a590bf`); la receta 1 y la carga conservan el mismo resultado. Las nuevas aperturas usan geografía 2 y plano 3.
- `signature-final.log`, `alignment-final.log`, `package-final.log`: firma válida, alineación, versión 19 y API mínima 24. `signature-previous-public.log` confirma el mismo certificado que el APK 0.15 descargado anteriormente desde GitHub.

La nueva geografía se comprobó en 32 combinaciones de tamaño, origen y semilla; ambos orígenes conservan seis emplazamientos viables. Se comprobó equivalencia de un año con catálogo real y guardado, ida/vuelta y rechazo de versión desconocida. El plano compacto conserva las 196 huellas de 2×2 sin solapes.

`scenarios.json` registra aperturas normales, sin órdenes del jugador ni recursos inyectados. Tras un año autónomo se registran construcciones y población reales. El caso prehistórico inicial sirve para capturas; no es una población aumentada artificialmente para parecer una ciudad mayor.

## Android y conservación de datos

API29 x86_64, hardware `ranchu`, sin aceleración KVM. Cada ejecución inventaría los archivos originales, usa un checkpoint declarado, compara sus bytes al observar y al reabrir y restaura todos los originales por SHA-256.

| Registro | Alcance |
|---|---|
| `native-prehistory/results.json` | Candidato anterior: planeta/región/ciudad, culling y checkpoint intacto; **falló al reabrir** antes de cargar el mundo. Captura y log conservados |
| `native-software-diagnostic/results.json` | Mismo candidato con raster por CPU solicitado: instalación, seguimiento y recuperación aprobados; originales restaurados |
| `native-prehistory-final/results.json` | Candidato con compatibilidad de renderizador: mundo nuevo, región, ciudad, desplazamiento, recenter y reapertura aprobados; checkpoint y originales exactos |
| `native-legacy-final/results.json` | Ese candidato recuperó cámara/persona del checkpoint anterior de 32 asentamientos, pero **falló la etiqueta de vista**, que seguía diciendo Planeta. Captura conservada; se corrigió con notificación tras layout |
| `native-legacy-release/results.json` | Paquete publicado cargando el checkpoint anterior de 32 asentamientos: seguimiento, etiqueta correcta y reapertura; contrasta compatibilidad y datos, no estabilidad secular |
| `native-prehistory-release/results.json` | Paquete publicado con apertura nueva y protagonista recuperado; checkpoint y originales exactos |

El cambio de compatibilidad afecta exclusivamente al hardware `ranchu`/`goldfish` con API29 o anterior, conservando las selecciones explícitas de diagnóstico. Los teléfonos mantienen su configuración de GPU. También se recorta la imagen planetaria al rectángulo visible al acercarse.

Las comprobaciones finales solicitan **interfaz y recuperación**, sin repetir mediciones de sesenta fotogramas del emulador por CPU. Los registros lo indican con `frameMetricsRequested=false` y `renderedCountsVerified=false`. No se sustituyen esas métricas por valores inventados. Los perfiles anteriores se conservan como diagnóstico; no acreditan 30 FPS, latencia o memoria máxima del teléfono de referencia.

La nueva prueba de capturas tuvo fallos del arnés de I/O asíncrono y una expectativa de nombre incorrecta para el origen prehistórico; se corrigieron antes de la integración completa aprobada. Las capturas Flutter del host usan fuente de prueba y permanecen en `build/`; no forman parte de la galería Android.

## Límites de esta entrega

Esta versión prioriza presentación y mapas nuevos. Mundo 2/checkpoint 4, trabajos y desplazamientos locales, instituciones completas, eras, equinos, fauna individual, modos de vida y catálogo ampliado siguen pendientes en M2–M11. Las baterías largas no se repitieron por esta entrega gráfica. La aceptación de milenios activos y rendimiento físico continúa abierta.

Compilación, instalación, recuperación y descarga pública se documentan por separado. La publicación usa únicamente el APK final; el candidato con fallo de GPU queda como diagnóstico local. Las copias textuales de logs normalizan espacios finales y saltos de línea; los checkpoints se compararon por bytes sin esa normalización.

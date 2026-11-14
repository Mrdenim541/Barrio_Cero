# Presentación 0.18 y alcance de las referencias

La petición vigente prioriza gráficos, texturas e interfaz y autoriza entregar el APK de prueba en GitHub. Se mantiene la dirección WorldBox/RimWorld/BitLife del plan: observación autónoma, actividades con consecuencias y decisiones contextuales. Las láminas aprobadas guían composición y paleta; las capturas de aceptación proceden del APK.

| Objetivo visual | Integración 0.18 | Alcance restante |
|---|---|---|
| Planeta coherente, costas y biomas | Geografía 2 para nuevos mundos; océano, litoral y relieve derivados de las celdas guardadas | Fronteras políticas, navegación marítima y ecología histórica completas |
| Pixel art de asentamientos | 25 construcciones existentes redibujadas; bosque, rocas, juncos, flores, ruinas y 24 suelos | Variantes completas de eras/especies y todos los estados de daño/actividad |
| Interfaz del atlas | Marcos verde/dorado, fuentes legibles, vista contextual, Seguir · Mundo · Historia; nombres de edificios por selección | Revisión integral de las diez decisiones y todas las pantallas finales |
| Ciudad legible al acercarse | Plano local 3 para aperturas nuevas, encuadre más cercano y claros en parcelas existentes | Rutas locales y asignaciones personales reales de M3/M6 |

## Compatibilidad

La geografía y el plano son versiones de generación, no un cambio de reglas diarias. Mundo continúa en esquema 1, checkpoint 3 y reglas 11. Se guarda `geographyVersion: 2` en mundos nuevos y `siteLayout: 3` en sus asentamientos. La carga lee las celdas y coordenadas existentes; nunca vuelve a generar un mapa guardado. La ausencia del marcador geográfico sigue significando receta 1.

La receta anterior conserva cuatro hashes canónicos obtenidos ejecutando el código de 0.17 (`2a590bf`). Se prueba ida y vuelta de ambas versiones, rechazo de versiones desconocidas, 32 aperturas de continentes entre tamaños/orígenes y equivalencia de un año con guardado. El plano nuevo conserva 196 huellas de 2×2 sin solapes; los planos 1/2 no se recolocan. Las colonias heredan el plano de su origen.

Esto adelanta la geografía de M2, pero no cierra mundo 2, checkpoint 4, archivo histórico o migración integral. Los 174 requisitos originales y ampliados continúan registrados.

## Recursos y presentación

`tool/pixel_landscape.py` contiene geometría, capas, colores y semilla del arte original. `tool/generate_art.py` produce PNG, RGBA premultiplicado, manifiestos e iconos Android. Los identificadores de edificios, personajes y actividades conservan su significado. La prueba de recursos comprueba PNG/RGBA también para el nuevo atlas de paisaje.

Los árboles representan vegetación del bioma y los claros decoran edificios existentes. Las ruinas del terreno requieren su marca confirmada. El dibujo no concede materiales, añade habitantes o decide trabajos. Las ilustraciones de eras futuras siguen siendo dirección artística; los personajes y acontecimientos realmente disponibles provienen de la simulación.

La validación ejecutada y sus límites están en [docs/validation/atlas](../validation/atlas/README.md). La medición de un emulador por software no cierra rendimiento de Android 10+/4 GB. Eras completas, especies alternativas, modos de vida e instituciones/narrativa ampliadas continúan en sus hitos.

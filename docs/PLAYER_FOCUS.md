# Protagonista y seguimiento — ampliación del usuario

El usuario aprueba las láminas visuales del planeta y las eras como objetivo y cambia el acceso Barrio por **Seguir**. La navegación vigente será Seguir · Mundo · Historia. Los archivos de imagen conservan su composición de referencia; el rótulo Barrio se sustituye al implementarlos.

## Selección y autonomía

El jugador puede designar un individuo como protagonista y observar su vida. Seguirlo centra la cámara en su posición confirmada y mantiene su identidad al viajar, cambiar de comunidad, cultura o gobierno. No transfiere autoridad, recursos ni decisiones al jugador. Arrastrar o explorar el mapa suspende la cámara de seguimiento; el protagonista designado se conserva y Seguir vuelve a localizarlo.

El selector admitirá personas e individuos animales realmente existentes. Los miembros inteligentes de una civilización no humana y los animales comunes tienen capacidades diferentes: seguir un caballo común no lo convierte en una sociedad inteligente. Las especies inteligentes alternativas conservan sus premisas y diferencias materiales; la condición humana no es requisito para ser protagonista.

La primera integración 0.17 usa personas destacadas ya modeladas; elección, pausa de cámara y reapertura están comprobadas en [la evidencia M1](validation/planet/README.md). La fauna y los individuos no humanos se habilitan al existir su población, identidad y posición en M8. No se dibujan animales decorativos como si fueran individuos simulados.

La selección de cámara se guarda como preferencia de presentación, vinculada a la partida e identidad. No consume azar ni cambia el estado del mundo. Si el protagonista fallece, se muestra su legado y se puede elegir sucesor; no se reemplaza silenciosamente ni se conserva un muerto realizando actividades.

## Estados de vida solicitados

El usuario confirma que ambas alternativas deben poder activarse. El selector tendrá **Normal**, **Sin envejecimiento** e **Inmortalidad total**, un estado activo por individuo, modificable durante la partida.

- Normal: aplica las reglas de su especie y estado.
- Sin envejecimiento: conserva edad biológica al activarlo; puede sufrir enfermedad, privación, heridas y muerte. La edad cronológica y su historia continúan.
- Inmortalidad total: no muere por envejecimiento, enfermedad, violencia, privación o catástrofe. Conserva necesidades y consecuencias; no obtiene recursos, vivienda, autoridad ni capacidades gratis. Puede quedar debilitado, desplazado, aislado o cautivo según los sistemas existentes.

Al desactivar un estado se retoma el envejecimiento biológico desde la edad conservada, sin reescribir nacimiento ni comprimir de golpe los años transcurridos. Las acciones quedan registradas y persistidas como cambios explícitos del mundo; no son ajustes visuales ni preferencias del dispositivo. Un inmortal superviviente impide declarar extinción global mientras siga existiendo población capaz de actuar; supervivencia e incapacidad deben distinguirse.

Estas son intervenciones extraordinarias opcionales autorizadas por esta ampliación. El modo normal conserva mortalidad y no se introducen rescates automáticos. Las pruebas ordinarias y de extinción no las activan en secreto.

## Dependencias y aceptación

- M1: cámara preparada para seguir una identidad, selector y sustitución del acceso Barrio. La primera implementación solo ofrece individuos reales disponibles.
- M2/M6: modo de vida en el esquema nuevo, conservación de nacimiento/edad biológica, protección coherente en cohortes, viajes y todas las causas de mortalidad. Copia y migración sin alterar partidas antiguas al leerlas.
- M8: edades, necesidades y seguimiento de fauna/especies alternativas por sus definiciones.
- M11: avance secular y recuperación para cada modo; población reconciliada, desactivación correcta, mortalidad normal intacta y ausencia de inmortalidad accidental.

No se habilitarán controles de inmortalidad que solo guarden una marca sin ejecutar estas reglas. Hasta integrar y comprobar sus efectos, los estados de vida son requisitos pendientes.

### Puntos de integración comprobados en el código

- `PopulationLedger.advanceTo` programa el fin de cohortes a los 120 años; `_populationDay` aplica esas bajas. Congelar solo la edad mostrada no impediría la muerte del protagonista.
- `PopulationLedger.killCohort/remove` selecciona personas incluidas en los grupos. El modo necesita pertenencia reconciliada y una edad biológica propia, sin añadir habitantes ni cambiar el nacimiento histórico.
- `_populationYear` calcula mortalidad natural; `_removePeople` también recibe privación, conflictos y efectos narrativos. Todas esas vías deben respetar el mismo estado de vida y registrar bajas efectivas.
- `MigrationJourney.consumeDay` contabiliza muertes antes de resolver el grupo. Al introducir personas protegidas en tránsito, la propuesta de pérdida y su confirmación deben separarse para mantener el mismo número de supervivientes en viaje y población.
- Los textos de algunos efectos todavía contienen cifras de bajas fijas. Deben usar resultados reales; un inmortal superviviente no puede acompañarse de una noticia que lo dé por muerto.

La actualización se incorporará con reglas y esquema nuevos, copia explícita y ejecución antigua preservada. No se cambia el PRNG o la mortalidad de las partidas de reglas 11 como efecto de activar la cámara.

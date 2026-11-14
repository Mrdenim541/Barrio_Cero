# Núcleo de simulación

`lib/simulation/engine.dart` usa únicamente Dart. Unidad: un día; mes de 30 días y año de 360. No existe avance por reloj real ni por render. `WorldState.generate(seed:42,size:96)` genera seis sociedades y terreno persistente. El tamaño pequeño es 64.

La presentación utiliza `Simulation(world).submit(Command(id:..., action:..., actorId:..., issuedDay:..., target:..., choice:...))`. Una orden rechazada conserva el estado; una orden aceptada registra su recibo. Repetir el mismo identificador y carga devuelve el recibo sin repetir efectos; reutilizarlo con otra carga se rechaza. El actor debe coincidir con la comunidad controlada y la fecha con el día actual. `resolve_event` usa `target` como evento y `choice` como opción. Estos contratos tienen pruebas ejecutadas en la suite Flutter; véase docs/validation/h1/flutter-tests.log.

La API anterior `Simulation(world).command(action, societyId:..., target:..., choice:...)` devuelve `CommandResult(ok,message)`. Acciones: `build` (id edificio), `research` (id tecnología), `explore`, `facility` (choice: seal/salvage/study/share), `trade` y `diplomacy` (id sociedad), `control` (id sociedad), `delegate`, `repair`, `policy` (balanced/food/science/trade/defense/expansion/isolation). La presentación debe exigir asumir control antes de enviar órdenes a una sociedad ajena; el motor permite societyId explícito para IA y herramientas de prueba.

`advanceDays(count, stopOnCrisis:false, delegateDecisions:false)` ejecuta exactamente los mismos ticks diarios en cualquier tamaño de lote y devuelve días realmente procesados. La delegación explícita activa decisiones de gobierno en la comunidad dirigida. El modo de crisis interrumpe ante hambre, salud crítica, instalación sin respuesta o consecuencias que requieren elección. La cancelación del trabajador externo conserva todos los ticks ya confirmados.

`toJson` / `WorldState.fromJson` conservan semilla, estado PRNG, fecha, políticas, recursos, grupos y fracciones demográficas, identidades, proyectos, posiciones locales, crónica, rutas, cola y recuerdos de contenido. `validate` rechaza referencias, material, terreno y coordenadas incoherentes. `lib/persistence/checkpoint.dart` define el checkpoint autocontenido y sus hashes; almacenamiento atómico y worker siguen integrados mediante la capa de sesión/presentación.

Cada sociedad tiene `sites`: edificios completados con identificador y posición entera en cuadrícula local 32×32. `built` es el agregado de esos sitios. Las obras pagadas y reservadas no aparecen completadas hasta su fecha. Modificadores de daño alteran capacidad y defensa; `repair` paga recursos y repara daño territorial/vivienda/defensa. Las rutas usan BFS sobre celdas terrestres; una caravana contiene alimentos retirados de origen. Los intercambios transfieren carga y metal existente.

## Contenido

Registrar JSON ya validado mediante `registerContent(pack)` en cada instancia, incluido el trabajador. `eligibleEvents(societyId)` expone acontecimientos y plantillas compatibles, incluyendo decisiones aplazadas. `resolveContentEvent(eventId,optionId,societyId:...)` valida condiciones y costes antes de efectos/cola. `pendingContentEvents` facilita fichas para la comunidad dirigida. Opciones delegadas consideran asequibilidad, reservas y riesgo; sus elecciones quedan en la crónica. Familias extraordinarias desactivadas no se ejecutan ni al resolver una rama pendiente.

Operaciones permitidas: recurso, población, salud, moral, ambiente, vivienda, defensa, relación, bandera, tecnología y programación. Las 16 plantillas calculan parámetros de semilla/fecha sin consumir azar por abrir pantallas. Sus costes y resultados son valores concretos. Las probabilidades base y condicionales intervienen en el director autónomo. En UI el jugador puede inspeccionar y resolver los eventos compatibles.

Los doce rasgos modifican reglas: prudencia/audacia (riesgo); generosidad (carga); reserva/conciliación (diplomacia); inventiva/tradición (conocimiento); paciencia (reservas); inquietud (umbral de expansión); severidad (defensa); custodia (ambiente); pragmatismo (producción). En reglas 4 o posteriores las capacidades y recetas proceden del catálogo declarativo fijado al mundo. Se eliminó el factor genérico por número de tecnologías; los ejecutores antiguos conservan sus tablas y reglas originales. La diferenciación completa de 48 tecnologías y seis eras sigue pendiente.

## Comprobaciones ejecutadas y límites

`dart tool/simulation_check.dart`: la ejecución original aprobó los primeros ocho grupos, incluida equivalencia de cien años con catálogo real y 50.518 acontecimientos, órdenes, instalación, sucesión, treinta semillas ×200 años y rechazo de guardados corruptos. Los objetivos de mil años terminaron por extinción en el día 215.910; no acreditan mil años activos.

La ejecución falló después por un contador obsoleto que exigía 300 opciones cuando el inventario contiene 292. El runner corregido compara identificadores exactos; las 292 opciones y el grupo de plantillas/sitios/reparación aprobaron en repeticiones separadas. `--filter=<texto>` permite esas ejecuciones focalizadas, las marca parciales y rechaza selecciones vacías. Los fixtures no sustituyen recorrer cada arco desde su inicio. Logs y resultados: `docs/validation/h1/`.

`dart tool/benchmark.dart`: se midieron mapas 64/96 con 32 asentamientos iniciales durante cien años. No mantuvieron 32 vivos; aceptación fallida. El runner ahora devuelve error ante esa condición. Los tiempos y RSS de Linux no acreditan FPS, latencia ni memoria del teléfono Android de referencia. Resultados: `docs/validation/h0/benchmark-initial.json`.

## Límites del modelo

En reglas 6 la población se registra por grupos con fecha de nacimiento, cultura y residencia, con personajes como miembros de esos mismos grupos. Las bajas, sucesión y transferencias se reconcilian; las edades comunes iniciales se marcan estimadas. Las reglas antiguas conservan su demografía agregada. Familias, parentescos y tránsito material de migrantes siguen pendientes. El mapa no tiene propiedad política por celda ni simulación hidrológica. Las sociedades conservan cultura y memoria, pero no hay modelo general de constituciones, ocupación o secesión. Producción usa rendimiento territorial sin agotar toda reserva natural. Noticias rutinarias se limitan conservando causas referenciadas; instantáneas anuales son resúmenes, no estados rebobinables. Importar paquetes y migraciones debe respetar la capa de validación y el conjunto exacto de contenido guardado por la presentación.


## Reglas 6: población y aprendizaje

`WorldState.populationState` es la autoridad de recuento; `Society.children/adults/elders` son proyecciones comprobadas. `WorldState.validate()` rechaza discrepancias, personas sin grupo o un archivo de bajas incompatible. No se debe ajustar una proyección a mano para implementar una acción. `tool/fixtures.dart` solo reconstruye escenarios de prueba editados explícitamente; nunca se usa para reparar partidas de producción.

`train` usa `target: resident` para destacar un residente existente o un ID de persona para continuar su aprendizaje; `choice` es `craft`, `technical` o `scout`. `cancel_train` recibe el ID del aprendizaje. La consulta y la confirmación pasan por la misma transacción aislada que las obras. El trabajo reserva maestro y aprendiz antes de construcción y producción, después de rutas y expediciones. La cancelación usa el mismo cálculo de devolución proporcional de `WorkOrder` y se registra una sola vez.

El gobierno puede quedarse sin dirección si no hay adultos elegibles: no se crea un adulto de edad inventada. Las órdenes nuevas se rechazan hasta que exista dirección adulta; la repetición de un recibo confirmado sigue devolviendo su resultado sin efectos. La migración cambia residencia manteniendo las personas y las culturas; su representación en tránsito aún no está implementada.

La conversión mediante `Checkpoint.upgradeRules` no modifica el original: conserva contenido exacto, PRNG, identidades y cumpleaños conocidos; registra la estimación de edades comunes y los restos demográficos anteriores. El repositorio conserva una copia por SHA-256 antes de confirmar. La documentación de comportamiento y límites está en `docs/validation/population/README.md`.


## Reglas 7: vínculos y hogares

`WorldState.socialState` contiene vínculos personales, peticiones, hogares, tutelas y recuerdos. Los participantes se consultan desde las identidades poblacionales, sin crear una segunda población. El contacto se procesa mensualmente y no depende del render o de consultar una ficha. Las partidas de reglas 6 siguen ejecutándose con esas reglas hasta una conversión explícita. Convertir a 7 crea un registro personal vacío, sin inventar familias anteriores, y conserva sus grupos y habilidades.

`home` recibe el ID de petición en `target` y `support` o `decline` en `choice`. Solo opera sobre una petición vigente de la comunidad controlada. Apoyar consume 4 maderas y 6 alimentos; la relación romántica no se establece por orden del jugador. `foster` recibe el ID del adulto que asume el cuidado; destaca a un menor existente y documenta tutela, sin atribuir parentesco biológico. Consume 2 alimentos y 1 agua. Las identidades, cumpleaños y población total se conservan.

Las residencias históricas se mantienen tras muerte o traslado. La validación permite haber fundado un hogar antes de morir durante el mismo día; un fallecido no puede confirmar una orden nueva. Peticiones aceptadas sin hogar, participantes duplicados, secuencias reutilizadas o romances sin acuerdo de adultos se rechazan. Las instituciones políticas, genealogía biológica e herencias materiales todavía requieren implementación; no se deducen de estos registros.


## Reglas 8: plan productivo

`planProduction` es una consulta pura con capacidades productivas, inventarios enteros y presupuesto laboral. `DailyProduction` comprueba balance de insumos, producción, pérdidas y cierre, además de que no se gasten jornadas duplicadas. Viviendas sin rendimiento no participan en el reparto. El motor confirma el plan y registra el consumo alimentario en `Society.lastProduction`; ese registro describe la fase local y no pretende reemplazar el libro completo de transferencias del mundo.

Las reglas 1–7 conservan su ejecutor. Actualizar no inventa trabajo histórico: el primer informe aparece al avanzar el día siguiente. La apertura y los costes siguen procediendo del contenido exacto fijado al mundo. El problema migratorio de selección del primer origen se mantiene identificado en la evidencia de 0.9 y no se considera resuelto por cambiar la producción.

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

Los doce rasgos modifican reglas: prudencia/audacia (riesgo); generosidad (carga); reserva/conciliación (diplomacia); inventiva/tradición (conocimiento); paciencia (reservas); inquietud (umbral de expansión); severidad (defensa); custodia (ambiente); pragmatismo (producción). Todas las tecnologías aportan 1% de productividad institucional y algunas añaden sus efectos específicos y desbloqueos. No existen treinta subsistemas científicos independientes.

## Comprobaciones ejecutadas y límites

`dart tool/simulation_check.dart`: la ejecución original aprobó los primeros ocho grupos, incluida equivalencia de cien años con catálogo real y 50.518 acontecimientos, órdenes, instalación, sucesión, treinta semillas ×200 años y rechazo de guardados corruptos. Los objetivos de mil años terminaron por extinción en el día 215.910; no acreditan mil años activos.

La ejecución falló después por un contador obsoleto que exigía 300 opciones cuando el inventario contiene 292. El runner corregido compara identificadores exactos; las 292 opciones y el grupo de plantillas/sitios/reparación aprobaron en repeticiones separadas. `--filter=<texto>` permite esas ejecuciones focalizadas, las marca parciales y rechaza selecciones vacías. Los fixtures no sustituyen recorrer cada arco desde su inicio. Logs y resultados: `docs/validation/h1/`.

`dart tool/benchmark.dart`: se midieron mapas 64/96 con 32 asentamientos iniciales durante cien años. No mantuvieron 32 vivos; aceptación fallida. El runner ahora devuelve error ante esa condición. Los tiempos y RSS de Linux no acreditan FPS, latencia ni memoria del teléfono Android de referencia. Resultados: `docs/validation/h0/benchmark-initial.json`.

## Límites del modelo

Demografía agregada con fracciones, no cohortes anuales exactas. Identidades destacadas no se reconcilian completamente con cada baja común. El mapa no tiene propiedad política por celda ni simulación hidrológica. Las sociedades conservan cultura y memoria, pero no hay modelo general de constituciones, ocupación o secesión. Producción usa rendimiento territorial sin agotar toda reserva natural. Noticias rutinarias se limitan conservando causas referenciadas; instantáneas anuales son resúmenes, no estados rebobinables. Importar paquetes y migraciones debe respetar la capa de validación y el conjunto exacto de contenido guardado por la presentación.

# Núcleo de simulación

`lib/simulation/engine.dart` usa únicamente Dart. Unidad: un día; mes de 30 días y año de 360. No existe avance por reloj real ni por render. `WorldState.generate(seed:42,size:96)` genera seis sociedades y terreno persistente. El tamaño pequeño es 64.

`Simulation(world).command(action, societyId:..., target:..., choice:...)` devuelve `CommandResult(ok,message)`. Acciones: `build` (id edificio), `research` (id tecnología), `explore`, `facility` (choice: seal/salvage/study/share), `trade` y `diplomacy` (id sociedad), `control` (id sociedad), `delegate`, `repair`, `policy` (food/science/trade/defense/expansion/isolation). La presentación debe exigir asumir control antes de enviar órdenes a una sociedad ajena; el motor permite societyId explícito para IA y herramientas de prueba.

`advanceDays(count, stopOnCrisis:false, delegateDecisions:false)` ejecuta exactamente los mismos ticks diarios en cualquier tamaño de lote y devuelve días realmente procesados. La delegación explícita activa decisiones de gobierno en la comunidad dirigida. El modo de crisis interrumpe ante hambre, salud crítica, instalación sin respuesta o consecuencias que requieren elección. La cancelación del trabajador externo conserva todos los ticks ya confirmados.

`toJson` / `WorldState.fromJson` conservan semilla, estado PRNG, fecha, políticas, recursos, grupos y fracciones demográficas, identidades, proyectos, posiciones locales, crónica, rutas, cola y recuerdos de contenido. `validate` rechaza referencias, material, terreno y coordenadas incoherentes. El almacenamiento atómico, hashes, copias y worker pertenecen a la capa de presentación.

Cada sociedad tiene `sites`: edificios completados con identificador y posición entera en cuadrícula local 32×32. `built` es el agregado de esos sitios. Las obras pagadas y reservadas no aparecen completadas hasta su fecha. Modificadores de daño alteran capacidad y defensa; `repair` paga recursos y repara daño territorial/vivienda/defensa. Las rutas usan BFS sobre celdas terrestres; una caravana contiene alimentos retirados de origen. Los intercambios transfieren carga y metal existente.

## Contenido

Registrar JSON ya validado mediante `registerContent(pack)` en cada instancia, incluido el trabajador. `eligibleEvents(societyId)` expone acontecimientos y plantillas compatibles, incluyendo decisiones aplazadas. `resolveContentEvent(eventId,optionId,societyId:...)` valida condiciones y costes antes de efectos/cola. `pendingContentEvents` facilita fichas para la comunidad dirigida. Opciones delegadas consideran asequibilidad, reservas y riesgo; sus elecciones quedan en la crónica. Familias extraordinarias desactivadas no se ejecutan ni al resolver una rama pendiente.

Operaciones permitidas: recurso, población, salud, moral, ambiente, vivienda, defensa, relación, bandera, tecnología y programación. Las 16 plantillas calculan parámetros de semilla/fecha sin consumir azar por abrir pantallas. Sus costes y resultados son valores concretos. Las probabilidades base y condicionales intervienen en el director autónomo. En UI el jugador puede inspeccionar y resolver los eventos compatibles.

Los doce rasgos modifican reglas: prudencia/audacia (riesgo); generosidad (carga); reserva/conciliación (diplomacia); inventiva/tradición (conocimiento); paciencia (reservas); inquietud (umbral de expansión); severidad (defensa); custodia (ambiente); pragmatismo (producción). Todas las tecnologías aportan 1% de productividad institucional y algunas añaden sus efectos específicos y desbloqueos. No existen treinta subsistemas científicos independientes.

## Comprobaciones pendientes de ejecución

`dart tool/simulation_check.dart`: equivalencia de cien años con lotes y guardado; gasto/obras; tres rutas de instalación y señal histórica; sucesión/extinción; treinta semillas ×200 años y mil años; corrupción; todas las opciones del catálogo real; instancias procedurales, sitios y reparación.

`dart tool/benchmark.dart`: mapas 64/96, 32 asentamientos iniciales, cien años con catálogo, tiempo y RSS del proceso. No mide FPS ni sustituye pruebas Android. Estos scripts están escritos; consultar STATUS y resultados antes de afirmar ejecución.

## Límites del modelo

Demografía agregada con fracciones, no cohortes anuales exactas. Identidades destacadas no se reconcilian completamente con cada baja común. El mapa no tiene propiedad política por celda ni simulación hidrológica. Las sociedades conservan cultura y memoria, pero no hay modelo general de constituciones, ocupación o secesión. Producción usa rendimiento territorial sin agotar toda reserva natural. Noticias rutinarias se limitan conservando causas referenciadas; instantáneas anuales son resúmenes, no estados rebobinables. Importar paquetes y migraciones debe respetar la capa de validación y el conjunto exacto de contenido guardado por la presentación.

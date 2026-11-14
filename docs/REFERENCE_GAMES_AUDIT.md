# Referencias para el planeta autónomo

## Alcance y evidencia

Revisión ampliada por petición del usuario tras probar 0.15: el mapa se siente pequeño, la evolución resulta poco visible y los saltos históricos son lentos. Este catálogo reúne 34 juegos relacionados; no pretende enumerar todos los juegos existentes ni afirmar que se ejecutaron todos.

Estados de revisión: **F** = fuentes concretas inspeccionadas; **P** = paquete oficial inventariado con REA; **M** = repositorio y metadatos comprobados, mecánicas pendientes de inspección; **D** = candidato de diseño, sin ejecución ni inspección directa en esta revisión. Una referencia de diseño no es evidencia de funcionamiento de BARRIO CERO.

Las versiones, commits, licencias detectadas, hashes y conclusiones concretas están en [la evidencia de referencias](validation/references/). Se analizaron fuentes de cinco proyectos: Mindustry, Unciv, Widelands, Freeciv y OpenTTD. Los juegos comerciales de referencia no están instalados en este entorno; no se ha decompilado WorldBox, RimWorld ni BitLife.

## Catálogo completo de esta revisión

| Juego | Aporte al diseño | Aplicación y límite | Revisión |
|---|---|---|---|
| WorldBox | Observación, sociedades autónomas, intervención sobre un mundo | Referencia principal del ciclo. El planeta debe funcionar sin órdenes del jugador; las intervenciones de BARRIO conservan sus costes acordados. | D |
| Galimulator | Observar expansión, relaciones y caída de imperios | Lectura de fronteras y cambios históricos a distancia; evitar trasladar su abstracción espacial a la vida cotidiana. | D |
| The Universim | Relación entre planeta, asentamientos y desarrollo histórico | Escalas conectadas y cambios de capacidades; una cámara planetaria no demuestra simulación territorial. | D |
| Spore | Especies y fases de desarrollo | Identidad biológica y cambios de escala; evitar presentar fases lineales o evolución dirigida como biología real. | D |
| RimWorld | Necesidades, trabajos, personajes y consecuencias | Referencia de vida local. Los habitantes eligen trabajos y mantienen relaciones; no trasladar el volumen de paneles de escritorio. | D |
| Dwarf Fortress | Historia, parentesco y continuidad del mundo | Hechos persistentes vinculados a personas y lugares; evitar exigir conocer centenares de reglas para observar. | D |
| Songs of Syx | Poblaciones amplias, ciudades y especies | Agregación de población y diferencias materiales; no procesar cada habitante como personaje destacado. | D |
| Clanfolk | Familias y vida durante generaciones | Hogares, aprendizaje y continuidad familiar; el jugador no asigna cada necesidad individual. | D |
| Norland | Familias dirigentes, relaciones y política | Distinguir parentesco de institución y legitimidad; evitar reducir toda la población a dirigentes. | D |
| BitLife | Acontecimientos personales breves y elecciones | Tarjetas con participantes reales y consecuencias materiales; no convertir el mundo en una secuencia obligatoria de ventanas. | D |
| Reigns | Elecciones fáciles de comprender | Pocas alternativas legibles; evitar decisiones binarias arbitrarias desconectadas del mundo. | D |
| King of Dragon Pass | Decisiones colectivas, tradiciones y memoria | Consecuencias diferidas y distintas voces del consejo; mantener acceso visual al territorio. | D |
| Six Ages | Narrativa social y continuidad cultural | Arcos condicionados por historia y recursos; no usar resultados prefabricados como sustituto de mecanismos. | D |
| Dawn of Man | Subsistencia y transición prehistórica | Alimentos, almacenamiento, herramientas y conocimientos sostenidos; no investigar sin trabajo e infraestructura. | D |
| Sapiens | Personas y actividades de una comunidad inicial | Leer tareas y necesidades en el espacio; evitar micromanejo obligatorio. | D |
| Civilization VI | Tecnología, ciudades y capacidad histórica | Costes y desbloqueos comprensibles; no imponer turnos ni una única secuencia universal de eras. | D |
| Humankind | Cultura e identidad histórica | Separar identidad cultural y sociedad política; las transformaciones necesitan causas. | D |
| Crusader Kings III | Dinastías, herencia y sucesión | Gobierno y patrimonio personal separados; reducir complejidad de presentación para móvil. | D |
| Stellaris | Contacto, diplomacia y variedad extraterrestre | Visita, cooperación e infiltración además de guerra; expediciones con suministros y actores reales. | D |
| Frostpunk | Crisis materiales y decisiones institucionales | Costes y responsabilidad política verificables; no requerir crisis extremas constantes. | D |
| Against the Storm | Adaptación al ambiente y prioridades | Objetivos contextuales y alternativas; conservar el mundo persistente en lugar de reiniciarlo por estructura de partida. | D |
| Oxygen Not Included | Recursos y fallos de infraestructura | Cadenas materiales explicables; no trasladar simulación física detallada a todo el planeta. | D |
| Niche | Diferencias biológicas y herencia | Alimentación, movilidad y reproducción cambian estrategias; no crear una escala universal de especies superiores. | D |
| Species: Artificial Life, Real Evolution | Ecología y adaptación | Relación organismo–ambiente; separar evolución biológica de tecnología y cultura. | D |
| Mindustry | Cámara, bloques visibles, simulación y transporte | Patrones de representación y actualización. Fábricas y defensa no pasan a ser el objetivo de BARRIO. | F + P |
| Unciv | Automatización civilizatoria, ciudades, diplomacia y tecnología | Políticas autónomas por responsabilidades; adaptar el concepto a tiempo continuo sin adoptar sus turnos. | F |
| Widelands | Actividades programadas y economía logística | Separar cola de simulación, dibujo y guardado; no copiar su sistema completo de rutas sin evaluar el coste. | F |
| Freeciv | Jugador político, ciudades y nacionalidad | Una sociedad puede tener varias ciudades; la identidad de habitantes no equivale a propietario político. | F |
| FreeCol | Colonias, trabajos y transporte | Candidato para provisiones, producción y asentamientos conectados; sus mecánicas no se han inspeccionado en esta revisión. | M |
| OpenTTD | Transporte y bucle de simulación duradero | Separar ticks y representación, medir subsistemas. No incorporar su escala de gestión de transportes como obligación. | F |
| Thrive | Organismos y capacidades biológicas | Candidato abierto para especie/entorno. No se presupone una civilización completa disponible ni se importa su simulación 3D. | M |
| Cataclysm: Dark Days Ahead | Estado de personajes y consecuencias persistentes | Candidato para necesidades y lesiones; su estructura por turnos y protagonismo individual no son el ciclo principal. | M |
| Cataclysm: Bright Nights | Variante centrada en accesibilidad y sistemas | Comparación de simplificación, pendiente de inspección mecánica directa. | M |
| FreeOrion | Sociedades, investigación, especies y política espacial | Candidato para contacto y capacidades diferentes; no asumir que sus reglas encajan en un planeta histórico. | M |

## Jerarquía para evitar una mezcla confusa

1. **WorldBox define el ciclo:** observar un mundo autónomo e intervenir de forma opcional.
2. **RimWorld define la profundidad local:** necesidades, trabajos y vínculos reconocibles.
3. **BitLife define el canal personal:** acontecimientos breves y decisiones significativas.
4. Mindustry, Unciv, Widelands, Freeciv y OpenTTD aportan patrones técnicos concretos. Las demás referencias resuelven preguntas acotadas; no añaden automáticamente nuevas pantallas o sistemas al alcance.

No se adopta ningún juego entero como base por semejanza visual. Mindustry y Unciv ya tienen simulaciones maduras, pero sus objetivos y reglas difieren del planeta histórico autónomo. Godot, disponible en este entorno, sigue siendo candidato para una prueba de representación continua; no se ha decidido ni ejecutado una migración completa de Flutter.

## Hallazgos derivados de fuentes

- **Mindustry:** `Renderer.update` calcula la cámara y actualiza el nivel de detalle; `FloorRenderer` prepara cachés por bloques y recorre los visibles. `Logic.update` tiene un bucle diferente del renderizador. Aplicación: cámara común, regiones de dibujo y contenido visible por escala; no aumentar únicamente el límite del zoom actual.
- **Unciv:** `GameInfo.nextTurn` acepta una barra opcional y tiene modo de simulación; `NextTurnAutomation.automateCivMoves` separa diplomacia, investigación, unidades y ciudades. `WorldMapHolder` reduce trabajo durante desplazamiento/zoom. Aplicación: ejecución autónoma fuera de la presentación y prioridades por subsistema, conservando restricciones materiales.
- **Widelands:** `Game::think` hace avanzar una cola de órdenes y después consulta al guardado. Aplicación: el límite de cálculo y el punto de persistencia no tienen por qué coincidir con cada paso visible.
- **Freeciv:** `city` contiene propietario político y nacionalidad de habitantes, y los jugadores tienen colecciones de ciudades. Aplicación: separar sociedad, asentamiento y cultura como exige la especificación.
- **OpenTTD:** `StateGameLoop` distingue subsistemas y el bucle de juego está separado de operaciones visuales. Aplicación: medir coste de simulación, serialización, escritura y dibujo por separado.

Son observaciones estáticas de los archivos citados, no benchmarks ni sesiones observadas de esos juegos.

## Primer cambio aplicado al juego

El trabajador de 0.15 confirmaba un mundo completo cada treinta días: un siglo podía requerir 1.200 confirmaciones. Se añade un ejecutor de lotes históricos compartido entre Android y web que acumula hasta 360 días, con presupuesto de cálculo de 200 ms y cesión al bucle de eventos entre bloques de hasta treinta días. Un bloque individual puede superar ese presupuesto: no es una garantía de latencia del dispositivo.

Los días y el PRNG se ejecutan con las mismas reglas. El reloj de pared elige puntos de confirmación, no resultados históricos. Cada lote sigue esperando escritura confirmada; cancelación, crisis, extinción y objetivo pendiente conservan su significado. Una interrupción puede perder más cálculo sin confirmar —hasta un año en lugar de un mes— y lo repetirá desde el checkpoint con su objetivo original. No se sustituye el siglo por una animación ni por una estimación estadística.

Las pruebas y la comparación con archivos temporales acreditan únicamente el alcance publicado en `validation/references/results.json`. Esta mejora reduce trabajo de confirmación; no crea eras, fronteras, trabajos locales ni garantiza por sí sola un siglo instantáneo.

## Código, arte y reutilización

REA es una herramienta MIT, no un motor de juego ni una licencia sobre el contenido que inspecciona. Se instaló por CLI aislado, sin registrar un servidor MCP ni modificar la configuración de agentes. El inventario oficial de Mindustry se conserva con identidad y límites; no se incorporaron sus imágenes, sonidos ni código al APK.

Los repositorios GPL/MPL siguen sus licencias; los metadatos `NOASSERTION` o ausentes necesitan revisión por archivo antes de reutilizar contenido. Godot y sus demos tienen licencia MIT en los metadatos consultados, con revisión de avisos por recurso antes de incorporar uno. En esta entrega se implementan patrones con código original y se conservan los recursos originales de BARRIO.

## Trabajo que sigue abierto

- Probar una cámara continua sobre un mismo territorio, con ciudades situadas en él, detalle por escala y terreno dibujado por bloques visibles.
- Mostrar actividades basadas en tarea, trayecto y destino confirmados; las animaciones no acreditan decisiones autónomas.
- Prioridades políticas diferenciadas, expansión territorial material y varias ciudades por sociedad.
- Recorridos personales con participantes reales, plazos, parentesco y consecuencias, además del catálogo ampliado.
- Medir el salto en Android y conservar cancelación/recuperación; separar sus tiempos de cálculo, comunicación y disco.
- Inspección directa de las referencias comerciales cuando exista una instalación legítima accesible. Su ausencia no bloquea el desarrollo con fuentes abiertas.

Los requisitos originales y ampliados permanecen vigentes. Ninguna fila se cierra por aparecer en este catálogo ni por instalar REA.

# BARRIO CERO: ERAS — ampliación aprobada de jugabilidad y simulación

Versión de alcance 2.0, aprobada el 13 de noviembre de 2026. Este documento conserva y amplía `PROJECT_SPEC.md`; no sustituye sus 106 bloques ni describe funciones ya terminadas. `docs/redesign_requirements.json` registra los criterios adicionales y su estado. La aprobación del plan autoriza implementación local por hitos, no publicación del entorno o en tiendas.

## 1. Visión, referencias y decisiones confirmadas

Guiar un pequeño asentamiento, conocer a sus familias y observar cómo decisiones, entorno y otras sociedades transforman su historia durante generaciones. Ciclo principal: observar necesidad u oportunidad → elegir → reservar recursos y trabajo → avanzar → reconocer consecuencia y causa → volver a decidir.

WorldBox guía la lectura del mundo, autonomía y territorio; RimWorld guía necesidades, trabajos, personajes y consecuencias materiales; BitLife guía acontecimientos personales breves y elecciones comprensibles. Polytopia deja de ser referencia principal de producto; sus patrones de claridad táctil pueden servir como criterio de interfaz. El arte, contenido y código siguen siendo originales.

Decisiones confirmadas por el usuario: prehistoria como inicio predeterminado; reconstrucción después del colapso como segundo escenario completo; familias destacadas con población común agregada; progreso durante varias generaciones y siglos, según capacidades y decisiones. Se conservan Android vertical e individual, funcionamiento offline sin cuentas/servicios obligatorios, mínimo API 24 y teléfono de referencia Android 10+ con 4 GB. Continúan las tres escalas y saltos de 1/10/100 años.

Límite aprobado: relaciones adultas, intimidad mediante elipsis y violencia ficticia con consecuencias visibles. No se incluyen escenas sexuales gráficas o poco censuradas. No se cuenta esa petición anterior como requisito cumplido.

## 2. Cambios de alcance y compatibilidad de experiencia

La reconstrucción ya no es el único origen: permanece seleccionable y es el origen de las partidas actuales. La prehistoria tendrá economía, contenido, infraestructura inicial y arte propios antes de aparecer como opción jugable. Un APK intermedio puede mejorar la experiencia de reconstrucción sin presentarla como prehistoria.

Las seis eras cambian capacidades materiales, institucionales y narrativas. Las especies requieren reglas biológicas y anatómicas, no un cambio de sprite. Las vidas personales incorporan hogares, parentesco, relaciones y memoria. La representación de violencia procede de hechos confirmados. Reorganizar la interfaz no cierra estos sistemas.

No hay victoria única, ascenso histórico obligatorio ni rescate automático ante extinción. Observar, dirigir y delegar son acciones distintas. Cambiar de comunidad no transfiere recursos, compromisos o historia; la anterior conserva sus órdenes y pasa a autonomía.

## 3. Eras operativas

| Era | Capacidades distintivas | Consecuencia mecánica |
|---|---|---|
| Prehistórica | Recolección, herramientas, refugios, transmisión oral y cooperación local | Dependencia directa del entorno y especialización inicial. |
| Antigua | Producción estable, almacenamiento, agua y registros duraderos | Excedentes, ciudades, administración y comercio regular. |
| Medieval | Oficios, instituciones territoriales, fortificaciones y redes regionales | Obligaciones, poder local y competencia territorial. |
| Industrial | Energía mecánica, extracción, fabricación y transporte de volumen | Cadenas productivas, contaminación y dependencia de suministros. |
| Moderna | Electricidad, comunicaciones, medicina y servicios institucionales | Coordinación a distancia e infraestructuras críticas. |
| Futurista | Automatización, biotecnología/cibernética, energía y hábitats especializados | Transformaciones, nuevas dependencias y respuesta planetaria. |

Cada asentamiento tendrá capacidades y etapa operativa propias; una sociedad puede reunir asentamientos diferentes. Investigar no crea infraestructura, combustible o trabajadores. Una capacidad histórica se reconoce después de **180 días de funcionamiento sostenido**. La pérdida de soporte durante **360 días** puede provocar regresión. Conocimiento registrado, especialistas e infraestructura se conservan por separado: conocer una técnica no implica poder mantenerla.

El año no concede una era; ninguna constitución es obligatoria. La reconstrucción puede recuperar capacidades mediante vestigios reales. En prehistoria se desarrollan mediante las cadenas materiales y sociales. El balance busca siglos de juego y no garantiza que todas las sociedades alcancen el futuro.

## 4. Especies y entidades del mundo

Separar `SpeciesDefinition`, `Culture`, `Society`, `Settlement`, `PopulationCohort`, `Person`, `Household`, `Relationship`, `Institution`, `Territory`, `Route` y `Conflict`. Las identidades destacadas pertenecen a cohortes reales y no suman habitantes adicionales. Una migración tiene origen, tránsito y destino.

| Especie inicial | Reglas que deben distinguirla | Coste relativo |
|---|---|---|
| Humanos | Dieta flexible, herramientas manuales y transporte limitado sin infraestructura | Reutilización mayor del arte existente; variantes de eras y nuevas reglas. |
| Equinos sapientes | Linaje ficticio inteligente previo a la partida, cuadrupedia, herbivoría, demanda territorial, trabajo con boca/arneses/bancos de sujeción | Alto: locomoción, siluetas, talleres, transporte, dieta y edificios. |
| Visitantes extraterrestres | Metabolismo, hábitat y suministros definidos; llegada en expediciones finitas | Alto: soporte vital, actores externos, contacto y asentamiento. |

Humanos y equinos pueden ser origen en mundos exclusivos o mixtos. Los visitantes aparecen mediante acontecimientos; una sociedad local que establezcan puede observarse y dirigirse con las mismas reglas. Los equinos tienen rutas tecnológicas independientes de recibir ayuda humana. Su inteligencia es ficción, no una mutación natural improvisada en cien años. La reproducción entre especies no produce híbridos automáticamente.

## 5. Familias, instituciones y memoria

Los hogares y parentescos de familias destacadas persisten. Amistad, afecto, confianza, rivalidad, convivencia, separación y duelo son vínculos diferenciados. Los personajes mantienen objetivos y autonomía: una orden política no garantiza sentimientos o consentimiento. Nacimientos, adopciones, migraciones y muertes actualizan población y relaciones una sola vez.

Sucesión institucional y herencia familiar son mecanismos distintos. Instituciones iniciales: consejo comunitario, organización de clanes, gobierno hereditario, administración cívica y gobierno tecnocrático; ninguna es un paso histórico obligatorio. Promesas, deudas, agravios, desplazamientos y pérdidas pertenecen a entidades persistentes, no al dirigente actual. Procesar personas y familias por fechas y acontecimientos, no por fotograma.

La pérdida de una capital no borra cultura, familias, colonias, refugiados o compromisos. Diferenciar ocupación, destrucción, caída política y extinción global. Guerras y matanzas dejan responsables, participantes, víctimas, incertidumbre conocida, ruinas y memoria.

## 6. Director y objetivos de contenido

El catálogo declarativo será la única autoridad para edificios, tecnologías y acontecimientos. Se elimina su extracción desde Dart; se rechaza cualquier campo admitido cuya semántica no exista. La UI consume instancias concretas, no un catálogo abierto de definiciones elegibles.

Objetivos: conservar 12 recursos, 6 biomas, 6 perfiles, 12 rasgos y Ana/Leo/Tito con ocupaciones compatibles; ampliar a **30 edificios/mejoras y 48 tecnologías funcionalmente diferentes**; conservar/adaptar 96 acontecimientos independientes y añadir **48** (ocho situaciones propias de cada era); conservar doce arcos y añadir cuatro (hogar/vínculos, herencia, convivencia entre especies y reconstrucción tras pérdida de capacidades). Cada arco tendrá 4–7 nodos y dos desenlaces mecánicamente diferentes. Permanecen 16 plantillas y ocho familias extraordinarias; una clasificación no cuenta como evento adicional.

Cada `EventInstance` contiene participantes concretos, lugar, causas, condiciones, vencimiento, opciones y resolución. El texto utiliza esos participantes; no atribuye acciones actuales a Ana, Leo o Tito tras su muerte. Revalidar al vencer: adaptar o cancelar explícitamente cuando una muerte, guerra, destrucción o cambio de estado invalide una rama. Costes y efectos son atómicos, rastreables y con fuentes materiales o extraordinarias explícitas.

Distinguir decisiones, alertas y noticias. Mostrar hasta tres asuntos destacados, manteniendo el resto accesible. La selección espontánea tiene presupuesto y periodos de espera; los efectos comprometidos conservan sus fechas. Un límite causal por tick detiene y diagnostica el día antes de confirmar un estado parcial. Normal/caótica/extrema alteran frecuencia y severidad, no eliminan precondiciones.

Desactivar una familia bloquea nuevas cadenas; las ya comprometidas continúan. La UI informa de esta semántica. No desaparecen invasores, daños o participantes por cambiar la configuración. Conservar las ocho familias originales y escalas local/regional/planetaria, con contacto, intercambio, influencia, infiltración, invasión, resistencia y convivencia; contacto no implica guerra.

## 7. Dos cadenas completas de aceptación

**Una casa entre dos comunidades:** dos adultos con contacto real desarrollan vínculo mutuo → solicitan hogar (vivienda, residencia temporal o rechazo) → una interrupción de ruta los separa (negociar paso, trayecto alternativo o separación) → el viaje consume recursos y tiene llegada/retraso/interrupción reales → el hogar conserva compromisos durante los años y los descendientes nacen por demografía válida → hogar reunido con cooperación, hogares separados con continuidad cultural, o duelo/reclamaciones si ocurre una muerte real. Cambian residencia, población, recursos, confianza y memoria; no se reemplaza un fallecido por un homónimo.

**La instalación y sus herederos:** expedición descubre un sitio (pasado tecnológico en reconstrucción, vestigio precursor ficticio en prehistoria) → sellar/desmontar/estudiar/compartir paga costes distintos → estudio depende de especialistas y capacidades, y produce conocimiento, energía localizada o accidente → aprovecharla exige infraestructura/suministros y puede crear crecimiento/dependencia/tensiones → señal habilitada inicia contacto y respuestas diferentes → cooperación, reconstrucción tras accidente, dependencia política, conflicto con desplazamientos o ruinas. Demostrar tres rutas completas, incluidas consecuencias históricas. Un artefacto avanzado no eleva automáticamente la era de toda la sociedad.

## 8. Interfaz, arte y primera sesión

Navegación estable **Barrio · Mundo · Historia**. Barrio muestra asentamiento, selección contextual, proyectos, habitantes y familias. Mundo reúne región/mundo, rutas, sociedades, territorio y filtros. Historia reúne decisiones pendientes, noticias, genealogía destacada y comparación temporal. Permanecen visibles fecha, comunidad dirigida y controles temporales. Paquetes, archivo y ajustes van al menú.

Iniciar pausado y centrado en el asentamiento. Las acciones muestran resultado esperado, coste, trabajo, duración y motivo de indisponibilidad antes de ordenar. Sustituir volcados de propiedades por fichas legibles; permitir tocar entidades locales reales. La guía se puede omitir y retomar, sin consumir PRNG ni modificar reglas.

Diez decisiones significativas del recorrido guiado: (1) prioridad alimentaria; (2) mejora de agua; (3) mejora/ampliación de refugio; (4) trabajo frente a aprendizaje; (5) destino de exploración; (6) intercambio/acuerdo exterior; (7) petición familiar; (8) respuesta a una consecuencia aplazada; (9) adopción de un conocimiento desbloqueado; (10) prioridades delegadas y salto corto. Abrir paneles o avanzar no cuenta por sí solo como decisión. La prueba registra elección, coste y cambio material: construcción persistente, consecuencia aplazada, interacción exterior y opción nueva. Omitir la guía permite caminos libres sin recursos artificiales.

Mantener pixel art original, siluetas legibles, ocho estados de actividad y variantes anatómicas/por era. Cargar dimensiones/variantes por manifiesto, evitando índices rígidos. Figuras, rutas, trabajos y edificios proceden del modelo. Ajustes independientes de sangre, cuerpos y detalle textual afectan la representación, no víctimas ni resultados. Verificar texto ampliado, contraste, señales además del color y objetivos táctiles de 48 puntos a 320/360/412 puntos lógicos.

## 9. Contratos e integridad

`WorldSnapshot`: estado confirmado, reglas/versiones, entidades, PRNG, compromisos, contenido exacto y cola causal. `preview(Command)`: costes/duración/requisitos/rechazo sin consumir azar o recursos. `submit(Command)`: autoridad, revisión, reservas y recibo idempotente. `advance(AdvanceRequest)`: mismos ticks, fecha alcanzada, decisiones pendientes y motivo de parada. `SessionController`: único propietario de la sesión activa, carga/importación/suspensión/confirmación visual. `CheckpointRepository`: mundo, contenido, objetivo y estado de sesión persistidos conjuntamente.

Conservar Flutter/Flame, núcleo independiente, calendario diario, identificadores aprovechables, atlas originales, checksums y selector Android. Mantener una única cola de escritura y las regresiones de espacios/importación. Separar sesión, trabajador, almacenamiento, consultas y widgets; modularizar mundo, economía, población, política, transporte y narrativa.

Orden diario fijo: órdenes fechadas → trabajos/transporte → economía → población/instituciones cuando corresponda → acontecimientos → cierre. Materiales enteros en milésimas y restos demográficos persistentes. Azar visual separado. La cámara, lotes o paneles no cambian resultados. IA y jugador usan las mismas restricciones materiales.

## 10. Migración e historia extensa

Conservar el ejecutor antiguo para continuar partidas hasta convertirlas explícitamente. Nuevos mundos: esquema 2, contenido 2, checkpoint 3. Convertir cada sociedad antigua en una sociedad y un asentamiento; conservar identidad, ubicación, recursos, crónica, compromisos y tipo/estado PRNG. Registrar cambio de reglas. No inventar parentescos o pasado desconocido.

Conservar copia exacta del original, validar candidato y publicar juntos mundo/destino solo tras confirmar escritura. Rechazar conversiones incompatibles, incluidos personajes irreconciliables con su población, sin destruir la partida antigua. Contenido fijado y bytes exactos se conservan; importar paquetes no actualiza mundos existentes.

Historial en bloques inmutables con hashes y manifiesto confirmado atómicamente. ACK al trabajador después de persistencia; un cierre recupera el último punto confirmado sin duplicar efectos ni avanzar por reloj real. Comparar fronteras/métricas con datos registrados; un resumen no se presenta como mundo rebobinable.

Intercambio ZIP versionado mediante Java nativo y streaming, manteniendo JSON antiguo. Límite: **64 MiB comprimidos, 256 MiB descomprimidos**. Rechazar rutas inseguras, entradas duplicadas o referencias incompletas. Alcanzar un límite produce error, nunca eliminación silenciosa de historia. Fallos de disco, archivo, cancelación o suspensión conservan el último estado válido.

## 11. Aceptación, evidencia y límites

- Determinismo: 36.000 días, diez décadas y un siglo equivalentes, incluyendo catálogo, guía, cámara, ajustes, guardado y lotes distintos.
- Órdenes: insuficiencia, concurrencia, repetición, revisión obsoleta, especialista fallecido, obra destruida y reparación sin efectos parciales.
- Mundo vivo: dos comunidades crecen; ida y retorno comercial; escasez y respuesta; intervención cambia desarrollo, observación no.
- Especies/eras: alimentación, anatomía, edificios y transporte diferentes; cooperación, coexistencia, pérdida y recuperación de capacidades.
- Generaciones: nacimientos, parentescos, adopción, formación, migración y sucesión sin población duplicada o muertos actuando.
- Narrativa: participantes, plazos, exclusiones, cancelaciones, todos los efectos, dos finales por arco y tres rutas de instalación desde sus inicios.
- Extraordinarios: forzar familias solo en herramientas de prueba; mantener probabilidades normales; escalas y extinción sin repoblación automática.
- Persistencia: interrupciones antes/después de confirmar, durante animación/salto, disco lleno, copia dañada, corrupción y paquetes ausentes. Mantener regresiones de autoguardados antiguos y espacios.
- Estabilidad: 30 semillas durante 200 años o final válido, distribuidas entre orígenes, especies, políticas e intensidades. Añadir mil años activos con/sin extraordinarios y extinciones válidas por separado.
- Rendimiento: mapas 64/96 y ≥32 asentamientos sostenidos, catálogo completo, profile en Android de referencia: ≥30 FPS, respuesta visible ≤200 ms, cancelación confirmada ≤1 s, memoria máxima <512 MiB. Medir/publicar tiempo de cien años sin prometer instantaneidad.
- Android: instalación limpia/actualización, offline, primera sesión, intercambio, cierre/continuación, tamaños móviles y texto ampliado. Comprobar comprensión con una persona nueva además de tests automatizados.

La evidencia heredada acredita una base Android, 39 pruebas, equivalencia temporal y 30 semillas a 200 años. Dos objetivos de mil años terminaron en día 215.910 y el benchmark cayó por debajo de 32 asentamientos: no acreditan esas aceptaciones. No hay medición aprobada del teléfono de referencia. Repetir las baterías pertinentes tras cambiar reglas; conservar semilla, versiones, órdenes y reproducción por fallo. Filtradas, omitidas o con cero casos no son baterías completas aprobadas.

## 12. Hitos y definición de terminado

R0–R13 y sus dependencias se concretan en PLAN.md y el registro de ampliación. Cada cierre exige pruebas, documentación y APK que arranque. El trabajo paralelo separa dueños de simulación, contenido, arte, presentación y persistencia/pruebas; contratos compartidos se integran primero.

Terminado exige todos los requisitos originales y nuevos obligatorios con evidencia; ambos orígenes, humanos/equinos, seis eras, familias/instituciones/conflictos, diez decisiones, determinismo, recuperación y rendimiento aprobados. Entregar fuente, recursos/generadores, inventario, paquete de ejemplo, lockfile, APK firmado para pruebas, checksum, instrucciones y capturas reales; distinguir compilar, instalar y funcionar. No cerrar con requisitos parciales/bloqueados ni publicar en tiendas. Para rendimiento se necesita teléfono de referencia o laboratorio equivalente; si falta, el criterio permanece pendiente.

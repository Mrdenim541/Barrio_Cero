# Ejecución del rediseño aprobado: BARRIO CERO: ERAS

## Prioridad actual del usuario — presentación 0.18

El usuario solicita priorizar gráficos, texturas e interfaz conforme a las láminas y entregar un APK descargable en GitHub. Esta entrega conserva los hitos M0–M11 y las obligaciones pendientes. Incluye atlas originales renovados, paisaje por bioma, interfaz verde/dorada, geografía versionada para mundos nuevos y aldeas compactas. Las partidas existentes conservan su terreno, coordenadas y reglas. M2 avanza parcialmente en geografía; mundo 2, checkpoint 4 y su migración integral siguen pendientes. La publicación autorizada corresponde al código y APK de prueba en GitHub, sin publicar el entorno.

## Plan vigente M0–M11

Ampliación posterior: [PLAYER_FOCUS.md](docs/PLAYER_FOCUS.md) reemplaza el acceso Barrio por Seguir y añade protagonista humano/no humano, seguimiento persistente y estados Normal/Sin envejecimiento/Inmortalidad total. La cámara es presentación; los modos de vida son reglas del mundo que requieren integración demográfica, persistencia y pruebas. Las láminas visuales se mantienen como objetivo con ese cambio de navegación.

El plan aprobado del planeta continuo se ejecuta en [PLANET_PLAN.md](docs/PLANET_PLAN.md), manteniendo los mapas H/R/E anteriores y los 174 requisitos en `docs/planet_requirements.json`. Se conserva Flutter/Flame, con una cámara sobre coordenadas comunes y el ritmo elegido de vida local y crecimiento. La agrupación E1–E6 de abajo sigue siendo trazabilidad; M0–M11 determina las nuevas puertas de ejecución.

M0 cuenta con recorrido nativo 0.16: año sin órdenes idéntico a la referencia, intervención, avance, cancelación de cien años en día 630 y reapertura exacta con objetivo pendiente. M1 integra cámara continua, caché rasterizada y Seguir: 211 pruebas aprobadas, análisis final limpio y APK 0.17 instalado. Android recuperó al protagonista tras terminar el proceso y conservó el checkpoint exacto; todos los guardados originales se restauraron por hash. [Los registros](docs/validation/planet/README.md) conservan también los fallos de inicio y distinguen el benchmark anterior del paquete final. M1 cierra esta base funcional; no acredita trabajos reales, viajes personales, geografía nueva, dirección artística final ni rendimiento físico.

Las extinciones de los dos casos largos de reglas 11 no validan milenios activos. La nueva organización y las mejoras de cámara no cierran M2–M11 ni autorizan publicar el entorno.

**Aclaración vigente del usuario:** el producto es un planeta autónomo con acercamiento a territorios, asentamientos y habitantes. Observar o intervenir no debe suspender su evolución propia. [WORLD_AUTONOMY.md](docs/WORLD_AUTONOMY.md) precisa los cambios respecto de 0.14, las compatibilidades y los criterios transversales de E1–E6. La siguiente integración prioriza observación e intervención opcional; la guía no será necesaria para que el mundo avance. Esta dirección sustituye el énfasis previo en gestión manual, conservando las especificaciones y requisitos anteriores.

Integración 0.15 de esa dirección: creación autónoma predeterminada, intervención puntual con autoridad/restauración transaccionales, entrega explícita de decisiones antiguas, zoom conectado y reproducción conservada al inspeccionar. La referencia de un año y su ejecución Android se contrastan con contenido real. Se aprueban 202 pruebas; la evidencia separa suite, análisis final, compilación y recorrido nativo en `docs/validation/observer/`. Permanecen pendientes las fronteras y sociedades políticas completas de E2, sus vínculos generacionales, las capacidades/eras/especies de E3, el director ampliado de E4 y los cierres de E5–E6. La primera sesión de diez intervenciones es opcional y sigue requiriendo aceptación completa; esta integración no la sustituye.

La ampliación aprobada está en [REDESIGN_SPEC.md](docs/REDESIGN_SPEC.md). Conserva íntegra `PROJECT_SPEC.md`: 106 requisitos originales y 68 requisitos adicionales en [redesign_requirements.json](docs/redesign_requirements.json). La validación estructural de ese registro no demuestra funcionamiento. No se declara terminado ningún hito por disponer de documentación o botones.

Decisiones aceptadas: prehistoria como origen predeterminado; reconstrucción como segundo escenario completo; familias destacadas con población común agregada; evolución durante generaciones y siglos; humanos y equinos jugables; visitantes extraterrestres mediante acontecimientos; intimidad adulta sin representación sexual gráfica. Android vertical, offline, API 24 como mínimo y referencia Android 10/4 GB. WorldBox, RimWorld y BitLife tienen las responsabilidades descritas en la ampliación.

## Flujo activo: seis entregas completas

La revisión tras 0.15 amplía la selección a [34 referencias](docs/REFERENCE_GAMES_AUDIT.md), con cinco proyectos examinados en fuentes y un paquete inventariado mediante REA. Primer cambio 0.16: separar cálculo histórico y frecuencia de confirmación, manteniendo resultados y recuperación. La cámara continua por bloques, la expansión territorial visible y las actividades confirmadas siguen siendo criterios de E1/E2/E5; no se sustituyen por aumentar el zoom ni por esta optimización. La migración de motor permanece pendiente de una demostración comparativa, no decidida por instalar una herramienta de análisis.

Esta organización responde a la petición de reducir fragmentación y gasto de validación. Sustituye el orden de microversiones, conservando todos los criterios R0–R13 y los 174 requisitos. El mapa completo está en [execution_batches.json](docs/execution_batches.json): cada requisito tiene una entrega responsable y sus dependencias. Ningún estado de cumplimiento cambia por reagruparlo.

| Entrega | Pendientes que integra | Resultado revisable |
|---|---|---|
| E1. Experiencia inicial comprensible | R1/R4 y primera parte de R11: entrada clara, necesidades, habitantes, acciones contextuales, costes, cámara, escena local y composición visual | Un recorrido jugable desde el inicio con decisiones y consecuencias visibles; APK y capturas reales. Las diez decisiones completas se vuelven a cerrar con todos los sistemas en E5. |
| E2. Sociedades, territorio y vidas personales | R2/R3/R5/R6: territorio real, acceso político, instituciones, pactos, conflictos, ocupación, secesión, genealogía, relaciones adultas, herencia, sucesión y viajes de familias/personajes/colonias | Dos sociedades cuyo desarrollo cambia por decisiones reales, continuidad de familias y gobierno, pérdida de capital sin borrar identidad y guardados convertibles. |
| E3. Economía histórica, eras y especies | R2/R3/R4/R7: conservación global, recursos y trabajos territoriales, seis eras con soporte/pérdida de capacidades, humanos/equinos y coexistencia | Ambos orígenes completos; anatomía y alimentación cambian estrategias; 30 construcciones/mejoras y 48 tecnologías diferenciadas, sin progreso automático por año. |
| E4. Director narrativo y extraordinarios | R8/R9: participantes, causas, plazos, exclusiones, memoria, 144 eventos, 16 arcos, instalación unificada, ocho familias y extraterrestres | Cadenas completas con finales diferentes, consecuencias locales/regionales/planetarias, violencia con responsabilidad y ajustes que no borran hechos. |
| E5. Historia, arte y Android completo | R10/R11 y cierre de R1: archivo histórico por bloques, comparación, saltos, ZIP, recuperación, arte por especie/era, recorridos, audio, accesibilidad y tutorial | Sesión completa de diez decisiones con los cuatro resultados exigidos, presentación acorde al objetivo y cierre/importación/reapertura reales en Android. |
| E6. Aceptación y entrega | R12/R13 y revisión de todos los requisitos | Matriz cerrada, baterías completas, rendimiento medido, fuente/generadores/inventario/paquete, APK firmado de pruebas y SHA-256, instalación limpia y actualización. |

La prioridad inmediata pasa a E1, para que el progreso del motor sea comprensible y visible. E2–E5 se desarrollan como bloques integrados según sus dependencias; las correcciones internas no se presentan como entregas completas del juego. Cada entrega conserva las obligaciones originales y de la ampliación, incluidas las que ya tienen una implementación parcial.

Avance de E1 en 0.13: ficha de necesidades, sugerencia con validación real, guía opcional derivada de recibos, controles accesibles y primera mejora de lectura local. La integración aprueba 191 pruebas y compila APK profile conservando reglas 11; Android tiene evidencia propia. E1 permanece parcial hasta comprobar el recorrido inicial completo y su comprensión. La guía no sustituye la prueba de diez decisiones ni cierra R11. Véase [EXPERIENCE_FLOW.md](docs/EXPERIENCE_FLOW.md).

Refinamiento 0.14 por petición del usuario: más superficie para observar el mundo, tres indicadores consultables y una acción, sin párrafos ni configuraciones permanentes. Costes y requisitos siguen antes de confirmar; construcción y guía se conservan bajo Más acciones. Indicador de carga, selección/zoom para rótulos y feedback de obras confirmadas mejoran la lectura. Análisis y 192 pruebas aprobados; APK y recorrido nativo tienen evidencia propia en `docs/validation/compact/`. No cambia la simulación ni se cierran los requisitos restantes de E1–E6.

## Validación proporcional al cambio

- Durante el desarrollo: análisis y pruebas de comportamiento de los módulos cambiados, especialmente transacciones, población, guardado y compatibilidad. No repetir el recorrido Android completo ni los siglos por cada ajuste menor.
- Al integrar una entrega: batería rápida completa, contenido si corresponde, una compilación final y un recorrido Android combinado sobre ese APK estable. Si una corrección afecta la compilación final, comprobar esa corrección y el binario resultante, sin repetir casos independientes ya acreditados.
- Baterías largas: después de integraciones importantes y estables del motor, y en aceptación final. Los cambios exclusivos de documentación, arte o navegación no reinician una matriz congelada cuyo motor sigue igual. La matriz actual de reglas 11 continúa; se consumirán sus resultados existentes.
- Conservar la semilla y el primer fallo reproducible. Añadir una regresión útil y corregir el defecto antes de volver a lanzar una batería larga. No crear pruebas que solo repitan código, ni contar pruebas omitidas o vacías como aprobadas.
- Un solo agente, sin delegaciones adicionales no solicitadas. Informar por funciones terminadas, pendientes y evidencia; el número de pruebas no sustituye el avance jugable.

`tool/run_acceptance.sh` tiene tres perfiles:

```bash
# Durante un cambio de migración: análisis y comportamiento de ese módulo.
bash tool/run_acceptance.sh --profile quick --tests test/migration_transit_test.dart
# Al integrar un bloque: suite rápida completa y APK profile.
bash tool/run_acceptance.sh --profile integration
# Aceptación estable: añade simulaciones y cargas largas obligatorias.
bash tool/run_acceptance.sh --profile release
```

El perfil predeterminado es `quick`. `--dry-run` muestra las comprobaciones sin ejecutarlas ni registrarlas como aprobadas. Sin `--tests`, quick informa solo validación estática/análisis. El informe enumera pruebas diferidas y nunca declara aceptación completa del juego. Instalación, sesión Android y rendimiento físico mantienen evidencia separada. La validación final sigue exigiendo equivalencia temporal, mundo vivo, generaciones, ramas, interrupciones, treinta semillas/doscientos años, milenios activos y 32 asentamientos; el perfil rápido no las sustituye.

## Pendientes y límites que no desaparecen al reorganizar

La base 0.12 ya compila y funciona en Android, tiene guardado protegido, producción y formación, hogares básicos, migración de adultos en tránsito y varias verificaciones de siglos/carga. Eso permite construir los bloques anteriores sin rehacer esa base ni repetir sus comprobaciones por cambios ajenos.

Persisten la conservación material global y el esquema final; territorios, instituciones y conflictos; genealogía y herencia; familias/colonización en tránsito; seis eras, equinos y visitantes completos; director y catálogo ampliados; historia durable, ZIP y recuperación extendida; arte final y experiencia inicial. El catálogo actual tiene 25 construcciones, 32 tecnologías, 104 eventos independientes y 12 arcos, todavía sin completar todos los recorridos exigidos.

La referencia Android 10/4 GB requiere un teléfono o laboratorio equivalente para cerrar FPS, respuesta, cancelación y memoria. Es la dependencia externa de aceptación; no impide implementar los sistemas. Un APK compilado o un benchmark Linux no la sustituyen. No se publicará el entorno ni se hará un push como consecuencia de esta reorganización.

## Hitos actuales

| Hito y resultado | Dependencias y módulos | Prueba y criterio de cierre | Estado |
|---|---|---|---|
| R0. Contratos y trazabilidad | Base existente; documentos, registro, validadores, evidencias | Conservar los 106 IDs y sus fuentes, registrar ampliación, ejecutar línea base y preservar APK, contenido y guardados de referencia verificables | Verificado para R0 |
| R1. Interfaz comprensible | R0; presentación, consultas y sesión | Barrio/Mundo/Historia, inicio local pausado, fichas y costes previos; construir, avanzar, guardar, importar y reabrir; tamaños 320/360/412 y APK instalado | Parcial: integración técnica comprobada; revisión visual pendiente |
| R2. Núcleo transaccional | R0–R1; comandos, reglas, cantidades y PRNG | Rechazos sin mutación, idempotencia, reservas compartidas, cantidades fijas, orden diario estable y equivalencia temporal | Parcial: inventarios, pagos y reservas laborales integrados; conservación global y contratos restantes pendientes |
| R3. Modelo y migración | R2; entidades, ejecutor anterior y almacenamiento | Sociedad/asentamiento/cultura/especie separados; migración explícita world2/content2/checkpoint3 conserva identidad y población; fallo mantiene bytes originales y carga antigua | Parcial: identidades políticas y copia opcional probadas; esquema final pendiente |
| R4. Prehistoria jugable | R3; generación, economía, trabajos y cuadrícula | Ambos orígenes reales; recursos iniciales permiten supervivencia y obras válidas sin ayudas invisibles ni etiqueta engañosa | Parcial: apertura y supervivencia inicial comprobadas; integración y aceptación final pendientes |
| R5. Familias y generaciones | R3–R4; cohortes, personas, hogares y sucesión | Cien años con población reconciliada, formación, herencia y relaciones; ningún actor fallecido ni duplicación por nacimiento o migración | Parcial: grupos, sucesión, formación, hogares, vínculos y tutela; genealogía biológica, herencia e instituciones pendientes |
| R6. Sociedades conectadas | R4–R5; territorio, rutas, instituciones y conflictos | Dos comunidades crecen, caravana retorna, escasez causa respuesta; rutas cortadas, refugiados, secesión y pérdida de capital mantienen identidad y recursos | Parcial: grupos de adultos en tránsito con provisiones, desvío, regreso y guardado; familias, colonización en tránsito, territorio e instituciones pendientes |
| R7. Especies y eras | R4–R6; biología, capacidades, edificios y tecnologías | Equinos con anatomía y estrategias reales; seis eras y coexistencia desigual; límites 179/180 y 359/360 días; 30 edificios/mejoras y 48 tecnologías diferenciados | Pendiente |
| R8. Narrativa instanciada | R5–R7; director, instancias, memoria y catálogo | Participantes, plazos, exclusiones y efectos válidos; 144 acontecimientos independientes, 16 arcos con dos finales completos cada uno, plantillas y mínimos originales | Pendiente |
| R9. Extraordinarios | R6–R8; instalación, familias y visitantes | Tres recorridos de instalación, ocho familias, efectos locales/regionales/planetarios y desactivación que respeta cadenas comprometidas | Pendiente |
| R10. Historia y recuperación | R2–R9; trabajador, checkpoints, informes e intercambio | Equivalencia completa, interrupciones en escritura/saltos, ACK después de persistir; bloques históricos y ZIP limitado; informes coinciden con hechos | Pendiente |
| R11. Experiencia completa | R7–R10; arte, guía, fichas, accesibilidad y Android | Diez decisiones con cuatro resultados originales, recorridos y actividades reales; texto ampliado y 48 puntos; persona nueva comprende la sesión | Pendiente |
| R12. Estabilidad y rendimiento | R6–R11; pruebas largas, balance y perfiles | 30 semillas/200 años, milenios activos y extinciones válidas separados; 32 asentamientos sostenidos en mapas 64/96, catálogo completo; referencia 30 FPS/200 ms/1 s/512 MiB | En curso: reglas 10 aprobaron cargas de 32 en ambos mapas y treinta semillas/200 años; milenio extraordinario activo, reglas posteriores y medición física pendientes |
| R13. Entrega | R0–R12; fuente, arte, paquetes, documentación y Android | Matriz obligatoria cerrada; instalación limpia/actualización/offline, APK y SHA-256, fuente y recursos originales, inventario, paquete de ejemplo, capturas reales | Pendiente |

Cada hito requiere pruebas pertinentes ejecutadas, resultados conservados, documentación coherente y un APK que siga arrancando. Compilación, instalación y funcionamiento se acreditan por separado. Una batería filtrada o con cero casos no cuenta como ejecución completa. El fallo conserva semilla, órdenes, versiones y punto reproducible. La evidencia anterior de 39 pruebas Flutter no se presenta como ejecución nueva.

Iteración 0.10: 166 pruebas, análisis limpio, ambos siglos equivalentes y migración básica comprobada en Android. La generación conserva terreno y conecta las aperturas. Los resultados largos de reglas 9 se registran en `docs/validation/migration/results.json` cuando concluyen; la matriz aprobada de reglas 8 sigue identificada como tal. El próximo defecto reproducido es la prioridad excesiva de caravanas existentes sobre el agua: debe corregirse conservando carga, trayecto y trabajo, sin introducir suministros de emergencia gratuitos. R6 conserva todas sus obligaciones restantes.

Iteración 0.11: se corrigió ese defecto con raciones protegidas y regreso autónomo físico. 170 pruebas, análisis limpio, APK comprobado en Android y siglos equivalentes de ambos orígenes. Los escenarios completos de 32 y la matriz larga de reglas 10 conservan su estado individual en `docs/validation/labor/results.json`; no se aprueban por estar lanzados. Próxima integración material de R6: residencia en tránsito y provisiones reales, llegada única y respuesta a cortes de ruta; después, territorio e instituciones. La dirección visual, especies, eras y el resto del alcance siguen pendientes de sus pruebas.

Iteración 0.12: residencia temporal, coste completo de viaje, provisiones finitas, recorrido, desvío, regreso y entrega única integrados para adultos comunes. 187 pruebas, ambos siglos equivalentes, reinicio del trabajador y recorrido Android final aprobados. Las cargas y semillas largas de reglas 11 se registran por variante; la primera variante falló el orden diario y no cuenta como aceptación final. Próximo trabajo de R6: territorio y acceso político, instituciones y consecuencias persistentes; los viajes de familias y colonización conservan sus criterios pendientes. No se declara cerrado R6 por completar este subbloque.

## Revisión visual pendiente en R1

El usuario reconoce todavía el prototipo rechazado en las capturas del APK 0.2.0. Mantener R1 parcial aunque las pruebas técnicas aprueben. La siguiente integración debe producir una mejora visible de la escena local y la interacción, contrastada con las láminas objetivo existentes y con estado real; las dependencias de cuadrícula, ocupación y trabajo corresponden a R2–R4. No dar por entregada la dirección artística por cambiar navegación y textos.

## Registro del primer bloque e integración

Este bloque pertenece al arranque ya ejecutado. Se conserva como historial; el flujo activo E1–E6 determina el trabajo siguiente y no exige repetir esta preparación.

1. Registrar la ampliación y preservar fuente, contenido, APK y guardados de referencia sin sobrescribirlos.
2. Ejecutar validadores, análisis y pruebas rápidas; distinguir resultados previos, nuevos y bloqueados.
3. Extraer el controlador de sesión conservando la autoridad única de escritura, protección frente a autoguardados antiguos, importación y selección de espacios.
4. Implementar Barrio/Mundo/Historia, inicio local pausado, fichas legibles y disponibilidad/coste antes de confirmar.
5. Compilar, instalar y comprobar orden, avance, guardado, importación y reapertura del escenario actual. No ofrecer Prehistoria hasta R4 con economía funcional.
6. Incorporar resultados en STATUS y en registros de evidencia; continuar R2–R13 por dependencias sin reducir la especificación.

Integración es propietaria de contratos compartidos, sesión, compilación y estado. Se pueden asignar módulos independientes de simulación, contenido, arte, presentación y persistencia a agentes con archivos propios; cambios de esquema se integran antes de consumirlos. Ningún agente acredita la integración mediante pruebas exclusivas de su módulo.

`python3 tool/verify_requirements.py` conserva la comprobación original. `python3 tool/verify_redesign_requirements.py --self-test` valida hashes, referencias, decisiones aceptadas, dependencias y evidencia estructurada, e inyecta registros inválidos en memoria. Todo requisito verificado necesita evidencia conductual o manual aprobada con ruta, comando y alcance. Los resultados estáticos no cierran requisitos jugables.

Los escenarios de mil años que terminaron por extinción en el día 215.910 y el benchmark que perdió la carga de 32 asentamientos no acreditan carga prolongada ni rendimiento de referencia. Para cerrar R12 hace falta un teléfono de referencia o laboratorio equivalente. La ausencia de ese dispositivo no impide desarrollar los sistemas; mantiene ese criterio pendiente.

# Historial H0–H11 (se conserva como obligación de entrega)

Referencia: PROJECT_SPEC.md completa, registro granular docs/requirements.json (106 bloques,20 apartados). Teléfono de referencia Android10+,4GB RAM; compatibilidad mínima API 24 acordada el 13 de noviembre de 2026 (Flutter 3.35.7). Criterios de finalización: todos los requisitos obligatorios con evidencia funcional aprobada; APK compilado, instalado y jugado; ninguna prueba omitida cuenta como aprobada.

| Hito | Resultado | Dependencia | Estado de cierre |
|---|---|---|---|
| H0 | Base Android ejecutable y lockfile | Acceso oficial Flutter y dispositivo | Cerrado para la base actual: APK, instalación, orden, avance y recuperación nativa; evidencia docs/validation/h0 |
| H1 | Contratos tipados y caracterización | H0 | Parcial, interfaz Command; regresión de espacios corregida y comprobada |
| H2 | Transacciones, determinismo y migración | H1 | Parcial, submit idempotente y envoltura checkpoint2 |
| H3 | Sociedades/ciudades/territorios y rutas | H2 | Pendiente |
| H4 | Economía y30tecnologías diferenciadas | H3 | Pendiente |
| H5 | Generaciones y continuidad cultural | H4 | Pendiente |
| H6 | Autonomía, instituciones y conflictos | H3–H5 | Pendiente |
| H7 | Director, arcos y extraordinarios completos | H2,H6 | Pendiente |
| H8 | Saltos, informes y recuperación | H2–H7 | Parcial, guardado completo y pausa del trabajador |
| H9 | Sesión Android,arte y documentos | H0,H8 | Parcial, SAF compilado; exportación/importación nativas comprobadas; primera sesión completa pendiente |
| H10 | Estabilidad,balance,rendimiento | H6–H9 | 30 semillas ×200 años aprobadas; objetivos de mil años terminaron por extinción; benchmark no mantiene 32 comunidades |
| H11 | Entrega verificable | Todos | Pendiente; APK inicial disponible, alcance completo sin cerrar |

Cada cierre requiere pruebas pertinentes ejecutadas, documentación y APK que siga arrancando. Las tareas independientes adelantan trabajo pero no cierran hitos dependientes bloqueados. No se reemplaza evidencia de ejecución por parser sintáctico.

## Propiedad e integración

Integración mantiene app,build,contratos y registro. Agentes separados implementaron órdenes del motor,checkpoint,SAF y baterías de aceptación en archivos distintos. Integración revisa los resultados y conserva resultados ejecutados,fallidos y no ejecutados separados.

## Continuidad de los hitos originales

Las obligaciones H0–H11 siguen vigentes y se trazan a R0–R13 mediante los 106 registros de `docs/redesign_requirements.json`. Los resultados anteriores no acreditan los sistemas ampliados. La autorización histórica del ZIP de pruebas no autoriza publicar el entorno, otro paquete o subir a tiendas.

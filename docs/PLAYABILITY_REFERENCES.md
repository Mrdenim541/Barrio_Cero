# Referencias y primera sesión de BARRIO CERO: ERAS

13 de noviembre de 2026. Dirección de diseño tras probar el APK y señalar el usuario que hay demasiadas opciones confusas. Este documento propone cambios; no afirma que ya estén implementados. Conserva PROJECT_SPEC.md, especialmente sus apartados 6–8 y 17–19.

## Referencias seleccionadas

| Juego | Qué aporta | Aplicación a BARRIO CERO |
|---|---|---|
| The Battle of Polytopia | Acciones táctiles ligadas a la selección, objetivos cercanos y lectura sencilla del mapa | Referencia principal de acceso a acciones: seleccionar algo, ver qué se puede hacer, conocer el coste y ver el resultado. No cambiar el calendario por turnos ni adoptar sus reglas de victoria. |
| WorldBox | Observar sociedades y transformaciones en un mapa vivo | Entender el mundo visualmente, acercarse a una comunidad e inspeccionarla. Mantener la diferencia entre observar una sociedad y asumir su dirección; no añadir poderes divinos gratuitos. |
| RimWorld | Necesidades de una comunidad, trabajo pendiente, personajes e historias emergentes | Comunicar por qué ocurre un problema, qué opciones tiene el jugador y qué consecuencia dejó su elección. Adaptar la presentación a móvil sin trasladar sus paneles de escritorio. |

Sitios oficiales: https://polytopia.io/ · https://www.superworldbox.com/ · https://rimworldgame.com/

Son referencias de patrones conocidos, no una revisión de sus versiones actuales: el acceso web a esos sitios devolvió 403 en este entorno. No se han copiado recursos, textos ni código. No hay aquí una afirmación de que alguno reúna toda la especificación de BARRIO CERO.

## Diagnóstico de la interfaz actual

Inspección de `lib/presentation/app.dart`:

- `_selection` muestra ocho acciones con la misma jerarquía en una fila horizontal; varias quedan fuera de la vista.
- `_world` mezcla tres escalas, cinco filtros, cuatro iconos de mapa y varios controles temporales. `Años` recibe mayor énfasis visual que las acciones iniciales.
- `_build` y `_research` enumeran los catálogos completos; el rechazo de una orden llega después de tocarla. Hace falta distinguir disponibilidad, requisitos y coste antes de confirmar.
- `_details` recorre las propiedades del modelo. Esa salida incluye identificadores y estructuras internas que no explican decisiones al jugador.
- `Cómo empezar` está dentro del menú y abre un texto de seis pasos; no acompaña la tarea ni detecta que se haya completado.
- Una partida nueva abre el mapa mundial. El jugador debe encontrar cómo acercarse a su comunidad antes de apreciar las construcciones.
- `_stories` usa definiciones elegibles, no exclusivamente instancias concretas con participantes y plazos. Reordenar el menú no resuelve ese trabajo pendiente de H7.

## Dirección de interacción

El ciclo principal será: observar una necesidad u oportunidad → elegir una acción → ver trabajo y costes → avanzar el tiempo → reconocer el resultado y su causa → decidir qué hacer después.

1. **Entrada sencilla.** `Continuar` y `Nueva partida`. La configuración detallada del mundo va en un desplegable con un resumen de los valores efectivos. Conservar las reglas y probabilidades actuales; no cambiar silenciosamente la dificultad o los extraordinarios.
2. **Empezar en el barrio.** Mostrar la comunidad controlada en la escala de asentamiento, con el tiempo pausado y su nombre visible. Mantener acceso inmediato al mundo. Observar otra sociedad no transfiere el control.
3. **Tres destinos estables.** `Barrio`, `Mundo`, `Historia`. Las acciones concretas pertenecen a una selección o a una ficha; los ajustes, paquetes y archivo de partidas van en el menú. La escala regional y los filtros se encuentran dentro de Mundo.
4. **Una sugerencia contextual.** Una tarjeta breve propone una tarea realizable y permite descartarla. No inventar hambre, obras ni sucesos para mantener activo el tutorial. La sugerencia se obtiene del estado y se recalcula si el jugador elige otra cosa.
5. **Acciones comprensibles.** Cada orden muestra resultado esperado, coste, trabajadores, duración y motivo de indisponibilidad. Mostrar primero las acciones disponibles; ofrecer un acceso explícito a las futuras, con sus requisitos. No eliminar contenido ni crear bloqueos tutoriales artificiales.
6. **Tiempo con jerarquía.** Pausa/reproducción y avance corto permanecen visibles. Un control `Avanzar…` reúne día, mes y saltos de años. Los saltos largos siguen accesibles desde el principio, con sus confirmaciones y políticas; el tutorial no los exige antes de explicar órdenes y consecuencias.
7. **Información por capas.** Resumen de población, alimento y salud; al tocarlo, reservas y causas. Reemplazar el volcado del modelo por fichas de habitantes, proyectos, edificios y relaciones. Las cifras y las previsiones deben proceder de reglas reales; no presentar estimaciones sin soporte.
8. **Decisiones cuando importan.** Destacar decisiones pendientes y crisis; registrar cambios rutinarios en Historia. Una ficha debe distinguir resultado conocido, riesgo e incertidumbre. Una alerta debe permitir localizar a sus participantes o su lugar.

La guía puede omitirse y retomarse. Guardar su progreso como estado de presentación, sin consumir el PRNG del mundo, introducir recursos, alterar la autonomía o cambiar el resultado de la simulación.

## Primera sesión propuesta

| Momento | Acción del jugador y respuesta necesaria |
|---|---|
| Llegada | Reconocer Barrio Cero y sus personajes; entender que está guiando esa comunidad. |
| Primera elección | Comparar dos tareas realmente disponibles, por ejemplo huerto o vivienda según recursos y condiciones. Conocer coste, duración y finalidad antes de ordenar. |
| Trabajo | Ver la obra pendiente en el asentamiento y su progreso. Avanzar el tiempo; la construcción aparece solo cuando el motor la completa. |
| Consecuencia | Relacionar el cambio con la orden: qué se construyó, qué se gastó y qué capacidad cambió. No sustituirlo por un mensaje genérico de éxito. |
| Exterior | Localizar otra comunidad y ejecutar una interacción viable. Mostrar qué se transfirió, acordó o rechazó y por qué. |
| Historia | Resolver una decisión contextual con consecuencia aplazada y una opción que se desbloquee por hechos del mundo. Estas condiciones necesitan completar los sistemas narrativos pendientes. |
| Primer salto | Comprender la política delegada, realizar un salto corto y leer un informe vinculado a las causas. Poder guardar, cerrar y retomar. |

Durante las primeras diez decisiones significativas deben cumplirse los cuatro resultados de PROJECT_SPEC.md: cambio visual persistente, consecuencia aplazada, interacción exterior y opción nueva desbloqueada. Abrir fichas o pulsar diez controles no cuenta como diez decisiones. La prueba debe registrar las elecciones y los cambios concretos, no solo contar pulsaciones.

## Bloque de implementación prioritario

| Tarea | Dependencias y módulos | Evidencia para terminar |
|---|---|---|
| UX1: jerarquía y fichas | H0; `app.dart`, `world_game.dart`; preservar contratos y guardado de H1/H2 | Nueva partida centrada en el barrio; cada acción anterior sigue localizable; fichas sin datos internos; controles legibles a 320/360/412. APK instalado. |
| UX2: órdenes y progreso | Comandos y proyectos reales; presentación y consultas al motor | Una acción no disponible explica el requisito antes de enviarla; otra válida reserva materiales una sola vez, muestra trabajo y deja un edificio real. |
| UX3: guía contextual | UX1/UX2; estado de presentación persistente | Omitir, retomar y desviarse de la sugerencia funciona; cerrar/reabrir conserva el progreso; igual semilla y órdenes producen el mismo mundo con guía activada o desactivada. |
| UX4: diez decisiones completas | H6/H7/H8 más UX3 | Recorrido Android con los cuatro resultados obligatorios, interacción exterior, consecuencia diferida y salto. No cerrar esta tarea con botones o fixtures aislados. |

Comprobar también texto ampliado, contraste, controles táctiles de al menos 48 puntos y ausencia de desbordamientos. La aceptación de comprensión necesita observar a una persona que no conozca la interfaz: debe localizar su comunidad, dar una orden, explicar su coste, ver su resultado y volver a la partida sin instrucciones externas. Las pruebas automatizadas apoyan esa comprobación, pero no prueban por sí solas que la experiencia sea clara.

Adelantar UX1–UX3 no cierra H9 completo ni sustituye los sistemas pendientes. No se añaden dependencias ni se modifica el APK como parte de este documento.

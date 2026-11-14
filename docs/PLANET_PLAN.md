# Plan vigente: planeta autónomo

Plan aprobado para ejecutar después de 0.16. Base local `828109a`, reglas 11. Conserva PROJECT_SPEC.md, REDESIGN_SPEC.md y sus 174 identificadores. Las aclaraciones posteriores prevalecen donde cambian el inicio o la presentación; no se reescriben las fuentes históricas.

## Decisiones de producto y arquitectura

- Flutter/Flame y núcleo Dart conservados. Godot queda como contingencia que requiere una comparación equivalente, no una migración ya autorizada por rendimiento supuesto.
- Planeta finito 2D, mapas regionales 64/96, 32 microceldas por celda y una cámara continua. El terreno detallado no equivale a recursos nuevos.
- Inicio autónomo y pausado. Vida local y crecimiento es el ritmo elegido; observar y seleccionar no desactivan la IA. Intervención puntual y dirección explícita siguen diferenciadas.
- Tres accesos: **Seguir, Mundo e Historia**; la ampliación posterior del usuario sustituye Barrio por seguimiento de un protagonista real. Se conserva autonomía; acciones contextuales y configuraciones fuera del mapa principal. [Identidades y modos de vida](PLAYER_FOCUS.md).
- Mantener ambos orígenes, seis eras, humanos/equinos, visitantes, familias, instituciones y el catálogo ampliado: 30 construcciones, 48 tecnologías, 144 acontecimientos independientes y 16 arcos.
- Trabajar con un agente. No reinstalar REA ni añadir MCP. Los patrones de referencias abiertas se implementan con código original; no se importan sus recursos sin verificar licencia.
- Nuevos contratos conservan comandos transaccionales, consultas sin efectos, PRNG, sesión única y confirmación duradera. La siguiente evolución de datos será mundo 2, contenido 2 y checkpoint 4; checkpoint 3 ya existe.

## Hitos y puertas de integración

| Hito | Resultado verificable | Dependencia |
|---|---|---|
| M0 | Base 0.16 preservada, 174 requisitos trazados, instalación/salto/cancelación/reapertura comprobados | Base existente |
| M1 | Cámara común, detalle por escala, bloques visibles y navegación entre ciudades sin escenas separadas; carga de 32 | M0 |
| M2 | Geografía versionada, coordenadas físicas, mundo 2/checkpoint 4 y conversión que conserva originales | M1 |
| M3 | Trabajo, recorridos locales, producción, construcción, aprendizaje y hogar vinculados a actores reales | M2 |
| M4 | Demostración conjunta de autonomía, comercio, historia personal, intervención comparada y salto recuperable | M3 |
| M5 | Territorio, ocupación, instituciones, conflicto, refugiados, colonias y secesión con continuidad | M4 |
| M6 | Parentesco, herencia, sucesión y viajes de familias/personajes sin duplicar población | M5 |
| M7 | Economía conservativa, mantenimiento, seis eras, regresión y catálogo material completo | M5–M6 |
| M8 | Humanos/equinos diferenciados, coexistencia y soporte material de visitantes | M7 |
| M9 | Director instanciado, plazos/memoria, catálogo narrativo ampliado y extraordinarios completos | M6–M8 |
| M10 | Historia durable, fronteras históricas, ZIP, arte, accesibilidad y diez decisiones opcionales | M9 |
| M11 | Baterías finales, teléfono de referencia, instalación/actualización y entrega íntegra | Todos |

Cada hito cierra con pruebas pertinentes, documentación y APK que arranque. Una implementación parcial o compilación no cierra su aceptación funcional. La demostración M4 exige vídeo/capturas reales y revisión de comprensión: localizar una ciudad, seguir una actividad, explicar un cambio, intervenir y recuperar.

## Validación y persistencia

Durante desarrollo: pruebas focalizadas. Al integrar: análisis, suite rápida, catálogo cuando corresponda y APK. Baterías largas tras cambios sustanciales de reglas y cierre final; no reiniciar reglas 11 por presentación.

Se conservan equivalencia de 36.000 días/diez décadas/un siglo; mundo vivo; generaciones; dos finales por arco y tres rutas de instalación; interrupciones/corrupción/disco lleno; treinta semillas por doscientos años; milenios activos con/sin extraordinarios y extinciones por separado; al menos 32 asentamientos sostenidos; interfaz 320/360/412.

API mínima 24. Referencia Android 10+/4 GB: 30 FPS, controles en 200 ms, cancelación confirmada en un segundo y máximo 512 MiB. El tiempo de cien años se medirá. El host/emulador no acredita el teléfono físico.

Cada orden se publica después de escritura. Los saltos conservan lotes adaptativos y objetivo pendiente; hasta un año no confirmado puede recalcularse. La historia futura usará bloques por hash y manifiesto atómico. ZIP por streaming de 64 MiB comprimidos/256 MiB descomprimidos; mantener JSON antiguo, pins exactos y copia de migración.

## Evidencia y discrepancias preservadas

0.15 tiene recorrido Android; 0.16 tenía análisis/15 pruebas/APK, sin recorrido nativo cerrado. La medición AOT de diez años (20.054→3.525 ms, 120→10 guardados) es del host.

La matriz completa de reglas 11 contiene treinta semillas que alcanzan 72.000 días y dos extinciones antes de 360.000. `fullMatrixPassed=true` describe éxito del ejecutor con finales válidos; **no acredita milenios activos**. `activeMillenniaVerified=false` y los resultados individuales conservan esa distinción.

El registro `planet_requirements.json` enlaza cada ID original con fuente, H/R/E anterior, hito M, criterios y evidencia heredada. Heredar un estado no cierra la aceptación de la versión futura. La entrega completa exige cada criterio obligatorio con evidencia, código/recursos/generadores/inventario/paquete, lockfile, APK firmado de pruebas y checksum; compilación, instalación y funcionamiento separados.

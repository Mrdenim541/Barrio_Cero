# Investigación de referencias y lotes históricos

## Herramienta instalada

REA 6.9.0 está instalado de forma aislada en `/workspace/toolchains/rea`. Se usa con:

```bash
node /workspace/toolchains/rea/node_modules/rea-agents/scripts/rea.mjs --version
```

Se instaló desde el paquete oficial fijado, con scripts de instalación y dependencias opcionales desactivados. No se ejecutó `rea setup`, no se modificaron configuraciones de agentes y no se publicó el entorno. Esto acredita CLI disponible, no integración MCP. `rea-installation.json` conserva identidad y hash del lockfile externo.

## Investigación

`repositories.json` conserva las consultas de metadatos de 13 repositorios, incluidos REA, motor y demos. `inspected-sources.json` identifica los archivos realmente leídos de cinco proyectos de juegos. Las revisiones de checkout y de metadatos pueden diferir: se usan los commits de cada archivo como autoridad sobre su contenido. `source-excerpts.json` también conserva una ruta de Widelands que devolvió 404; no se cuenta como inspeccionada.

El inventario REA corresponde a `Mindustry.jar` oficial v160.7, SHA-256 `36d94941a1639478ad1d9be25a9d802c6f77552f400c6da0338b7b019f63a0d1`. Se ejecutó:

```bash
node /workspace/toolchains/rea/node_modules/rea-agents/scripts/rea.mjs inspect-artifact \
  /workspace/references/Mindustry-v160.7.jar --detail summary \
  --evidence_output /workspace/Barrio_Cero/build/validation/reference-analysis/mindustry-artifact.evidence.json \
  --format json
```

El resumen conserva el identificador de evidencia padre y las limitaciones. Incluye 5.238 entradas de archivo y 173 de directorio, sin ejecutar el juego, recuperar su lógica mediante decompilación ni demostrar rendimiento. La inspección de código se hizo directamente sobre fuentes; la propia guía REA recomienda esa vía cuando existen fuentes completas. No se afirma que el checkout de Mindustry tenga la misma revisión que el JAR de lanzamiento.

La evidencia completa queda en `build/validation/reference-analysis/`, identificada por `retained-bundle.json`; no se agrega ese bundle de 12 MiB al historial Git. Los juegos comerciales no se ejecutaron ni decompilaron en esta revisión. El catálogo de 34 títulos distingue candidatos de diseño, metadatos, fuentes e inventario de paquete.

## Cambio implementado y medición

`history_slice.dart` agrupa cálculo histórico por un máximo de 360 días y presupuesto de 200 ms, cediendo al bucle de eventos tras cada bloque de hasta treinta días. Ese presupuesto se verifica entre bloques; un bloque lento puede excederlo. El trabajador y la variante web comparten la implementación. Los resultados dependen de días y PRNG, no del reloj que decide cuándo guardar. Se conserva la confirmación duradera antes del siguiente lote.

`history-batches-10-years.json` corresponde a una única comparación secuencial AOT en el host, con catálogo real, origen prehistórico, semilla 17 y extraordinarios desactivados. Ambas variantes usaron el controlador de sesión y escrituras con flush/rename en archivos temporales. Alcanzaron el día 3.600 con el mismo estado canónico completo: `bbe48337c48a56919a213475abfa2efef5ef5d1908acf360adabb7bc33f35b88`.

| Medida | Treinta días por confirmación | Agrupación adaptativa |
|---|---:|---:|
| Confirmaciones | 120 | 10 |
| Bytes escritos | 102.459.424 | 8.665.333 |
| Tiempo total del host | 20.054 ms | 3.525 ms |

La comparación utiliza el mismo ejecutor con límite de treinta días para la referencia anterior; no conserva la versión completa antigua como otro binario. No incluye el transporte entre isolates, dibujo, FPS, selector de archivos ni rendimiento de un teléfono. El orden fijo y una sola repetición tampoco permiten extrapolar un factor universal. No acredita un salto completo de cien años.

Se corrigieron dos avisos de estilo del script de medición después de compilarlo; no afectan a su lógica ni al resultado conservado. El análisis final, las pruebas focalizadas y la compilación Android tienen registros separados. Las pruebas cubren resultados idénticos entre presupuestos y guardados, cancelación, crisis, parámetros inválidos y la confirmación del trabajador. No se relanza la matriz larga del motor por cambiar únicamente la agrupación, conservando sus límites de procedencia.

Reproducción de la comparación:

```bash
source tool/development_env.sh
dart compile exe tool/benchmark_history_batches.dart -o build/history-batches-benchmark
build/history-batches-benchmark 10
```

La nueva granularidad conserva como máximo un año sin confirmar: tras una interrupción se vuelve al último checkpoint y se repite ese cálculo. El objetivo pendiente y la semilla se conservan; no se atribuye a disco un resultado que todavía no se escribió.

## Límites de entrega

`results.json` distingue código validado, APK compilado y comprobación Android pendiente. No se han añadido cámara continua, fronteras, especies, eras ni arte externo con este cambio. No se han incorporado código o recursos GPL/MPL al producto. Los 174 requisitos siguen vigentes y el juego continúa incompleto.

# Iteración 0.4 — trabajo y transporte con compromiso real

Reglas 3 y checkpoint 3. No es una entrega final del juego.

## Cambios comprobados

- Una obra consume jornadas de personal, se pausa sin adultos y solo termina al completar el trabajo. Quien termina una obra no produce también durante ese día.
- Cancelar devuelve una sola vez la fracción no utilizada de sus materiales registrados. Las obras heredadas sin costes registrados no inventan devoluciones.
- Expediciones, caravanas y obras comparten el presupuesto diario de adultos, en ese orden. Las prioridades son deterministas; aún falta una interfaz de asignación laboral completa.
- Una caravana recorre ida y regreso. El metal viaja a bordo y llega al regresar; un corte conserva carga y posición. Cerrar una ruta ordena el retorno físico y libera el personal al llegar.
- Las reglas antiguas permanecen disponibles. La actualización explícita conserva el original exacto; adapta obras, expediciones y cargas, sin inventar historia.
- `content/catalog.json` es la fuente de las tablas base. `generate_catalog.py` genera el ejecutor compatible y `build_content.py` consume el mismo JSON. Regenerar no modifica los bytes del catálogo existente. Esto elimina la extracción de reglas desde Dart; no completa los efectos tecnológicos pendientes ni las extensiones dinámicas de edificios.

## Evidencia

`results.json` registra los hashes y el alcance. Pasaron 100 pruebas Flutter, incluido trabajo insuficiente, devolución idempotente, conservación de carga, retorno físico y guardado durante el regreso. El análisis no encuentra incidencias. La equivalencia con catálogo real alcanzó 36.000 días en sus cuatro recorridos y comparó 41.293 entradas causales completas, incluso las podadas de la vista reciente.

`build-final.log` acredita compilación debug. La instalación y la interacción Android se registran separadamente en `native-result.json` cuando concluyen; los fallos del emulador no cuentan como funcionamiento aprobado.

La matriz de treinta semillas conservada en `../rules3/stability-30-seeds.log` pertenece a la versión anterior: treinta alcanzaron 200 años; los escenarios largos acabaron en extinción a los días 222.120 y 215.250. No acredita mil años activos ni las reglas nuevas de esta iteración.

## Pendientes

R2/R3 permanecen parciales: no existe todavía un libro completo de producción y consumo, conciliación poblacional final, cohortes, hogares o esquema World2 completo. Este cambio aporta parte del transporte exigido por R6, pero no demuestra migraciones en tránsito, instituciones o territorio. No acredita R4–R13, el arte final ni rendimiento en un teléfono de referencia.

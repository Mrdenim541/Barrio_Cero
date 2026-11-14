# Observación autónoma — 0.15.0+16

Esta integración permite iniciar un planeta autónomo, acercarse entre mundo, región y comunidad e intervenir sin asumir su gobierno. Es una entrega parcial de E1; no acredita el juego completo.

## Comprobaciones

- `integration-results.json` conserva la ejecución original: validadores aprobados, 202 pruebas aprobadas y APK profile compilado. El análisis inicial falló por dos importaciones relativas del generador, no del código de la aplicación. `analyze-final.log` acredita el análisis limpio después de corregirlas.
- Solo `tool/build_observer_scenario.dart` cambió entre esa integración y el cierre: importaciones de paquete. Los hashes del código de la aplicación, pruebas, recursos y configuración siguen coincidiendo. No se repitió la suite ni se recompiló por esa corrección del generador.
- `focused-acceptance.log` conserva las diez pruebas nuevas de sesión, gestos y presentación. Los registros `diagnostic-*` conservan fallos intermedios; no cuentan como resultados aprobados.
- Los 19 archivos protegidos del motor y contenido coinciden con las entradas congeladas de reglas 11. La matriz larga existente conserva su procedencia y no se reinició por esta presentación.

## Android real ejecutado

El APK se instaló y ejecutó en un emulador Android API 29 por software, 320×640. Esto comprueba comportamiento en Android, no velocidad ni estabilidad en el teléfono físico de referencia.

`tool/build_observer_scenario.dart` crea el mundo mediante la sesión normal, semilla 17, prehistoria, sin extraordinarios y sin inyectar recursos ni decisiones. Produce un checkpoint inicial y la referencia del año completo con el catálogo fijado. En Android, el mundo pasó de 42 a 69 sitios y de cero a 27 tecnologías durante 360 días, con cero órdenes del jugador; el JSON completo coincidió con la referencia. La población pasó de 144 a 141: autonomía no significa crecimiento garantizado.

El zoom no cambió ningún byte del checkpoint. La intervención opcional cambió la política alimentaria manteniendo `controlledId=null`, recursos y fecha. Después de otro mes, el cierre forzado y la reapertura conservaron exactamente el checkpoint del día 390. Los guardados originales se restauraron y comprobaron por hash. Resultados detallados: `native/results.json`.

Se revisaron visualmente las capturas 01, 02, 03 y 06: planeta inicial, informe del año, asentamiento acercado y planeta reabierto. Proceden de la aplicación; no son ilustraciones. El mapa actual todavía no representa fronteras políticas reales.

## Reproducción y artefactos

Fuente del escenario: `tool/build_observer_scenario.dart`; metadatos: `scenario-metadata.json`. El checkpoint y la referencia completos permanecen en `build/validation/observer-scenario/`. El APK y su checksum están en `build/deliverables/barrio-cero-eras-0.15.0-profile.apk` y su archivo `.sha256`.

`native-harness.py.txt` conserva el guion ejecutado; dependía del prefijo auxiliar temporal archivado en `native-helpers.py.txt`. Son procedencia de esta ejecución, no un comando portátil listo para ejecutar: contienen rutas y coordenadas del emulador. Antes de repetir hay que preparar el escenario, adaptar las rutas auxiliares y usar un dispositivo de pruebas con respaldo de partidas. No se necesita repetir para consultar esta evidencia.

`results.json` enlaza alcance, hashes y pendientes. `SHA256SUMS` permite comprobar la integridad de los archivos de evidencia. Compilación, instalación y funcionamiento están acreditados por separado; rendimiento físico, territorios, eras, especies y la aceptación completa siguen pendientes.

Los logs archivados normalizan retornos de carro y espacios finales para su lectura en Git. `raw-log-hashes.json` conserva los hashes previos a esa normalización; no se alteraron resultados ni mensajes.

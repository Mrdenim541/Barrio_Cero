# Estado de BARRIO CERO: ERAS

Actualizado el 13 de noviembre de 2026. La especificación completa sigue pendiente. **No existe APK compilado ni juego instalado. H0 no está cerrado.**

## Evidencia disponible

- Emulador Android 10 arrancado por software: ADB reconoce `emulator-5554` y `sys.boot_completed=1`. Registro: `docs/validation/environment-readiness.json`. Esto comprueba el dispositivo de pruebas, no la aplicación.
- Validador Python: estructura, referencias, grafo tecnológico, mínimos, hashes de dos paquetes y diez casos de rechazo aprobados. Catálogo: 96 eventos independientes y 62 nodos de 12 arcos; 16 plantillas, 18 edificios, 30 tecnologías, 12 recursos, 6 biomas, 12 rasgos, 6 perfiles y 8 familias.
- Parser Dart sin errores sintácticos. No comprueba tipos ni comportamiento.
- Registro `docs/requirements.json`: 106 bloques de los 20 apartados, vinculados al hash de PROJECT_SPEC.md. El verificador comprueba trazabilidad; ningún bloque se declara funcionalmente aprobado.
- Base original preservada en commit local `146184f`. No se ha publicado el repositorio.

## Cambios implementados pendientes de ejecución

- Órdenes tipadas, transaccionales e idempotentes; validación del actor; corrección de Equilibrio, reparaciones y reservas de expediciones. La autonomía aún utiliza la API anterior: no está completada la unificación de comandos del plan.
- Envoltura de guardado versión 2: mundo, objetivo del salto, ajustes y contenido exacto protegidos conjuntamente. Migración explícita del formato anterior, conservando copia original. Esto no completa la futura migración del modelo de sociedades y asentamientos.
- Selector Android de documentos mediante SAF, importación validada y cancelación; sin permisos generales de almacenamiento.
- Integración: nueva partida e importación se guardan antes de reemplazar el mundo; arranque asíncrono conserva el contenido importado; fallos al preparar saltos liberan la interfaz; cancelación anticipada se conserva; Guardar ahora confirma después de completar disco; errores de inicio del trabajador se notifican.
- Pruebas ampliadas de órdenes, checkpoints y documentos. Baterías largas con catálogo real, secuencia causal íntegra, treinta semillas por doscientos años y escenarios de mil años; benchmark de 32 asentamientos con cobertura poblada explícita.

Estas pruebas están escritas, **no aprobadas**. El runner `tool/run_acceptance.sh` registra comandos, hashes, resultados y bloqueos en `build/acceptance/`. Una comprobación omitida nunca cuenta como aprobada. El resultado de este bloque se conserva en `docs/validation/implementation-block-results.json`, con hashes de fuente y salidas.

## Herramientas y bloqueo externo

Flutter fuente 3.35.7, Java 21.0.13, plataforma Android 36 r2, Build Tools 35.0.0, Platform Tools 37.0.1, NDK 27.0.12077973, emulador 37.2.13 e imagen API 29 x86_64 presentes. Wrapper Gradle 8.12 verificado; AGP 8.9.1 y Kotlin 2.1.0 configurados.

La descarga oficial de Dart devuelve `CONNECT tunnel failed, response 403` para `storage.googleapis.com`. El borrador de configuración revisión 5 incluye ese dominio, `download.flutter.io` y `maven.google.com`; la instancia observada conserva revisión 1 sin dominios adicionales. Guardar el borrador mediante herramientas no aplica la política de la instancia.

**Acción externa necesaria:** guardar/aplicar el cambio de red preparado en Environment settings. Después se comprobará una conexión nueva. No se han ejecutado resolución de dependencias, análisis Dart/Flutter, pruebas Dart/Flutter, benchmark ni compilación Android. Tampoco existe lockfile resuelto, instalación del juego, captura real ni medición de rendimiento del producto.

## Continuación

1. Tras aplicar la red, ejecutar `bash tool/setup_android.sh`, resolver dependencias y conservar `pubspec.lock`.
2. Ejecutar análisis y pruebas; corregir los errores que revelen y generar el primer APK debug.
3. Usar `bash tool/start_android_emulator.sh`, instalar el APK y verificar nueva partida, mapa, orden, avance y guardado/carga.
4. Registrar compilación, instalación y funcionamiento por separado. Continuar H1–H11 manteniendo Android ejecutable.

Persisten las limitaciones del modelo descritas en `docs/IMPLEMENTATION_AUDIT.md`: sociedades y asentamientos unidos, territorio político incompleto, instituciones y secesión pendientes, generaciones y migraciones parcialmente reconciliadas, tecnologías poco diferenciadas y narrativa incompleta. Habilitar Flutter no completa esos sistemas.

Las imágenes de `docs/design/` son referencias del diseño final solicitado; no son capturas ni evidencia de ejecución.

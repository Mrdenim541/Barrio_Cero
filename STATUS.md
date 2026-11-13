# Estado de BARRIO CERO: ERAS

**Implementación inicial entregada en código; solicitud completa todavía NO terminada. No existe APK compilado.**

## Código preparado

Flutter 3.35.7 + Flame, Android vertical API23+, motor Dart independiente con calendario de360 días, PRNG persistente, seis sociedades, mapas64/96, economía y proyectos,30 tecnologías, comercio terrestre, generaciones y cola causal. Interfaz de tres escalas con sitios locales persistentes, selección/control explícito, políticas, crónica y decisiones. Saltos1/10/100 años por el mismo tick diario con trabajador, confirmaciones de guardado y cancelación. Guardados con SHA256, copia anterior, tres espacios, duplicación y exportación/importación textual. Paquetes versionados declarativos para nuevos mundos.

Contenido:96 eventos independientes,12 arcos con62 nodos,16 plantillas,18 edificios,30 tecnologías,12 recursos,6 biomas,12 rasgos,6 perfiles y8 familias extraordinarias. Ana, Leo y Tito tienen identidades y edades. Arte original:6 roles×8 acciones×4 fotogramas,18 edificios distintos,6 terrenos,24 iconos e icono Android; generadores incluidos.

## Comprobaciones ejecutadas

- `python3 tool/validate_content.py`: PASS; mínimos, referencias, DAG tecnológico, desenlaces alcanzables distintos, dos paquetes SHA256 y diez rechazos de corrupción.
- Generación de contenido y arte repetida: archivos de assets idénticos byte por byte.
- Parser tree-sitter de todos los archivos Dart: sin errores sintácticos. **No es análisis de tipos ni ejecución Dart.**
- `bash -n tool/setup_android.sh`: PASS.
- Gradle wrapper oficial verificado por SHA256; Android herramientas por checksum oficial, TLS conservado.
- SDK instalado y listado: plataforma 36 r2, Build Tools 35.0.0, Platform Tools 37.0.1, NDK 27.0.12077973; Java 21. Flutter fuente fijada al commit `adc901062556672b4138e18a4dc62a4be8f4b3c2`.
- ADB iniciado y consulta real: lista de dispositivos vacía. No hay /dev/kvm disponible.

Evidencia: `docs/validation/checks.json`, `docs/validation/setup.log` y `docs/validation/final.log`. La lámina de arte es material de producción, no captura del juego.

## Bloqueo de herramientas

`bash tool/setup_android.sh` terminó con código 1 al obtener Dart desde `https://storage.googleapis.com/flutter_infra_release/flutter/035316565ad77281a75305515e4682e6c4c6f7ca/dart-sdk-linux-x64.zip`: `CONNECT tunnel failed, response 403` de la política de red. No se deshabilitó TLS ni se usaron binarios sin verificar. La instalación Android se completó por separado.

Se guardaron en el borrador del entorno `network.allowed_domains`, `install_script` y `start_skill`; esto no aplica ni publica automáticamente la configuración. Revisa y guarda el acceso oficial a storage.googleapis.com en Environment settings. Tras completar validación, publica el entorno para reutilizarlo. No se ha verificado restauración en otra tarea.

## NO ejecutado

`flutter pub get` (por tanto no hay lockfile resuelto), `flutter analyze`, `dart run tool/simulation_check.dart`, `flutter test`, `dart run tool/benchmark.dart`, compilación APK, instalación y juego Android. Los nueve grupos de pruebas del motor, pruebas de contenido y UI320/360/412 y benchmark32 asentamientos están escritos pero no aprobados ni medidos. No hay captura de aplicación ejecutándose, medición FPS o memoria simulando siglos.

## Límites reales del producto

Consultar `docs/IMPLEMENTATION_AUDIT.md` y `docs/SIMULATION_API.md`. Faltan profundidad de propiedad territorial, ocupación/secesión/instituciones, trayectos locales por tarea y reconciliación completa de identidades destacadas con bajas demográficas. Parte de los efectos tecnológicos son productividad agregada, no subsistemas específicos. La exportación Android es JSON/portapapeles, sin selector nativo de documentos; no hay interfaz de migración de esquemas/contenido ni una primera sesión de diez decisiones verificada. La demografía es agregada; los recursos naturales no se agotan de manera material completa. Estos límites no quedan resueltos solamente al habilitar Flutter.

## Siguiente paso ejecutable

Desde `/workspace/Barrio_Cero`, tras aplicar el permiso de red:

```bash
bash tool/setup_android.sh
export PATH=/workspace/toolchains/flutter/bin:$PATH
export ANDROID_HOME=/workspace/toolchains/android
export PUB_CACHE=/workspace/toolchains/pub-cache
export GRADLE_USER_HOME=/workspace/toolchains/gradle-cache
flutter analyze
dart run tool/simulation_check.dart
flutter test
dart run tool/benchmark.dart
flutter build apk --debug
```

Corregir los errores reales que estas comprobaciones revelen, guardar `pubspec.lock`, completar los sistemas pendientes y probar dispositivo/emulador. Un APK solo estará entregado cuando exista y su compilación haya terminado correctamente; instalarlo es una comprobación posterior independiente.

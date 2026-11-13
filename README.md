# BARRIO CERO: ERAS

Juego individual para Android, escrito en Flutter/Dart con Flame y una simulación local reproducible. No requiere cuentas, servidor, anuncios ni claves de API para jugar. La especificación completa se conserva en [PROJECT_SPEC.md](PROJECT_SPEC.md); el estado verificable de la entrega está en [STATUS.md](STATUS.md).

## Entorno y compilación

Requisitos del equipo: Linux x64, Git, curl, unzip, Python 3 y un JDK 21 completo (`javac`, no solo JRE). El script instala Temurin 21.0.9+10 verificado si falta el compilador. La instalación utiliza Flutter **3.35.7** (commit `adc901062556672b4138e18a4dc62a4be8f4b3c2`), Android SDK 36, Build Tools 35.0.0, Gradle 8.12, Android Gradle Plugin 8.9.1 y Kotlin 2.1.0. Android mínimo: Android 7 / API 24 (acordado el 13 de noviembre de 2026, por el mínimo soportado de Flutter 3.35.7). El script conserva la comprobación TLS y verifica el archivo de herramientas Android contra el manifiesto oficial. Las versiones Dart/Flutter y las dependencias efectivamente resueltas deben contrastarse con los registros de validación y `pubspec.lock`.

```bash
./tool/setup_android.sh
source tool/development_env.sh
flutter analyze
flutter build apk --debug
```

`BARRIO_TOOLCHAINS` permite elegir otro directorio de herramientas. Para máquinas fuera del entorno de nube, ajústalo antes de ejecutar el script. Los procesos no sobreviven a una nueva tarea: usa el checkout existente, sin crear worktrees, y vuelve a iniciar la aplicación cuando sea necesario.

Las descargas requieren los destinos oficiales `github.com`, `raw.githubusercontent.com`, `storage.googleapis.com`, `pub.dev`, `dl.google.com`, `maven.google.com`, `repo.maven.apache.org`, `plugins.gradle.org`, `plugins-artifacts.gradle.org`, `services.gradle.org` y sus destinos de distribución permitidos por el entorno. Un bloqueo de red debe resolverse en la configuración, conservando la validación TLS.

El comando genera `build/app/outputs/flutter-apk/app-debug.apk`. La existencia de estas instrucciones **no demuestra que se haya generado un APK**: consulta STATUS.md para los resultados reales de compilación e instalación.

## Instalar en Android

Cuando el APK haya sido compilado:

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
flutter run -d <identificador-del-dispositivo>
```

También puedes copiar el APK a un teléfono e instalarlo autorizando la fuente de instalación en Android. La firma de depuración es exclusivamente para pruebas. Para distribución, crea y guarda tu propia clave fuera del repositorio, configura firma de publicación mediante propiedades locales o variables seguras, incrementa la versión y ejecuta `flutter build appbundle --release`. Este proyecto no publica en tiendas ni incluye credenciales de firma.

## Desarrollo y continuidad

Consulta [PLAN.md](PLAN.md), [CONTENT_GUIDE.md](CONTENT_GUIDE.md) y [ART_GUIDE.md](ART_GUIDE.md). Las reglas residen en `lib/simulation`, el contenido en `assets/content` y la presentación en `lib/presentation`. El calendario tiene doce meses de treinta días; el tiempo se pausa al salir. La cámara y el dibujo no deben consumir el azar de simulación.

El código, el catálogo y el arte están sujetos a las comprobaciones descritas en STATUS.md. Una compilación verificada y una instalación probada son resultados distintos. No se afirma compatibilidad con todos los teléfonos sin pruebas en dispositivos.

# Entrega 0.19.0+20 — evidencia de actividad y ZIP

[Alcance de diseño](../../design/ACTIVITY_RELEASE_019.md). M3 permanece en curso; esta entrega no cierra tareas personales ni recorridos locales completos.

## Código y compilación

`integration-results.json` aprueba todos los checks seleccionados: análisis, **221 pruebas Flutter**, trazabilidad, contenido y compilación **release**. `compiled-sources.json` recoge los hashes de los archivos de aplicación compilados, cotejados sin diferencias al finalizar. Las reglas, calendario, PRNG y contenido no cambian respecto de 0.18: se mantienen reglas 11, mundo 1 y checkpoint 3. No se repitieron las matrices seculares por cambios de presentación.

`integration-first-results.json`, `first-flutter_tests.log` y `attempts.json` conservan dos fallos de la primera batería: una espera de restauración de cámara no sincronizada y un encabezado que pasó a requerir desplazamiento con texto ampliado. Se expone/espera la finalización real de la restauración y se prueba el desplazamiento. La nueva batería completa aprobó. El primer ensayo focalizado también corrigió el uso de pumpAndSettle con un bucle continuo de Flame.

Las pruebas de actividad conservan toda la asignación laboral y el estado canónico; no atribuyen contabilidad agregada a parcelas ambiguas ni muestran datos antiguos/extintos como producción actual. El progreso procede del trabajo pendiente real, incluidas pausas. La prueba de cámara conserva la simulación al elegir escalas.

## Paquete

`artifact.json`, `signature.log`, `package.log` y `alignment.log` separan tamaño, hashes, firma, versión, API y alineación. El APK universal pesa **52.553.481 bytes**, y el ZIP **23.535.622 bytes** frente a los 89.869.607 de la entrega anterior: reducción del 73,8 %. Conserva ARM32, ARM64 y x86_64, API mínima 24 y el mismo certificado de pruebas.

El ZIP contiene APK, instrucciones en español y SHA-256. `tool/package_android.py` comprueba CRC y que el APK interior coincide por hash. No vuelve a firmar ni modifica el ejecutable. El APK de prueba anterior permanece disponible.

## Android real ejecutado en emulador

`native-release/results.json` registra instalación como actualización, arranque offline, selector de escala, producción visible, seguimiento, proceso terminado y reapertura exacta. `committedActivityVisible`, `cameraPreservesExactCheckpoint`, `protagonistRestored`, `reopenExact` y `originalSavesRestoredExactly` aprobaron.

El fixture es una apertura normal prehistórica tras **un año autónomo**, semilla 73, mapa 96 y seis sociedades; no un escenario rellenado durante la prueba. El escenario se conserva en `tool/build_atlas_scenarios.dart`, con su evidencia anterior en `../atlas/scenarios.json`. Se preservó y restauró todo el directorio de guardados original por SHA-256. La preferencia de cámara se mantuvo separada del checkpoint.

Las imágenes `native-release/*.png` proceden del APK release exacto, no de un mockup o del renderizador del host. Android API29 x86_64, hardware ranchu, sin KVM, modo avión y datos/Wi-Fi apagados. El emulador userdebug permite root para preparar/restaurar los fixtures de una aplicación release no depurable; el producto no necesita root. El modo software específico de este emulador no cambia los teléfonos.

Esta comprobación funcional no mide FPS, latencia ni memoria física. `frameMetricsRequested=false` y `renderedCountsVerified=false`: no se presentan como objetivos aprobados del teléfono de referencia. La instalación limpia y la aceptación final de todos los sistemas siguen en M11.

## Distribución

El ZIP se distribuye mediante la rama pública `downloads/android-test-0.19.0`; la página de Release enlaza el archivo. El servicio de subida de assets rechazó la autorización en la entrega previa; no se repite esa ruta fallida. `github-download.json` y `github-download-http.log` registran una descarga anónima completa: HTTP 200, 23.535.622 bytes, CRC válido y hashes exactos del ZIP y APK interior. Coincide con el APK instalado y reabierto.

Mundo/checkpoint nuevos, trabajos locales, territorio/política completos, eras, especies, inmortalidad, catálogo ampliado, milenios activos y rendimiento físico siguen pendientes. Los 174 IDs se mantienen; ningún requisito final se cierra por esta entrega.

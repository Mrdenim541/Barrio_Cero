# Estado de BARRIO CERO: ERAS

Actualizado el 13 de noviembre de 2026. **H0 tiene una base Android compilada, instalada y comprobada. El juego completo todavía NO está terminado.**

## Evidencia ejecutada

- Flutter 3.35.7 / Dart 3.9.2 instalados, dependencias resueltas y `pubspec.lock` incorporado. Acceso oficial a Dart verificado con HTTP 200; el antiguo bloqueo 403 está resuelto en la instancia publicada. No se modificó ni publicó el nuevo borrador.
- Análisis Flutter limpio. 39 pruebas aprobadas: órdenes transaccionales, contenido, checkpoints, contrato de documentos, atlas originales y presentación móvil.
- Interfaz comprobada a 320/360/412 × 640; la prueba crea una partida, construye, avanza, lee el guardado real y reconstruye la sesión.
- APK debug compilado inicialmente y APK profile actualizado compilado, firmado para pruebas e instalado en `emulator-5554`, Android 10/API 29. Mínimo Android 7/API 24 aceptado por el usuario, por el mínimo de Flutter 3.35.7.
- Prueba nativa: semilla 42, mapa 96×96, orden de huerto, dos avances diarios, mapa/asentamiento visibles y recuperación tras `am force-stop`. El checkpoint antes y después del reinicio es idéntico y pasa el parser de la aplicación. Wi-Fi y datos móviles desactivados; el ajuste de modo avión está activo, pero el shell no pudo emitir su broadcast protegido.
- Exportación e importación nativas comprobadas: el selector de Android creó un JSON idéntico al checkpoint confirmado. Después de avanzar al día 3, importarlo restauró el día 2 y los mismos bytes; se conservaron tras pausa, cierre forzado y nueva carga.
- Capturas reales en `docs/validation/android/`; resultados, comandos, hashes y límites en `docs/validation/h0/`. APK conservado: `build/deliverables/barrio-cero-h0-profile.apk`.
- Catálogo Python: 158 eventos (96 independientes + 62 nodos de 12 arcos), referencias, grafo, mínimos, hashes y diez rechazos aprobados.

## Pruebas largas

La equivalencia temporal con catálogo real aprobó 36.000 pasos diarios, diez décadas, un siglo y guardado/reanudación en lotes de 137 días: mismo estado y secuencia íntegra de 50.518 acontecimientos. También aprobaron órdenes fechadas/observación, construcción, tres rutas de instalación, estudio histórico y sucesión.

Las treinta semillas completaron 200 años con invariantes anuales. Los dos escenarios con objetivo de mil años terminaron por extinción global en el día 215.910; validan ese final, pero no mil años activos. El runner original aprobó ocho grupos y falló después por exigir arbitrariamente 300 opciones frente a las 292 del catálogo. Se sustituyó ese contador por igualdad exacta del conjunto de opciones ejecutadas; las 292 opciones y las plantillas aprobaron en dos repeticiones focalizadas. No se presenta esto como una nueva ejecución completa ininterrumpida. Evidencia: `docs/validation/h1/`. Las opciones se prueban en fixtures; todavía faltan recorridos narrativos completos.

El benchmark midió cien años en mapas 64/96, pero terminó con 23/21 comunidades vivas. **No aprueba el requisito de carga sostenida de 32 asentamientos.** Las mediciones se conservan en `docs/validation/h0/benchmark-initial.json`; se corrigió el runner para que ese resultado no pueda aparecer como aprobado solo por terminar el proceso. No hay mediciones válidas de FPS o latencia en el teléfono de referencia.

## Correcciones demostradas en este bloque

Se corrigieron errores de tipos, el conflicto de nombre Simulation con Flutter, desbordamientos de interfaz, controles inferiores y la eliminación prematura del controlador del diálogo de semilla. El JRE disponible carecía de javac: se añadió JDK Temurin 21.0.9+10 verificado. Gradle usa el proxy heredado y mantiene TLS.

El emulador sufrió un ANR inicial de System UI y falló al descomprimir los PNG. La carga actual usa copias de los mismos píxeles en RGBA premultiplicado; los PNG originales siguen intactos y las pruebas comparan equivalencia visual. El arranque final usa Impeller/Vulkan con SwiftShader y las capturas muestran atlas reales. La ejecución por software sin KVM no acredita rendimiento de un teléfono.

## Continuidad y alcance pendiente

H1/H2 tienen comandos tipados, idempotencia, reservas y checkpoint autocontenido, pero faltan contratos y separación completa de sesión, unificación de órdenes autónomas, precisión material y migración del futuro modelo. H3–H11 conservan el alcance de PROJECT_SPEC.md: sociedades/asentamientos separados, territorio, instituciones, conflictos, generaciones coherentes, narrativa completa, historia, tutorial, recuperación y balance.

El registro `docs/requirements.json` mantiene 106 bloques de los 20 apartados y su hash original. Una prueba parcial no cierra todo un bloque. Las láminas de `docs/design/` son objetivos visuales, no evidencia.

Cuatro pruebas nuevas de archivos reales verifican la cola, copias, temporales incompletos y recuperación después de un error de escritura. No sustituyen pruebas de disco lleno ni interrupción a mitad de salto.

Se corrigió la selección de espacios: explorar el archivo no redirige el autoguardado. Una prueba reprodujo la sobrescritura potencial antes de la corrección; ahora verifica pausa de Android, conservación del segundo mundo y cambio conjunto de espacio y mundo tras cargar. Análisis limpio y 39 pruebas aprobadas. APK actualizado instalado conservando el guardado byte a byte: `build/deliverables/barrio-cero-eras-0.1.0-test.apk`; SHA-256 `948845b73e12b60955275157e08cb0fd34fd558bdf7597bd1c35b932330903bb`.

También se corrigió una carrera observada en Android: al regresar del selector, un autoguardado antiguo podía sobrescribir la partida importada después de confirmarla en pantalla. Se eliminó la segunda cola de escrituras; la regresión está reproducida y aprobada en pruebas automatizadas. La repetición nativa del APK corregido se registra en docs/validation/h1/results.json.

Continuación: completar separación de sesión y contratos H1/H2; seguir los hitos de PLAN.md manteniendo el APK ejecutable. No hay publicación en tiendas ni push del repositorio.

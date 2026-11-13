# Evidencia parcial de H1

Registro del 13 de noviembre de 2026. H1 completo sigue abierto.

## Partidas y almacenamiento

`slot-regression-before.log` reproduce el defecto: elegir otro espacio cambiaba el destino del autoguardado antes de cargarlo. `flutter-tests.log` contiene la prueba corregida: elegir espacio 2 conserva el espacio activo 1; una pausa no sobrescribe el segundo mundo; cargarlo confirma juntos el mundo y su destino. La misma prueba reconstruye la sesión desde el disco.

Las cuatro pruebas de `test/storage_native_test.dart` usan archivos reales y comprueban orden de escrituras, copia anterior, temporales incompletos, rechazo de rutas y recuperación después de un error al escribir el temporal. Este error se provoca con un directorio que ocupa el nombre temporal. No equivale a disco lleno ni a matar el proceso entre instrucciones.

La suite completa contiene 39 pruebas aprobadas; el análisis Flutter no presenta incidencias. `build-profile.log` corresponde al APK actualizado, instalado conservando la partida anterior. La última recompilación incluye también la corrección del orden de autoguardado e importación.

La prueba nativa de importación detectó otro defecto: la interfaz confirmó el mundo importado, pero un autoguardado anterior lo sobrescribió después en disco. `native-import-regression.json` conserva fechas y hashes del fallo; `import-regression-before.log` lo reproduce en una prueba automatizada. Se eliminó la segunda cola de autoguardado para que todas las escrituras se encolen directamente en SaveStore. La prueba ahora confirma que el archivo permanece igual al mundo importado incluso después de terminar los autoguardados pendientes.

## Simulación

`simulation-original-run.log` conserva tanto los resultados como el fallo original, sin ocultarlo. Aprobó ocho grupos, incluidos cien años equivalentes con el catálogo real y treinta semillas que alcanzaron doscientos años. Los dos objetivos de mil años finalizaron por extinción global en el día 215.910. No demuestran mil años activos.

El fallo posterior exigía arbitrariamente 300 opciones, frente a las 292 que contiene el catálogo validado. Se reemplazó ese contador por cobertura del conjunto exacto de identificadores. `content-options-rerun.log` acredita las 292 opciones; `templates-rerun.log` acredita el grupo de plantillas, sitios y reparación. Estas son repeticiones focalizadas, no otra batería completa ininterrumpida. Los fixtures de opciones no sustituyen recorrer cada arco desde su inicio.

## Android

Emulador Android 10/API 29, 320×640, CPU por software sin KVM. El selector nativo creó `/sdcard/Download/barrio-cero-0-dia-2.json`; el archivo exportado coincide byte a byte con el checkpoint confirmado y pasa `tool/inspect_checkpoint.dart`. La captura `../android/07-export-picker.png` procede del selector real. La repetición en el APK corregido restauró el día 2 después de avanzar al día 3 y produjo exactamente los bytes exportados. `08-import-picker.png` y `09-import-restored.png` muestran el selector y la confirmación real. Tras enviar la aplicación al fondo, cerrar su proceso y volver a cargar, se conservaron los mismos bytes y el día restaurado (`10-import-reopened.png`). El resultado se registra por separado en `results.json`.

APK de pruebas: `build/deliverables/barrio-cero-eras-0.1.0-test.apk`. SHA-256: `948845b73e12b60955275157e08cb0fd34fd558bdf7597bd1c35b932330903bb`. Mínimo Android 7/API 24, aceptado por el usuario. No es una entrega del juego completo ni una medición del teléfono de referencia.

## Pendiente

Separar controlador de sesión y almacenamiento; cerrar operaciones concurrentes de carga/importación; confirmar registros de paquetes después de persistirlos; completar contratos del motor. Permanecen pendientes los sistemas H3–H11, las pruebas de interrupción durante saltos, narrativa de extremo a extremo, mil años activos y rendimiento con 32 asentamientos sostenidos.

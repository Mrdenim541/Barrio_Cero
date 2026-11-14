# 0.20.0+21 — vida local, acciones y salto histórico

[Alcance y pendientes](../../design/LIVING_RELEASE_020.md). Se conserva la dirección visual del atlas y la autonomía; no se declara terminado el juego ni cerrado M3.

## Código y comprobaciones

`integration-results.json` conserva la ejecución completa: **228 pruebas Flutter aprobadas**, contenido, catálogos y trazabilidad aprobados. El análisis inicial detectó dos cuestiones de estilo en pruebas/herramientas; se corrigieron y `analyze-final.log` / `analyze-actions.log` están limpios. No se reescribe aquel resultado como una integración íntegramente verde.

Tras esa batería se estabilizó el marcador de ciudad frente a personas que caminan y se corrigió la disponibilidad de acciones durante guardados. `focused-final.log` registra nueve pruebas; `focused-actions.log`, dieciocho. Incluyen rutas, reanudación, cámara, interfaz y protocolo de cancelación/confirmación. Son baterías focalizadas, no otras ejecuciones completas. `build-actions.log` compila el APK publicado; `build-final.log` corresponde al candidato anterior.

`compiled-sources.json`, `artifact.json`, firma y paquete registran identidad del código, checksum, modo release, API mínima 24 y versión 21. El certificado coincide con las entregas anteriores. El ZIP universal conserva ARM32, ARM64 y x86_64; CRC y APK interior se cotejan por hash.

Las visitas guardan personas, celdas anteriores/actuales, destinos y caminos. Se comprueba que no duplican población, no consumen azar del motor ni cambian cantidades económicas. Los equipos comunes quedan limitados por adultos reales y trabajo contabilizado. Las visitas aún no completan ocupaciones personales ni toda la logística de M3.

## Siglo activo medido

`century-before-local-cache.json` y `century.json` alcanzan el día 36.000 con mundo activo y contenido real. El primero tarda 43.714 ms; el segundo **32.421 ms**, de los cuales 27.892 son cálculo, 105 proyección y 4.424 confirmación. Ambos tienen exactamente el hash completo `fe0231407323770a3d591c24f0ebb2132c00c1a79173a6d5e0274ef1ac86a52e`, incluyendo historia y rutas tras diferentes lotes/guardados.

Es una comparación exploratoria secuencial AOT del servidor con archivos temporales. No acredita cinco segundos, el almacenamiento nativo ni rendimiento físico. `discarded-memo.json` registra una caché que conservó el resultado, pero empeoró el tiempo: fue retirada; no está en el APK. `legacy-batches.json` conserva la comparación anterior, sin mezclarla con mediciones del teléfono.

Se calculan jornadas reales, con proyecciones del mapa separadas del checkpoint. El avance confirmado se escribe antes del ack. La granularidad máxima nueva es cinco años; un cierre puede repetir cálculo no confirmado, conservando el objetivo y los días guardados. Faltan pruebas finales de interrupciones reales, estabilidad ampliada y rendimiento con 32 asentamientos.

## Android

`native-release/` conserva el candidato inicial. Verificó desplazamiento de los 18 habitantes destacados y restauró exactamente los guardados originales. Falló al buscar un refugio fuera del área visible del selector. También se observó que los botones quedaban desactivados durante los guardados: ese defecto de producto se corrigió.

`native-final/` contiene la prueba del APK final: reproducción y posiciones persistentes, construcción desde el mapa mientras el mundo corre, coste descontado, autonomía, salto de un año y reapertura. Los resultados específicos figuran en `results.json`; no se da por aprobado un recorrido que falte o falle. El arnés normaliza los saltos de línea del puente de accesibilidad Android y elige el huerto visible, sin inyectar recursos o resultados.

Las capturas y vídeos son de Android API29 x86_64, emulador ranchu por software y sin KVM, con modo avión y datos/Wi-Fi apagados. No son ilustraciones. Se conservan reintentos del puente UIAutomator; no son métricas de rendimiento. Todos los originales se inventarían y restauran por hash. Las pruebas funcionales no acreditan FPS, latencia, memoria ni el objetivo de cinco segundos del teléfono de referencia.

## Entrega y continuidad

El ZIP se distribuye desde la rama pública `downloads/android-test-0.20.0`; la Release enlaza el archivo y las capturas. `github-download.json` registra la descarga anónima completa y la comparación con el APK instalado.

Se conservan 174 requisitos. Visitas locales usan extensión v1; mundo 1/checkpoint 3 y reglas materiales 11 continúan. Lectura de partidas antiguas no añade posiciones: Jugar activa la extensión conservando un punto anterior. Eras, especies, instituciones, inmortalidad, narrativa ampliada, milenios activos y aceptación física continúan pendientes.

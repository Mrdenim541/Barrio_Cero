# Estado de BARRIO CERO: ERAS

## Rediseño actual — R0 registrado; R1 parcial

Se conservaron los 106 requisitos originales y se añadieron 68 requisitos de la ampliación aprobada. La versión intermedia 0.2.0 incorpora Barrio/Mundo/Historia, fichas legibles, consulta y confirmación de costes, SessionController y confirmación durable de todos los lotes históricos.

La línea base de 39 pruebas pasó antes de modificarla. La batería integrada pasó 62 pruebas; tras corregir el recorte visual se repitieron las siete de interfaz (320/360/412 y texto ampliado), con análisis final limpio. El APK profile se compiló y se instaló por actualización en Android 10; la partida anterior se conservó byte a byte. Evidencia y límites: [validación R1](docs/validation/r1/README.md).

**R1 sigue parcial.** El usuario señaló que las capturas todavía parecen el prototipo rechazado. La navegación y la persistencia mejoraron, pero el arte, la distribución local y la presentación del asentamiento no alcanzan la lámina objetivo. Las capturas actuales son evidencia de una versión intermedia, no del aspecto final acordado. No se considera resuelta la objeción visual por aprobar pruebas técnicas.

Próxima prioridad dentro del rediseño: una escena local legible con escala útil, composición del asentamiento e interacción contextual vinculadas al estado real; contrastarla con `docs/design/world-and-settlement-target.png` mediante capturas ejecutadas. Los caminos, puestos de trabajo, recorridos y edificios nuevos que requieran modelo local se integrarán con R2–R4; no se dibujarán como simulación funcional sin sus reglas. R2 está iniciado; R3–R13 y el alcance original continúan sujetos a sus criterios pendientes.

## Iteración visual 0.2.1

La escena local tiene cámara ajustada al área habitada, terreno texturado, nombres y selección directa de edificios/habitantes. Los mundos nuevos distribuyen edificios por sectores sin solaparse; los antiguos conservan la versión de plano y la serialización. Se compactó la ficha inicial para ampliar el mapa. Batería completa: 67 pruebas; cinco comprobaciones focalizadas después de corregir herencia de planos en colonias antiguas; análisis limpio; APK instalado. Equivalencia temporal focalizada aprobada para semilla 17: 36.000 días, décadas, siglo y guardado/reanudación conservan estado y 50.518 acontecimientos con el catálogo real. Esta ejecución de un grupo no sustituye la aceptación completa. Capturas ejecutadas y límites en [validación de escena](docs/validation/r1-scene/README.md). R1 permanece parcial y no se presenta este cambio como arte final ni como implementación de eras, familias o especies.

## R2 iniciado: materiales

Se añadió un componente de cantidades enteras en milésimas y un libro de transferencias atómicas, reservas, devoluciones y consumos. La recuperación reproduce el historial y rechaza saldos y recibos falsos. Cinco pruebas focalizadas y análisis limpio. Todavía no está integrado con la economía activa ni con los restos demográficos; no se declara cerrado R2. Evidencia: `docs/validation/r2-materials/`.

## Integración 0.3.0 — materiales y sociedades

Los inventarios en milésimas ya se usan en mundos nuevos, los pagos reales tienen recibos verificables y los restos demográficos se guardan como enteros. Sesión y trabajador usan avance tipado. Las partidas antiguas mantienen sus reglas hasta aceptar una conversión con copia exacta por SHA-256 y restauración. La pertenencia política se separó del estado local: unión de sociedades con condiciones/costes, varias ciudades y cambio de capital sin trasladar reservas.

Batería completa: 93 pruebas; análisis limpio. Android verificó conversión, copia exacta, negociación/unión, cambio de capital y restauración byte a byte. Se conservan fallos de automatización y sus repeticiones. Hay una batería larga nueva en curso; todavía no acredita las treinta semillas ni mil años activos. Evidencia y limitaciones: `docs/validation/rules3/`.

R2 y R3 siguen parciales: faltan reservas laborales completas, conservación material de todos los flujos, esquema final y conciliación poblacional completa. R4–R13 conservan sus obligaciones; una unión y un registro político no acreditan territorio, instituciones, eras o familias. El catálogo aún depende del motor anterior. No se declara terminado el juego.

## Línea base anterior y evidencias históricas

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

El ZIP del APK se subió con autorización explícita a la rama `downloads/android-test-0.1.0`; su descarga HTTPS se comprobó con HTTP 200 y hashes coincidentes. No se publicó el entorno ni se subió a tiendas.

El rediseño aprobado sustituye la referencia principal anterior por WorldBox, RimWorld y BitLife. La implementación parcial actual y la objeción visual del usuario se describen al comienzo de este documento.

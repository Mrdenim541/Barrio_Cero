# Auditoría de implementación en curso

## Actualización 0.12 — reglas 11

187 pruebas y análisis limpio. Los grupos de adultos comunes tienen residencia en tránsito, provisiones pagadas, posición diaria, desvíos, espera, regreso, bajas y entrega única. El coste total se consulta antes de confirmar. Se preservan fechas/culturas, plazas comprometidas, balance de viaje y reglas antiguas. Los dos siglos equivalentes y el trabajador con checkpoint en tránsito aprobaron. Android final comprobó salida, coste, cierre en camino, llegada y reapertura; originales restaurados por hash. La primera variante falló la validación mensual anterior al paso de viajeros y se conserva como fallo, junto con su corrección reproducida. [Resultados y variantes](validation/transit/results.json). Territorio, instituciones, familias/colonización en tránsito y demás obligaciones de R6 siguen pendientes.

## Actualización 0.11 — reglas 10

170 pruebas y análisis limpio; raciones productivas protegidas frente a compromisos antiguos, caravanas en espera con carga y retorno autónomo físico. Se conservan los fallos y repeticiones. Android comprobó conversión de reglas 9 sin pérdida, ración completa de agua, cierre/reapertura y restauración de originales. Ambos orígenes repitieron siglos equivalentes; apertura 64×64 sostuvo al menos 32 durante el siglo. Las otras cargas y la matriz larga se registran por caso cuando concluyen. No se acredita rendimiento del teléfono físico ni finalización del juego. [Evidencia](validation/labor/README.md).

## Actualización 0.10 — reglas 9

166 pruebas y análisis limpio; ambos orígenes alcanzaron siglos idénticos con catálogo real. Aperturas conectadas sin alterar el terreno, prioridad de decisiones pendientes, respuesta autónoma diaria a necesidades graves e invitaciones migratorias con origen, razones, adultos comunes y cuidado restante comprobados. Android profile API29 confirmó cinco adultos trasladados, veinte alimentos pagados, consulta sin efectos y reapertura exacta; originales restaurados por hash. El primer intento de navegación nativa falló y se conserva. R6 sigue parcial: la migración aún es inmediata. El diagnóstico de apertura con 32 encontró reservas de transporte que ocupan todos los adultos; la carga larga y el rendimiento físico tienen aceptación separada. [Evidencia](validation/migration/README.md).

La matriz larga de reglas 8 terminó: treinta semillas alcanzaron doscientos años y los dos escenarios de mil años siguieron activos hasta el objetivo, con controles anuales. Esto no equivale a validar reglas 9, 32 comunidades sostenidas ni FPS del teléfono.

## Actualización 0.8 — hogares y vínculos

Reglas 7, 147 pruebas completas y análisis limpio. Contacto mensual, peticiones con participantes y plazos, hogar pagado, tutela de residentes existentes y memoria de pérdidas funcionan en el núcleo. Se comprobaron coste, idempotencia, vencimiento y muerte el mismo día de fundación. Los cien años equivalentes se repitieron en ambos orígenes. Android ejecutó hogar, cuidado y reapertura con datos originales restaurados. No hay genealogía biológica conocida, herencia material ni director declarativo unificado: R5 sigue parcial. El benchmark de apertura con 32 asentamientos falló la carga sostenida (mínimos 15/9); se conserva el fallo. [Evidencias](validation/social/results.json).

## Actualización 0.7 — reglas 6

139 pruebas y análisis limpio; cien años equivalentes en ambos orígenes con catálogo real. Se añadieron grupos por fecha, cultura y residencia, pertenencia real de personajes, bajas reconciliadas, archivo de procedencia, sucesión sin habitantes inventados y formación con trabajo y recursos. Los traslados preservan residentes pero todavía son instantáneos. No hay hogares, parentescos, herencia o biología equina. R5 pasa a parcial. La evidencia de compilación y la comprobación Android se distinguen en [población](validation/population/README.md). La batería larga 0.6 terminó con treinta semillas de 200 años; sus dos milenios acabaron por extinción y no validan reglas 6.

La auditoría histórica que sigue describe H1 y no sustituye los resultados posteriores. STATUS.md y los registros de cada versión conservan las diferencias.

Actualizada durante H1, 13 de noviembre de 2026. **El APK profile se compiló, instaló y ejecutó en Android 10; esto no completa todos los sistemas del juego.** Análisis limpio y 39 pruebas Flutter aprobadas. Se comprobó creación/carga, orden, avance, mapa/asentamiento, guardado y recuperación tras cierre del proceso. Resultados y capturas en `docs/validation/h0/` y `docs/validation/android/`. La tabla distingue las pruebas parciales de los criterios todavía pendientes. Los resultados de H1 están en `docs/validation/h1/`.

## Comprobaciones realizadas

- Validador Python del catálogo ejecutado: estructura de 158 eventos (96 independientes), doce arcos con desenlaces alcanzables distintos, dieciséis plantillas, grafo tecnológico, hashes de dos paquetes y diez pruebas de rechazo aprobados. Por separado se ejecutaron las 292 opciones del catálogo en fixtures Dart; esto todavía no acredita recorridos completos de los arcos.
- Wrapper oficial Gradle 8.12 descargado y SHA256 contrastado con el publicado; checksum de distribución fijado.
- `bash -n tool/setup_android.sh` aprobado. No demuestra ejecución completa del script.
- Android SDK 36, Build Tools 35.0.0, Platform Tools 37 y NDK 27 instalados, según verificación del agente principal. Java 21 disponible. Flutter 3.35.7 y Dart 3.9.2 instalados; JDK Temurin 21.0.9+10 completo y lockfile resuelto.
- Análisis Flutter limpio, 39 pruebas aprobadas, APK profile compilado e instalado. El parser sintáctico previo no se usa como sustituto de estas comprobaciones.

## Trazabilidad de la solicitud

| Área | Implementación encontrada | Validación pendiente o alcance limitado |
|---|---|---|
| Android individual offline y vertical | Scaffold Flutter/Flame, paquete `com.barriocero.eras`, API mínima 24 acordada, sin servicios de juego externos | Compilado e instalado en Android 10; sesión básica offline comprobada. Cobertura de dispositivos pendiente. |
| Mundo persistente y tres escalas | Semilla, mapas 64/96, seis biomas, seis sociedades, zoom, arrastre, minimapa y filtros | Mapa y asentamiento observados en Android; falta probar toda la navegación. Territorios son representaciones aproximadas; falta propiedad política detallada por celda. |
| Asentamientos | Edificios con ID y posiciones persistentes sobre cuadrícula local 32×32; UI usa esos sitios | Recorridos internos son animación representativa; no existe pathfinding local completo de cada tarea. |
| Pixel art original | PNG, atlas, paleta, fuente generadora e iconos Android originales | Atlas originales comprobados en Android mediante carga RGBA equivalente a los PNG; Los estados de animación están conectados a trabajo/personajes del modelo de forma representativa, no a cada ciudadano. |
| Calendario y determinismo | Tick diario, año de 360 días, RNG explícito serializado; simulación separada de presentación | Equivalencia de cien años aprobada en Dart con catálogo completo, lotes y guardado: mismo estado y 50.518 acontecimientos. No se ha contrastado equivalencia entre plataformas. |
| Economía y construcción | Doce recursos, pago previo, reserva de equipos, proyectos, producción, costes de insumos, reparación de daños | Reservas, construcción y reparación probadas en fixtures; huerto ordenado en Android. Balance, agotamiento de recursos naturales y mantenimiento material requieren mayor profundidad y pruebas. |
| Tecnología y rasgos | Catálogos alineados; treinta tecnologías con desbloqueos/reglas y factor institucional; doce rasgos afectan decisiones, producción o relaciones | No se ha probado cada efecto. Algunas tecnologías comparten el factor de productividad, con especialización mecánica limitada. |
| Sociedades autónomas | Prioridades, reservas, políticas, investigación, comercio, colonización, cambio de control y delegación | Autonomía ejecutada en las treinta semillas de 200 años; falta el escenario causal de mundo vivo. Fragmentación política, rebeliones, instituciones complejas y ocupación territorial no están completos. |
| Rutas y conflictos | BFS terrestre, carga pagada, avance diario, bloqueos, relaciones, consumo de suministros y bajas | No hay mercado general de precios ni sistema político de conquista completo. Migraciones no tienen caravanas físicas con ruta en todos los casos. |
| Generaciones | Cohortes agregadas, fracciones persistentes de envejecimiento/nacimientos/mortalidad, personajes y sucesión | Sucesión/extinción aprobadas en el runner; las identidades destacadas no se reconcilian plenamente con todas las bajas y migraciones demográficas agregadas. |
| Instalación antigua | Sellar, desmontar, estudiar o compartir, costes, efectos aplazados, energía, migración y señal | Tres respuestas y estudio histórico aprobados en el runner; falta unificar la implementación declarativa y recorrerla desde Android. Desenlaces dependen de reglas simples. |
| Catálogo narrativo | 96 eventos independientes, doce arcos adicionales, dieciséis plantillas instanciadas, ocho familias, opciones y efectos tipados | Estructura validada en Python y 292 opciones ejecutadas en fixtures. Falta recorrer dos finales de cada arco desde su inicio y comprobar alcance y balance en mundos reales. |
| Director y crónica | Condiciones, probabilidades base y condicionadas, cola temporal, decisiones delegadas, causas y lugares | Director ejecutado en las pruebas largas. Pruner conserva referencias causales; podría superar su objetivo de tamaño si muchas entradas están referenciadas. No hay garantía medida de rendimiento de cascadas. |
| Paquetes versionados | Parser Dart declarativo, registro, importación UI, ejemplo, hashes y versiones exactas por mundo | Parser y rechazos cubiertos por pruebas Flutter; completar casos de composición. No hay migración completa entre versiones de esquema o contenido de una partida existente. |
| Historia y saltos | Worker isolate Android, lotes confirmados por ACK después del guardado, cancelación, target persistente, punto anterior e informe | Equivalencia del núcleo aprobada; worker y recuperación a mitad de salto siguen pendientes de pruebas nativas. Suspensión y errores de almacenamiento necesitan fallos inyectados. Informe y comparaciones históricas son métricas agregadas, no mundos rebobinables. |
| Persistencia | Tres slots, cola de escritura, temporal con flush/rename, copia anterior, checkpoint v2 que protege mundo/contenido/objetivo/ajustes y selector Android SAF | Checkpoint y ciclo nativo de guardado/reinicio aprobados; selección de espacios corregida con prueba de autoguardado. SAF compilado; exportación/importación nativas restauran exactamente el checkpoint anterior después de avanzar un día. Migración explícita v1 a checkpoint v2 con copia original implementada; futuras migraciones del modelo y pruebas de interrupción pendientes. |
| Primera sesión y ajustes | Inicio, creación/carga, indicaciones breves, crónica, políticas, reducción de movimiento, sonido de sistema y vibración opcionales | Inicio y configuración revisados a 320/360/412; ciclo crear/ordenar/avanzar/cargar probado a 320. Falta prueba de diez decisiones y revisión completa de pantallas. Tutorial es orientación breve, no secuencia guiada completa. |
| Estabilidad y rendimiento | Suite Dart con equivalencia, ramas, sucesión, importación, treinta semillas ×200 años y escenario de mil años | Treinta semillas completaron 200 años; objetivos de mil años terminaron por extinción en día 215.910. Benchmark Linux medido, pero no mantuvo 32 asentamientos. Sin mediciones válidas de FPS, latencia y memoria Android. |

## Avance tras aprobar el plan

Emulador Android 10 arrancado y reconocido por ADB; el juego ya compiló, se instaló y completó su ciclo básico. Se añadieron comandos transaccionales con recibos persistentes, reservas de expedición, checkpoint autocontenido, selector SAF y pruebas asociadas. El trabajador comunica errores de inicio y la interfaz confirma escrituras antes de publicar el nuevo mundo. La equivalencia temporal usa el catálogo real y un registro causal íntegro; los resultados largos y sus límites están registrados en docs/validation/h1/results.json. Véanse STATUS.md y docs/requirements.json para estado y trazabilidad.

## Correcciones coordinadas durante la revisión

En la fase inicial se corrigieron por inspección de código: cohortes negativas al colonizar; conversiones enteras de límites; efectos `flag` con valores de texto; población serializada; catálogos discordantes; condiciones y probabilidades ignoradas; intensidades incompatibles; órdenes a sociedades sin asumir dirección; escrituras concurrentes; validación débil de importaciones; causas de la instalación; relaciones fuera de límites y envejecimiento detenido por redondeo. También se incorporaron sitios locales, reparación, rasgos, plantillas y confirmación persistente de lotes históricos.

Las pruebas posteriores caracterizan órdenes, reservas, contenido, sucesión y checkpoints; no demuestran por sí solas todos los comportamientos enumerados. Los límites siguen explícitos en la tabla.

## Siguiente paso ejecutable

1. Conservar APK, lockfile y evidencias; completar separación del controlador de sesión y contratos H1/H2.
2. Ampliar fallos de almacenamiento y cambios concurrentes de sesión; exportación/importación Android básicas ya verificadas.
3. Completar sociedades/asentamientos, territorio, política y narrativa conforme a PROJECT_SPEC.md.
4. Añadir escenarios activos de mil años y carga sostenida de 32 asentamientos; medir rendimiento en el dispositivo de referencia.
5. Mantener análisis, pruebas rápidas, validación de contenido y APK de regresión después de integrar cambios. **La especificación completa sigue pendiente.**

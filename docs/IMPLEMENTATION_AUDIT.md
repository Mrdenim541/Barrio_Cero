# Auditoría de implementación en curso

Actualizada tras H0, 13 de noviembre de 2026. **El APK profile se compiló, instaló y ejecutó en Android 10; esto no completa todos los sistemas del juego.** Análisis limpio y 35 pruebas Flutter aprobadas. Se comprobó creación/carga, orden, avance, mapa/asentamiento, guardado y recuperación tras cierre del proceso. Resultados y capturas en `docs/validation/h0/` y `docs/validation/android/`. La tabla siguiente conserva límites de implementación; «no ejecutado» en un subsistema significa que su alcance completo sigue sin probar, aunque exista una comprobación básica.

## Comprobaciones realizadas

- Validador Python del catálogo ejecutado: estructura de 158 eventos (96 independientes), doce arcos con desenlaces alcanzables distintos, dieciséis plantillas, grafo tecnológico, hashes de dos paquetes y diez pruebas de rechazo aprobados. Su resultado no acredita ejecución de los eventos en Dart.
- Wrapper oficial Gradle 8.12 descargado y SHA256 contrastado con el publicado; checksum de distribución fijado.
- `bash -n tool/setup_android.sh` aprobado. No demuestra ejecución completa del script.
- Android SDK 36, Build Tools 35.0.0, Platform Tools 37 y NDK 27 instalados, según verificación del agente principal. Java 21 disponible. Flutter 3.35.7 y Dart 3.9.2 instalados; JDK Temurin 21.0.9+10 completo y lockfile resuelto.
- El agente principal dispone de comprobaciones sintácticas por parser. Estas no son análisis estático de tipos ni compilación.

## Trazabilidad de la solicitud

| Área | Implementación encontrada | Validación pendiente o alcance limitado |
|---|---|---|
| Android individual offline y vertical | Scaffold Flutter/Flame, paquete `com.barriocero.eras`, API mínima 24 acordada, sin servicios de juego externos | Compilado e instalado en Android 10; sesión básica offline comprobada. Cobertura de dispositivos pendiente. |
| Mundo persistente y tres escalas | Semilla, mapas 64/96, seis biomas, seis sociedades, zoom, arrastre, minimapa y filtros | No ejecutado. Territorios son representaciones aproximadas; falta propiedad política detallada por celda. |
| Asentamientos | Edificios con ID y posiciones persistentes sobre cuadrícula local 32×32; UI usa esos sitios | Recorridos internos son animación representativa; no existe pathfinding local completo de cada tarea. |
| Pixel art original | PNG, atlas, paleta, fuente generadora e iconos Android originales | No comprobado visualmente en aplicación Android. Los estados de animación están conectados a trabajo/personajes del modelo de forma representativa, no a cada ciudadano. |
| Calendario y determinismo | Tick diario, año de 360 días, RNG explícito serializado; simulación separada de presentación | Pruebas de equivalencia de cien años escritas, no ejecutadas. No se ha contrastado equivalencia entre plataformas. |
| Economía y construcción | Doce recursos, pago previo, reserva de equipos, proyectos, producción, costes de insumos, reparación de daños | No ejecutado. Balance, agotamiento de recursos naturales y mantenimiento material requieren mayor profundidad y pruebas. |
| Tecnología y rasgos | Catálogos alineados; treinta tecnologías con desbloqueos/reglas y factor institucional; doce rasgos afectan decisiones, producción o relaciones | No se ha probado cada efecto. Algunas tecnologías comparten el factor de productividad, con especialización mecánica limitada. |
| Sociedades autónomas | Prioridades, reservas, políticas, investigación, comercio, colonización, cambio de control y delegación | No ejecutado. Fragmentación política, rebeliones, instituciones complejas y ocupación territorial no están completos. |
| Rutas y conflictos | BFS terrestre, carga pagada, avance diario, bloqueos, relaciones, consumo de suministros y bajas | No hay mercado general de precios ni sistema político de conquista completo. Migraciones no tienen caravanas físicas con ruta en todos los casos. |
| Generaciones | Cohortes agregadas, fracciones persistentes de envejecimiento/nacimientos/mortalidad, personajes y sucesión | No ejecutado. Las identidades destacadas no se reconcilian plenamente con todas las bajas y migraciones demográficas agregadas. |
| Instalación antigua | Sellar, desmontar, estudiar o compartir, costes, efectos aplazados, energía, migración y señal | Pruebas de ramas escritas, no ejecutadas. Desenlaces dependen de reglas simples. |
| Catálogo narrativo | 96 eventos independientes, doce arcos adicionales, dieciséis plantillas instanciadas, ocho familias, opciones y efectos tipados | Estructura validada en Python. Falta ejecutar todas las opciones, comprobar alcance y balance en mundos reales. |
| Director y crónica | Condiciones, probabilidades base y condicionadas, cola temporal, decisiones delegadas, causas y lugares | Código no ejecutado. Pruner conserva referencias causales; podría superar su objetivo de tamaño si muchas entradas están referenciadas. No hay garantía medida de rendimiento de cascadas. |
| Paquetes versionados | Parser Dart declarativo, registro, importación UI, ejemplo, hashes y versiones exactas por mundo | No ejecutado. Rechazo seguro y composición requieren pruebas. No hay migración completa entre versiones de esquema o contenido de una partida existente. |
| Historia y saltos | Worker isolate Android, lotes confirmados por ACK después del guardado, cancelación, target persistente, punto anterior e informe | No ejecutado. Suspensión, cierre abrupto, errores de almacenamiento y recuperación necesitan pruebas reales. Informe y comparaciones históricas son métricas agregadas, no mundos rebobinables. |
| Persistencia | Tres slots, cola de escritura, temporal con flush/rename, copia anterior, checkpoint v2 que protege mundo/contenido/objetivo/ajustes y selector Android SAF | No compilado ni probado en Android. Migración explícita v1 a checkpoint v2 con copia original implementada; futuras migraciones del modelo y pruebas de interrupción pendientes. |
| Primera sesión y ajustes | Inicio, creación/carga, indicaciones breves, crónica, políticas, reducción de movimiento, sonido de sistema y vibración opcionales | No hay prueba de diez decisiones ni revisión móvil 320/360/412. Tutorial es orientación breve, no secuencia guiada completa. |
| Estabilidad y rendimiento | Suite Dart con equivalencia, ramas, sucesión, importación, treinta semillas ×200 años y escenario de mil años | Escrita, no ejecutada. Sin mediciones de FPS, memoria, tiempos o mundo de 32 asentamientos. |

## Avance tras aprobar el plan

Emulador Android 10 arrancado y reconocido por ADB; el juego ya compiló, se instaló y completó su ciclo básico. Se añadieron comandos transaccionales con recibos persistentes, reservas de expedición, checkpoint autocontenido, selector SAF y pruebas asociadas. El trabajador comunica errores de inicio y la interfaz confirma escrituras antes de publicar el nuevo mundo. La equivalencia temporal usa el catálogo real y un registro causal íntegro; las baterías largas siguen sin ejecutarse. Véanse STATUS.md y docs/requirements.json para estado y trazabilidad.

## Correcciones coordinadas durante la revisión

Se corrigieron por inspección de código, sin ejecución: cohortes negativas al colonizar; conversiones enteras de límites; efectos `flag` con valores de texto; población serializada; catálogos discordantes; condiciones y probabilidades ignoradas; intensidades incompatibles; órdenes a sociedades sin asumir dirección; escrituras concurrentes; validación débil de importaciones; causas de la instalación; relaciones fuera de límites y envejecimiento detenido por redondeo. También se incorporaron sitios locales, reparación, rasgos, plantillas y confirmación persistente de lotes históricos.

Estas correcciones deben someterse a pruebas una vez disponible Dart. No se afirman como comportamiento verificado.

## Siguiente paso ejecutable

1. Conservar la base compilada, lockfile y evidencia H0; continuar separación de sesión y contratos H1/H2.
2. Ejecutar `flutter analyze`, la suite Dart y el validador Dart de contenido; corregir fallos de tipos e integración antes de afirmar que la aplicación funciona.
3. Compilar el APK de depuración e instalarlo en emulador o dispositivo. Verificar nueva partida, decisiones, tres escalas, comercio, saltos, guardado y recuperación; capturar la aplicación real.
4. Ejecutar y medir los escenarios de estabilidad y 32 asentamientos, además de las pruebas de tamaños móviles y suspensión.
5. Completar las limitaciones de diseño indicadas arriba. **La especificación completa sigue pendiente; el bloqueo de herramientas no es la única limitación de alcance.**

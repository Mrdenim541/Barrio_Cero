# Dirección de arte · Barrio Cero: Eras

Arte original generado para este proyecto; no incluye recortes ni personajes de la imagen de referencia. La referencia guía las proporciones compactas, cabezas grandes, contorno oscuro, herramientas reconocibles y colores tierra con acentos azules. No se usan emojis, fotografías, suavizado ni modelos 3D.

## Producción reproducible

Ejecutar desde la raíz `python3 tool/generate_art.py` con Python 3 y Pillow. El generador contiene las fuentes editables: coordenadas, polígonos, capas, variantes, fotogramas y paleta. No descarga arte externo. Todos los PNG tienen canal alfa. `assets/art/atlas.json` contiene dimensiones, índices y paleta exacta. Las imágenes se generan determinísticamente; la semilla de textura es independiente del azar de simulación.

`contact_sheet.png` es una lámina de producción para inspeccionar los recursos, **no una captura de la aplicación ni evidencia de ejecución**.

La integración 0.13 conserva estos atlas. El terreno de la vista local toma el bioma de la celda real, añade rótulos de edificios desde el catálogo fijado y ofrece encuadre cercano o general. Los rótulos evitan superponerse entre sí y a los controles. La decoración no añade recursos y la existencia de una obra no permite atribuírsela visualmente a una persona sin asignación. Esta mejora de lectura no completa el arte por era/especie, los recorridos ni las actividades confirmadas. Las capturas de ejecución están en `docs/validation/experience/`; las láminas objetivo continúan siendo diseños, no evidencia de esas funciones.

## Personajes y animación

`characters.png`: celdas de 32 × 48; cuatro columnas de fotogramas; 48 filas. Orden de roles: Ana, Leo, Tito, agricultor, guardia, sanitario. Cada rol ocupa ocho filas, en orden: reposo, caminar, trabajar, transportar, descansar, celebrar, peligro, pérdida. La fila es `rol * 8 + acción`. El tiempo recomendado por fotograma es 0,18 segundos. Las acciones tranquilas reutilizan celdas idénticas cuando el movimiento no aporta información.

Ana lleva gafas, bolsa de cables y llave; Leo tiene capucha, mochila y bastón; Tito lleva gorro, delantal y bolsa de suministros. El agricultor se reconoce por sombrero y azada, la guardia por casco y escudo, y el sanitario por insignia y botiquín. Las siluetas y el equipo distinguen las tareas sin depender solo del color.

Caminar alterna pies y altura; trabajar mueve la herramienta; transportar muestra una caja que cubre brazos y torso; descansar añade asiento; celebrar levanta brazos; peligro desplaza la postura; pérdida añade una expresión y lágrima discreta. Son animaciones de representación: nunca conceden recursos, aceleran el calendario ni eligen resultados. El renderizador debe seleccionar la figura a partir de habitantes y actividades reales del motor.

## Entorno

`buildings.png`: 18 celdas de 64 × 64, seis columnas y tres filas. Orden: granja, pozo, vivienda, aserradero, cantera, taller, clínica, escuela, mercado, muralla, mina, laboratorio, generador, telar, granero, recicladora, observatorio, hábitat. Usar los identificadores del atlas para adaptar los identificadores mecánicos del catálogo; no elegir la celda mediante nombres traducidos.

`terrain.png`: seis celdas de 32 × 32: llanura, bosque, desierto, montaña, humedal y agua. `icons.png`: 24 celdas de 16 × 16; recursos e indicadores consistentes con la misma paleta y contorno. Los iconos acompañan texto, nunca sustituyen unidades o explicaciones de costes.

## Paleta y lectura

Contorno `#25282b`; sombra `#414445`; suelo `#665441`; tierra `#897256`; arena `#c0aa77`; pasto `#758269`; hojas `#4f685b`; agua `#527983`; azul `#536f88`; piel `#b98361` y `#d2a577`; óxido `#925847`; acento dorado `#d0ab57`; claro `#d8cfad`. El manifiesto incluye las variantes restantes.

Mantener muestreo nearest-neighbor (`FilterQuality.none`), cámara sin rotación y coordenadas redondeadas cuando sea posible. No ampliar los personajes por interpolación suave. Terreno visto desde arriba; edificios y personas de frente con una ligera sugerencia de profundidad. Sombras simples sitúan las figuras sin física ni iluminación dinámica.

Reducir movimiento conserva el estado legible usando el primer fotograma. Los cambios permanentes se muestran por edificios, cultivos, daños o ruinas que existan en el modelo, no por una decoración que contradiga la simulación.

## Verificación del recurso

La generación verifica dimensiones a través del manifiesto. Inspeccionar la lámina tras modificar coordenadas. Para añadir contenido, asignar identificadores estables, agregar una celda al atlas y conservar el significado de los índices existentes o incrementar su versión. La licencia del proyecto puede aplicarse a este arte original junto con el código; no hay atribución externa obligatoria por estos recursos.

## Icono Android

El mismo generador escribe `android/app/src/main/res/mipmap-*/ic_launcher.png`, en cinco densidades (48, 72, 96, 144 y 192 píxeles). Representa una vivienda reconstruida sobre una placa verde, con marco de tierra y arena. No usa el logotipo predeterminado de Flutter.

## Contrato de animación y estado

API de atlas: `source = Rect(frame * 32, (roleIndex * 8 + actionIndex) * 48, 32, 48)`. `frame` pertenece a 0–3. `roleIndex`: técnica/Ana 0, explorador/Leo 1, suministros/Tito 2, agricultor 3, guardia 4, sanitario 5. `actionIndex`: reposo 0, caminar 1, trabajar 2, transportar 3, descansar 4, celebrar 5, peligro 6, pérdida 7.

La presentación puede derivar trabajar de un proyecto reservado, transportar de una ruta activa con carga real y un representante de suministros, y peligro de una crisis sanitaria o conflicto efectivo. Caminar requiere desplazamiento hacia un destino existente. Reposo es la opción segura cuando el modelo no especifica actividad. Celebrar y pérdida requieren un acontecimiento comprometido reciente; no se deben seleccionar por azar decorativo. Descansar corresponde a un grupo sin tarea activa y no genera recuperación mecánica por sí mismo. No representar individuos con `diedDay` informado ni trabajadores que excedan los adultos disponibles. Las figuras de grupo representan una parte de la población agregada, no individuos adicionales.

La reducción de movimiento usa el fotograma cero de la acción que corresponde al estado; conserva herramientas, carga y señales relevantes. La fase de presentación no forma parte del generador aleatorio del motor, y el cambio de acción nunca altera costes, salud, calendario o resultados.

Los 18 identificadores de edificio canónicos del motor coinciden directamente con el atlas: `farm, well, house, sawmill, quarry, workshop, clinic, school, market, wall, mine, laboratory, generator, loom, granary, recycler, observatory, habitat`. No hay alias que reemplacen telar, granero, recicladora o hábitat por otra construcción.

## Diseño objetivo de la versión completa

El usuario solicitó visualizar la versión final prevista para guiar la implementación. Las láminas `docs/design/world-and-settlement-target.png` y `docs/design/decisions-and-history-target.png` definen la dirección de composición, paleta, jerarquía de interfaz y densidad de pixel art. Son ilustraciones de diseño objetivo, no capturas ejecutadas ni evidencia de aceptación. Los números e historia representan una partida ilustrativa; el juego debe obtenerlos de la simulación real. Conservar controles táctiles legibles al trasladar cada panel a una pantalla vertical individual.

## Carga Android comprobada

Los atlas PNG originales se conservan. El generador produce también `characters.rgba`, `buildings.rgba` y `terrain.rgba`, con los mismos píxeles en RGBA8888 premultiplicado. El manifiesto indica dimensiones y formato. `loadArtPixels` comprueba el tamaño y carga esos datos sin depender del códec PNG de la plataforma; la prueba compara sus píxeles con los PNG originales (tolerancia de una unidad por redondeo alfa). Esto resolvió el fallo de descompresión observado en el emulador Android 10 con Flutter 3.35.7.

Las capturas de `docs/validation/android/` proceden de la aplicación instalada; las láminas de `docs/design/` siguen siendo objetivos visuales. La escena local actual es una base inicial y aún debe alcanzar la legibilidad, distribución y actividades del plan completo.

## Escena local 0.2.1

`SettlementScene` obtiene geometría exclusivamente de los edificios y habitantes vivos confirmados. La cámara y la selección usan las mismas transformaciones. La textura del suelo, sombras y entradas son elementos visuales; no acreditan rutas ni trabajos simulados. Los nombres identifican personajes existentes. El renderizador muestra reposo cuando no puede deducir una tarea, sin recorridos aleatorios de transporte.

Los planos nuevos usan `siteLayout: 2`, con sectores y huellas de 2×2 sin solapes. Los antiguos mantienen sus coordenadas y transmiten su versión de plano a sus colonias. No se regeneran para conseguir una imagen distinta. Las capturas de `docs/validation/r1-scene/` proceden del APK ejecutado; los atlas siguen siendo los recursos originales. La dirección artística completa de las láminas objetivo sigue pendiente.

## Recursos ancestrales de 0.6

El generador añade siete puestos/refugios y tres apariencias ancestrales, con ocho actividades cada una. El atlas de personajes es 128×3456; edificios, 384×320. La presentación obtiene dimensiones e índices de `assets/art/atlas.json`. Las pruebas cotejan PNG y RGBA y verifican que cada edificio publicado tenga píxeles en su celda. Las capturas de `docs/validation/prehistory/` son del APK; la hoja de contacto sigue siendo un inventario de recursos, no una captura del juego. No se considera completo el arte por especie, era, conflictos y transformaciones.

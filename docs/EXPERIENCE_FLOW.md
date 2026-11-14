# Experiencia inicial — integración 0.14

Este documento describe la interfaz implementada en 0.14. La aclaración posterior [WORLD_AUTONOMY.md](WORLD_AUTONOMY.md) establece el siguiente cambio: observar el planeta e intervenir opcionalmente sin frenar sociedades. No se considera ya implementado por disponer de un botón de delegación.

Esta entrega forma parte de E1 y conserva reglas 11. No completa las obligaciones de E1–E6 ni la aceptación de las primeras diez decisiones.

## Acceso desde el barrio

La ficha compacta muestra nombre, dirigente y tres indicadores: alimento, agua y habitantes. Tocar cada indicador abre su detalle; Habitantes muestra también las plazas disponibles y ocupadas. Los avisos de reservas comparan catorce días de consumo actual: no son una predicción del agotamiento, porque la producción continúa. Las obras pendientes no suman plazas.

Una sola acción destaca la siguiente posibilidad: decisión pendiente, reservas bajas, petición de convivencia, trabajo comprometido, vivienda o progreso posterior. Si ya se construye la mejora necesaria, conduce a la obra. Al observar otra comunidad, tocar su nombre abre la ficha y Asumir dirección permite revisar el cambio de gobierno.

Las explicaciones y los costes salen del primer plano. Al tocar una acción se consulta `Simulation.preview` y se muestran coste, requisitos, personal, duración y motivo de indisponibilidad antes de confirmar. Se conserva la comprobación de revisión. Leer indicadores, abrir la guía o mover la cámara no gasta materiales ni azar.

El botón Más acciones (tres puntos) reúne Construir, guía opcional y vista del mapa, además de las funciones anteriores. La guía también se abre desde Menú → Cómo empezar. No hace falta completar la guía para acceder a las funciones avanzadas.

Los resultados se muestran unos segundos sobre el mapa, sin reducir su tamaño. Pueden cerrarse o ampliarse al tocarlos, y el último permanece accesible en Más acciones → Último resultado. No son una nueva decisión ni una configuración.

## Guía libre

Los diez objetivos cubren prioridades, agua, vivienda, aprendizaje, exploración, comercio, hogares, respuesta a acontecimientos, conocimiento y delegación. No forman una secuencia obligatoria y pueden permanecer pendientes mientras falten requisitos o una situación real que los haga posibles.

Las marcas proceden de recibos de órdenes aceptadas de la comunidad seleccionada. Una consulta, un intento rechazado, otra comunidad o la repetición idempotente no añaden decisiones. La guía conserva esas marcas al reabrir la partida porque lee los recibos existentes. No introduce banderas, sorteos, recursos, sucesos o parentescos nuevos. Una marca acredita una decisión confirmada, no la conclusión de la obra o del viaje.

La prueba de las primeras diez decisiones de la especificación sigue pendiente: debe demostrar una transformación visible persistente, una consecuencia aplazada, interacción exterior y una posibilidad desbloqueada en un recorrido completo. El contador de esta guía no sustituye esa evidencia.

## Lectura visual

La cámara inicial se aproxima más; Ver todo el asentamiento recupera el encuadre general. Solo se dejan dos controles sobre la escena local. Arrastrar y pellizcar permiten recorrer y acercarse; los botones adicionales de zoom están en Vista del mapa. Los rótulos de edificios aparecen al seleccionar o acercarse suficientemente, usando las definiciones fijadas de cada mundo. La selección táctil comparte la transformación del dibujo. El terreno toma el bioma real; textura y vegetación decorativa no añaden inventarios.

La carga tiene un indicador breve y el fallo de una vista ofrece acceso al detalle. Un borde de tres segundos identifica las ubicaciones realmente añadidas tras completar obras; ordenar una obra no lo activa. Reabrir o cambiar de mundo no celebra todos los edificios. El borde también caduca con movimiento reducido, sin alterar días, recursos ni azar.

Se retira la animación que atribuía una obra a cualquier artesana por su oficio: la existencia de una obra no acredita una asignación personal. Las tareas y recorridos locales confirmados, el arte definitivo por era/especie y las escenas de consecuencias siguen pendientes.

## Comprobación y límites

La evidencia actual está en `docs/validation/compact/` y la anterior en `docs/validation/experience/`. Se distinguen análisis, pruebas, compilación y recorrido Android. El emulador por software no acredita rendimiento del teléfono de referencia. Las partidas originales se apartan durante el recorrido y se restauran comprobando todos sus hashes.

No cambian el esquema, la migración, el controlador de sesión, los paquetes fijados ni el motor. Se conservan las simulaciones AOT congeladas de reglas 11 y su procedencia; las nuevas pantallas se verifican por separado. E1 continúa abierto hasta demostrar el recorrido inicial completo, y R11 conserva la aceptación final ampliada en E5.

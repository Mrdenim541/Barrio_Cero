# Experiencia inicial — integración 0.13

Esta entrega forma parte de E1 y conserva reglas 11. No completa las obligaciones de E1–E6 ni la aceptación de las primeras diez decisiones.

## Acceso desde el barrio

La ficha muestra habitantes, dirección, reservas de alimento y agua y ocupación de vivienda. Los avisos de reservas comparan catorce días de consumo actual: no son una predicción del agotamiento, porque la producción continúa. Las obras pendientes no suman plazas.

La sugerencia prioriza una decisión pendiente, reservas bajas, una petición de convivencia, el trabajo ya comprometido, vivienda y posibilidades posteriores. Si ya se construye la mejora necesaria, conduce a la obra. En observación conduce a la ficha de la comunidad y explica que su gobierno sigue siendo autónomo.

Las sugerencias que emiten órdenes consultan `Simulation.preview`: la ficha muestra el coste o el motivo de indisponibilidad. La confirmación conserva los requisitos, personal, duración y comprobación de revisión. Leer la sugerencia, abrir la guía o mover la cámara no gasta materiales ni azar.

Construir y Más acciones permanecen al pie de la ficha. Su información superior se desplaza con texto ampliado. Las funciones avanzadas continúan disponibles. La guía opcional también se abre desde Menú → Cómo empezar.

## Guía libre

Los diez objetivos cubren prioridades, agua, vivienda, aprendizaje, exploración, comercio, hogares, respuesta a acontecimientos, conocimiento y delegación. No forman una secuencia obligatoria y pueden permanecer pendientes mientras falten requisitos o una situación real que los haga posibles.

Las marcas proceden de recibos de órdenes aceptadas de la comunidad seleccionada. Una consulta, un intento rechazado, otra comunidad o la repetición idempotente no añaden decisiones. La guía conserva esas marcas al reabrir la partida porque lee los recibos existentes. No introduce banderas, sorteos, recursos, sucesos o parentescos nuevos. Una marca acredita una decisión confirmada, no la conclusión de la obra o del viaje.

La prueba de las primeras diez decisiones de la especificación sigue pendiente: debe demostrar una transformación visible persistente, una consecuencia aplazada, interacción exterior y una posibilidad desbloqueada en un recorrido completo. El contador de esta guía no sustituye esa evidencia.

## Lectura visual

La cámara inicial se aproxima más; el botón Ver todo el asentamiento recupera el encuadre general. La selección táctil utiliza la misma transformación que el dibujo. Los rótulos de edificios utilizan las definiciones fijadas de cada mundo. El terreno local toma el bioma real de su celda; su textura y vegetación decorativa no representan inventarios adicionales.

Se retira la animación que atribuía una obra a cualquier artesana por su oficio: la existencia de una obra no acredita una asignación personal. Las tareas y recorridos locales confirmados, el arte definitivo por era/especie y las escenas de consecuencias siguen pendientes.

## Comprobación y límites

La evidencia de esta integración se conserva en `docs/validation/experience/`. Distingue análisis, pruebas, compilación y recorrido Android. La prueba Android utiliza un emulador por software, no acredita rendimiento del teléfono de referencia. Las partidas originales se apartan durante el recorrido y se restauran comprobando todos sus hashes.

No cambian el esquema, la migración, el controlador de sesión, los paquetes fijados ni el motor. Se conservan las simulaciones AOT congeladas de reglas 11 y su procedencia; las nuevas pantallas se verifican por separado. E1 continúa abierto hasta demostrar el recorrido inicial completo, y R11 conserva la aceptación final ampliada en E5.

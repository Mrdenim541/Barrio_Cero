# Iteración 0.12 — población y provisiones en tránsito

Reglas 11, checkpoint 3 y catálogo fijado 2.1.0. R6 continúa parcial: esta integración aborda el trayecto migratorio, no territorio, instituciones, secesiones ni toda la política del juego.

## Comportamiento

Una invitación positiva reserva adultos comunes reales del origen y provisiones pagadas por el receptor. El presupuesto visible suma el coste ordinario de la opción y alimento/agua para el camino actual más catorce días de contingencia. No aparecen habitantes nuevos por resolver la tarjeta. Varios efectos positivos de una opción forman un solo grupo, y las llegadas comprometidas reservan vivienda antes de alcanzar el destino.

La residencia temporal pertenece al registro de población, separada de ambos asentamientos. Conserva cumpleaños, cultura y especie. Los personajes destacados permanecen en sus comunidades: esta versión no traslada todavía familias completas ni dirigentes y no atribuye consentimiento personal desconocido. Los viajeros no trabajan en ciudades durante el recorrido. La comida del día de llegada se consume en el grupo, sin volver a cobrarla en el destino ese mismo día.

Cada día consume provisiones y recorre como máximo una celda. Un corte busca un desvío desde la posición actual; si no existe, espera allí y consume sus propias reservas. Un destino destruido, hostil, cerrado o sin capacidad provoca intento de regreso. Un regreso bloqueado también es un estado guardable. Treinta días consecutivos de raciones incompletas producen bajas reales del grupo; nunca se transforma una baja en llegada ni se repuebla automáticamente. Si sobreviven viajeros tras perderse todas las ciudades, el mundo todavía no se considera extinguido; un regreso real puede volver a habitar sus ruinas.

Al llegar se transfieren una sola vez los supervivientes y las provisiones restantes. Los viajes concluidos se conservan con población inicial, llegadas, bajas, consumo, entrega y pérdidas. El balance de cada viaje se valida. La historia de trayectos tiene un límite inicial de 10.000 registros; no se elimina silenciosamente para abrir espacio. El almacenamiento histórico por bloques de R10 sigue pendiente.

La interfaz muestra posición, estado, residentes, provisiones y pasos del recorrido actual, permite localizar al grupo en el mapa y consultar viajes concluidos por páginas. El marcador usa la celda confirmada, no un azar visual ni tiempo real. El informe de salto incluye población en tránsito para no contar una salida de ciudad como muerte global.

## Compatibilidad y orden diario

Las partidas anteriores mantienen sus reglas. La conversión conserva su original exacto y no inventa un recorrido para inmigraciones que ya finalizaron. El esquema del mundo continúa siendo la extensión versionada del esquema 1; la reorganización final de R3 no se considera terminada.

En reglas 11, todas las comunidades completan trabajo y economía antes del paso de viajeros; después se procesan las decisiones mensuales, demografía anual y consecuencias programadas. Así nadie omite ni duplica sus raciones por el orden entre ciudades. Una salida decidida después de comer comienza a viajar el día siguiente. Las reglas anteriores conservan su orden previo.

## Evidencia y fallos conservados

La variante inicial aprobó 185 pruebas cortas, pero las baterías largas encontraron validación narrativa anterior al paso diario del viaje. Se conservan los fallos, el hash de aquel APK y sus fuentes congeladas. La variante corregida mueve el paso de viajeros antes de la narrativa y añade una regresión determinista del cruce con el día 30, manteniendo la validación estricta de importaciones.

La batería corregida aprobó **187 pruebas**, con análisis limpio y APK profile recompilado. Comprueba consulta inmutable, coste, residencia temporal, conservación de habitantes, raciones de llegada, desvío, aislamiento, bajas, regreso bloqueado, reapertura, plazas reservadas y conversión sin historia inventada. Una prueba adicional del trabajador confirma un checkpoint a mitad del viaje y lo reinicia en otro aislado hasta la llegada, comparándolo con el avance continuo. La interfaz se prueba a 320 puntos y texto ampliado; las regresiones móviles anteriores siguen incluidas.

El primer ensayo de guardado comparó un mundo sin fijar con otro cuyo contenido ya estaba fijado por hash. Se corrigió el fixture para partir del mismo checkpoint, sin relajar la comparación del estado. El primer ensayo táctil intentaba pulsar contenido fuera del área visible; el acceso del viaje pasó a ocupar el lugar de la sugerencia genérica cuando hay residentes en camino.

Los resultados de Android, siglos equivalentes, opciones del catálogo, cargas de 32 y estabilidad se registran por variante y estado en `results.json`. Una ejecución iniciada o una captura de la variante anterior no acredita el APK corregido. Las mediciones Linux no acreditan rendimiento del teléfono Android 10/4 GB.

La variante corregida aprobó el recorrido Android completo: pago de 24,5 alimentos y 3,5 de agua; cinco residentes en tránsito; cierre y reapertura en el segundo día; llegada única en el sexto, con consumo y entrega del remanente equilibrados; reapertura posterior y restauración de originales por hash. Sus capturas están en `final-native/`. El ensayo de la variante inicial se conserva separado. El guion reproducible está en `android-scenario.py.txt`; se ejecuta desde la raíz, con herramientas Android activas, el fixture generado por `tool/build_migration_scenario.dart` y un `BARRIO_NATIVE_RUN_TAG` nuevo para proteger las evidencias y partidas anteriores.

Los dos orígenes aprobaron los 36.000 días equivalentes con el catálogo real. Las cargas de apertura y maduras sostuvieron al menos 32 comunidades durante todo el siglo en ambos mapas. La matriz de treinta semillas y dos milenios está en ejecución; sus casos terminados se registran sin declarar aprobada la batería completa.

## Pendientes

Territorio, instituciones y conflictos políticos; expediciones de familias y personajes destacados; colonización en tránsito; biología y especies alternativas; genealogía e herencia; eras; director declarativo completo; archivo histórico por bloques y ZIP; arte final y primera sesión completa. La conservación global de todos los flujos del mundo sigue pendiente aunque el balance de cada viaje se compruebe.

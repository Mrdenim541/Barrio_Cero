# Iteración 0.10 — autonomía, acceso y traslados con origen real

Reglas 9, catálogo 2.1.0 y checkpoint 3. Esta integración corrige decisiones del motor; no completa R6 ni las migraciones en tránsito.

## Correcciones

La investigación de la primera pérdida de población de reglas 8 está conservada en `../operating/first-loss.json`. Los acontecimientos invitaban habitantes escogiendo la primera comunidad por identificador. Podían dejar allí menores y mayores sin suficientes adultos, aunque la comunidad de origen no quisiera emigrar.

Ahora una invitación requiere motivos de salida, adultos comunes disponibles, reservas y vivienda en destino, paso terrestre seguro y capacidad de cuidado en origen. No puede trasladar dirigentes, especialistas u otros personajes destacados mediante ese efecto agregado. La selección prioriza necesidad, distancia e identificador estable. Una consulta no cambia materiales, población, historia o azar. La resolución vuelve a validar todo y un rechazo no cobra alimentos. El traslado conserva cumpleaños, cultura y población total. Sigue siendo inmediato: no se acredita aún transporte de migrantes, familias completas ni decisiones personales individuales.

La autonomía compara capacidad de alimento y agua con consumo y reservas. Puede reservar un proyecto urgente desde el primer día, pagando los mismos costes y trabajo que el jugador. No recibe pozos, materiales ni trabajadores gratuitos. Se comprueba explícitamente una apertura con agua insuficiente y sin recolector, en lugar de esperar un mes para descubrir la necesidad.

Las seis comunidades de las nuevas partidas se colocan en terreno viable de una misma componente terrestre. Se mantiene la separación mínima. No se modifica el terreno generado ni se consume azar adicional para conectar lugares. Sesenta aperturas (treinta semillas por origen, mapas 64/96 alternos) comprueban accesibilidad y terreno idéntico al generado con la misma semilla. Las posiciones guardadas no se regeneran al actualizar las reglas. El primer intento de preparar la prueba Android descubrió la falta de conexión; su fallo se conserva en `initial-no-connected-source.log`.

Las decisiones narrativas ya pendientes aparecen antes que las oportunidades generales. El diálogo de actualización puede desplazarse en pantallas pequeñas. Las partidas anteriores conservan sus reglas hasta una conversión explícita con copia exacta; no se alteran silenciosamente sus decisiones migratorias históricas.

## Evidencia y límites

La batería completa aprobó 166 pruebas y el análisis quedó limpio. Se compiló el APK profile 0.10.0+11. Instalación, funcionamiento, equivalencia temporal, estabilidad y carga sostenida se registran por separado en `results.json`; una batería en ejecución no cuenta como aprobada.

Las 307 opciones del catálogo aprobaron en fixtures de efectos. El primer intento falló porque el fixture antiguo carecía de un origen con motivos de salida. Se añadió esa condición inicial declarada para las tres invitaciones, sin saltar la validación del motor. Se conserva el fallo y la repetición. Esto no demuestra recorridos completos de los arcos, participantes de todos los eventos ni plazos declarativos: siguen pendientes de R8.

El escenario Android declara una enfermedad inicial en una comunidad naturalmente conectada y una petición pendiente. No se añaden personas, caminos ni suministros durante la sesión. Se distingue de una historia espontánea y de una prueba de balance. Su guion comprueba consulta, coste, transferencia única, conservación, cierre y reapertura, y restaura las partidas originales comparando todos sus hashes.

Las cargas de 32 conservan los programas y umbrales anteriores. La ubicación de los seis asentamientos iniciales cambia en las nuevas partidas por la corrección de generación; se comparan las mismas recetas de prueba, no estados iniciales idénticos. Los tiempos y RSS de Linux no acreditan FPS ni memoria del teléfono de referencia.

## Pendientes conservados

Migración con origen/tránsito/destino, territorio y ocupación, instituciones, conflicto político persistente, genealogía biológica y herencia, esquema final del mundo, equinos, seis eras funcionales, catálogo ampliado, director completamente instanciado, bloques históricos e intercambio ZIP, arte completo, primeras diez decisiones y aceptación de rendimiento Android. Ningún hito completo se cierra por esta integración.

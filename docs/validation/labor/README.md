# Iteración 0.11 — raciones y compromisos de trabajo

Reglas 10, catálogo 2.1.0, checkpoint 3. Conserva la mecánica anterior hasta una conversión explícita. No completa el juego ni R2, R6 o R12.

## Defecto reproducido y corrección

El seguimiento de la apertura de 32 comunidades de reglas 9 encontró la primera pérdida en el día 3.300: Puesto 28 tenía diez adultos y diez plazas comprometidas en caravanas, mientras el agua estaba a cero. La asignación diaria atendía primero las rutas y dejaba sin personal el pozo. Disponer de alimento y edificios no bastaba para sostener a sus habitantes.

Cuando las reservas de raciones bajan de catorce días, las reglas nuevas protegen el trabajo que la infraestructura y los insumos existentes pueden producir para cubrir necesidades. El resto del día se asigna a caravanas, expediciones, aprendizaje y obras con el presupuesto restante. Se cuentan las jornadas una sola vez. No se bloquea la construcción de un pozo inexistente reservando trabajo para una capacidad que todavía no existe.

El jugador conserva sus rutas: parte del transporte puede esperar sin perder compromiso, posición ni carga. Una sociedad autónoma también puede ordenar el regreso de rutas que ya no puede mantener. La orden usa el mismo cierre ordinario, prioriza retornos y conserva el trayecto. Si no hay personal para todos, los demás esperan; no se supone que todas las caravanas regresan simultáneamente. Al llegar se recuperan materiales y se libera el compromiso. No se añaden suministros de emergencia.

## Evidencia comprobada

- 170 pruebas completas, análisis limpio y validadores estructurales. El fallo anterior de agua cero se conserva, junto con el error inicial de compilación y una expectativa corregida del test de regreso: no todas las caravanas podían moverse a la vez con el personal disponible.
- Las regresiones comprueban raciones, personal compartido, ausencia de infraestructura, espera con carga, cierre físico, recuperación y conservación explícita de las reglas 9.
- Los dos orígenes alcanzan 36.000 días idénticos por cuatro caminos: días individuales, diez décadas, un siglo y guardado/reanudación irregular. Se compara el estado completo y la secuencia causal, incluido el historial ya podado. Prehistoria: 10.522 acontecimientos; reconstrucción: 19.237. Catálogo real de 166 eventos.
- APK profile 0.11.0+12 compilado, firma comprobada, instalado por actualización y ejecutado en el emulador Android API29.
- La prueba Android parte de una condición inicial declarada: ocho adultos, cuatro rutas pagadas, pozo operativo y agua almacenada agotada. La conversión preservó población, reservas, rutas, vínculos y PRNG, y conservó los bytes originales de reglas 9. Al avanzar un día, tres caravanas esperaron con su carga; seis jornadas productivas cubrieron la ración de 0,7 unidades de agua y la salud permaneció en 100. Consulta y reapertura exactas; todas las partidas originales restauradas por hash.

Las capturas proceden del APK ejecutado. El escenario es una regresión declarada, no una partida espontánea ni una demostración de balance universal. La animación y los mensajes temporales de UIAutomator no sustituyen las comprobaciones del guardado.

## Baterías largas

Las cargas de apertura y maduras usan las mismas recetas, umbrales y muestreo diario. Sus resultados se conservan en `results.json`, diferenciando escenarios terminados y en curso. El caso de apertura 64×64, que falló con reglas 9 al caer temporalmente a 31, alcanzó ahora todo el siglo con un mínimo de 32. No se extrapola esa aprobación a mapas o baterías que aún no han terminado.

La matriz de treinta semillas y dos milenios sigue identificada como en curso hasta obtener todos sus casos y el cierre del ejecutable. La matriz anterior completa de reglas 8 y la incompleta de reglas 9 mantienen su propia procedencia. Los tiempos y RSS de estos ejecutables corresponden a Linux compartido, no al teléfono Android 10/4 GB. FPS, latencia de controles, cancelación y memoria física de referencia siguen pendientes.

R2 conserva pendientes de conservación global y contratos; R6, tránsito migratorio, territorio e instituciones. Tampoco se cierran genealogía biológica, herencia, especies, eras, narrativa completa, historia por bloques, catálogo ampliado, arte final o las diez decisiones de primera sesión.

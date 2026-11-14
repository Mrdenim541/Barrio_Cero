# Iteración 0.6 — apertura prehistórica jugable

Reglas 5, checkpoint 3, catálogo base 2.1.0. R4 permanece parcial; esta evidencia no certifica el juego completo.

## Comportamiento integrado

La nueva partida propone **Prehistoria** por defecto y conserva **Reconstrucción** como otra apertura. La primera tiene 24 habitantes, refugios, dos zonas de recolección, agua superficial y un círculo de memoria. No empieza con metal, herramientas, medicinas, combustible o electricidad. La segunda conserva el asentamiento de 56 habitantes y sus recursos de recuperación. Son estados y economías diferentes, no etiquetas sobre la misma partida.

Los emplazamientos respetan biomas transitables, riqueza mínima y separación. La recolección y el agua tienen capacidad local limitada; un lugar inadecuado detiene su producción. La talla consume piedra y madera para producir herramientas; el trenzado consume fibras representadas por el recurso de madera. Un refugio terminado añade ocho plazas reales. La tradición oral modifica la transmisión del círculo de memoria. La autonomía adapta sus obras a los conocimientos y materiales disponibles.

Se añaden siete construcciones y dos conocimientos: **25 y 32** en total. No se consideran cumplidos los objetivos de 30 funciones constructivas y 48 tecnologías diferenciadas. El catálogo tiene **104 acontecimientos independientes**, 12 arcos y 16 plantillas: tampoco completa los objetivos de 144 acontecimientos y 16 arcos.

Ocho situaciones nuevas tienen contexto de apertura prehistórica. Una prueba financiada entrega sus herramientas catorce días después, con vínculo causal y resolución única. La escritura permite acceder a crónicas posteriores sin abandonar el origen prehistórico. Esto no completa las instancias, participantes, vencimientos o exclusiones de R8.

La interfaz prioriza acciones disponibles, muestra requisitos avanzados aparte y propone el refugio cuando falta espacio. Las tres primeras oportunidades aparecen antes del catálogo completo. Los atlas incorporan refugios, recolección, agua, talla, piedra superficial, memoria, trenzado y tres apariencias ancestrales. El motor de dibujo lee dimensiones e índices del manifiesto. El vestuario por todas las eras y especies sigue pendiente.

## Evidencia ejecutada

- **116 pruebas Flutter** aprobadas y análisis limpio, en ejecución secuencial. Se conserva también el fallo transitorio anterior de consulta de metadatos de Flutter; no contó como una batería aprobada.
- Treinta semillas comprueban **emplazamientos e inventarios iniciales**, alternando mapas 64/96. Esto no equivale a treinta semillas durante doscientos años.
- Supervivencia inicial, refugio persistente, fabricación real de herramientas, aprendizaje oral, restricciones del terreno, consecuencia aplazada y guardado/reanudación.
- Equivalencia completa de **36.000 días por cada origen**: días individuales, diez décadas, siglo y guardado irregular; 39.190 entradas causales en reconstrucción y 26.876 en prehistoria. Ejecutado con Dart AOT en Linux, no como medición de rendimiento Android. `temporal-inputs.json` conserva sus fuentes exactas.
- APK profile compilado e instalado por actualización. En Android API29, directorio de partidas aislado: apertura prehistórica por defecto, coste de ocho maderas y dos piedras, cuarenta jornadas reservadas, refugio terminado al avanzar un mes y reapertura exacta después de cerrar el proceso.
- Los cuatro archivos originales del emulador se restauraron y verificaron por longitud y SHA-256. El guion usó incorrectamente `run-as test`, inexistente en esta imagen Android, y anidó la carpeta original al restaurar. El control de integridad detectó el error; todos los originales seguían intactos y se devolvieron a su ruta correcta. Se conserva el registro del fallo y la corrección.

Las capturas `01`–`05` proceden del APK ejecutado. La cuarta muestra el cuarto refugio ya construido y la fecha alcanzada. No son modelos conceptuales ni representan el aspecto final de todas las eras.

## Pendientes que impiden cerrar el alcance

R2/R3 requieren todavía conservación global, conciliación poblacional completa y el modelo final. R4 deberá integrarse con esos contratos y con los criterios finales de aceptación. Faltan hogares y genealogías, ocupaciones completas, sociedades e instituciones avanzadas, territorio, transporte de migrantes, equinos, eras operativas y regresión, director narrativo completo, historia durable y los objetivos ampliados de contenido.

La captura aún muestra recomendaciones que necesitan seguir mejor el progreso posterior al primer refugio; el recorrido de diez decisiones y la revisión de comprensión pertenecen a R11. Los fallos nativos intermitentes del emulador en iteraciones anteriores siguen registrados. No se acredita estabilidad de un teléfono real, mil años activos ni el escenario sostenido de 32 asentamientos por estas pruebas.

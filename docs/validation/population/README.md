# Iteración 0.7 — población reconciliada y formación

Reglas 6, checkpoint 3, catálogo 2.1.0. Esta integración inicia R5 y amplía R2/R3; no cierra familias, eras ni el juego completo.

## Comportamiento

`PopulationLedger` conserva grupos por fecha de nacimiento, residencia, especie y cultura. Los personajes destacados son miembros de esos grupos: destacarlos no añade habitantes. Los cumpleaños cambian de banda en fechas exactas; las bajas retiran también las identidades afectadas y conservan su procedencia. La sucesión elige un adulto que ya existía. Los traslados mantienen edades, culturas e identidades sin duplicar población. Los recién llegados no vuelven a producir en el mismo día en el destino.

La conversión es opcional, mantiene el ejecutor anterior y conserva una copia exacta de la partida. Las fechas conocidas se mantienen; las edades de la población común se estiman explícitamente al convertir. No se reconstruyen familias desconocidas. Un grupo o una persona incompatible impide confirmar el candidato. Los fallecidos conocidos conservan cultura, residencia y fecha en el archivo poblacional.

Los aprendices proceden de residentes reales. Maestro y aprendiz reservan dos trabajadores durante noventa días; sin maestro, solo una escuela con escritura y conocimientos especializados permite estudiar durante ciento ochenta días. Se pagan provisiones y conocimiento. El progreso se guarda. Cancelar, migrar, retirarse o morir interrumpe la formación y devuelve únicamente las provisiones no utilizadas; no borra la competencia adquirida. Un maestro reservado no dirige simultáneamente una expedición. La exploración sin especialista requiere doce días en vez de ocho; los oficios de fabricación reducen sus insumos manteniendo el rendimiento. El gobierno autónomo puede formar relevo cuando su único especialista envejece y hay reservas suficientes.

La interfaz muestra formación, costes, duración, aprendices en curso y cancelación. La ficha personal identifica cultura, competencias explícitas y fecha estimada cuando corresponde. La recomendación prehistórica cambia después de resolver el problema de vivienda.

## Evidencias

Los registros definitivos y su alcance se enumeran en `results.json`. Las fuentes del ejecutable AOT y del APK están identificadas en `inputs.json`. Los registros de pruebas y Android distinguen intentos fallidos de repeticiones aprobadas.

La equivalencia de cien años usa el catálogo real en ambos orígenes: 36.000 días individuales, diez décadas, un siglo y lotes irregulares con serialización. Compara el estado canónico y la secuencia causal completa, incluidas las entradas retiradas de la crónica visible. No equivale a rendimiento Android ni a la batería completa de aceptación.

La prueba Android aísla el directorio de partidas y conserva los originales. Verifica coste sin efectos al consultar, población reconciliada, trabajo de formación y reapertura. Su resultado solo se considera aprobado si también se restauran y verifican todos los archivos originales.

## Límites que siguen abiertos

- No hay todavía hogares, parentescos, vínculos personales, herencia o adopción. La población común puede reproducirse sin genealogía individual; los destacados no reciben descendientes inventados.
- Los traslados conservan población pero aún son instantáneos: faltan tránsito, provisiones y rutas para migrantes. Comercio y expediciones tienen sus mecanismos propios.
- El registro admite humanos; la biología equina y los límites reproductivos por especie corresponden a R7. La edad máxima humana de seguridad es 120 años; no es una garantía de longevidad.
- Las asignaciones productivas siguen agregadas. Falta la ocupación completa por necesidad y lugar, conservación material global y capacidades naturales agotables.
- La narrativa anterior todavía admite textos con nombres fijos y necesita instancias con participantes. No se afirma que la reconciliación poblacional cierre R8.
- La crónica sigue siendo una ventana con poda; los bloques históricos íntegros y sus manifiestos pertenecen a R10.
- La matriz larga nueva se registra aparte. La batería 0.6 no valida estas reglas. Mil años con población activa, 32 asentamientos sostenidos y rendimiento en teléfono real siguen pendientes.

## Resultado Android

Instalación por actualización y recorrido aprobados en API29 profile: 336 habitantes entre seis ciudades, nuevo aprendiz sin incremento poblacional, coste efectivo de 10 alimentos y 5 conocimientos, 180 jornadas reservadas, finalización en el día 90 y reapertura con población y habilidad conservadas. Los cuatro originales se restauraron con hashes exactos. El primer intento falló en el selector de origen del guion antes de crear partida; se corrigió y repitió. Los avisos transitorios de UIAutomator también se conservan. No equivale a instalación limpia ni rendimiento físico.

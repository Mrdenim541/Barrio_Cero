# Iteración 0.8 — hogares, vínculos y cuidado

Reglas 7, checkpoint 3, catálogo 2.1.0. R5 permanece parcial. Esta iteración no completa biología, descendencia conocida, herencia ni todo el diseño social.

## Comportamiento integrado

Los habitantes destacados pueden conocerse mediante contacto mensual, desarrollar amistad, confianza, rivalidad y afecto, y solicitar un hogar compartido. Un romance requiere adultos con voluntad mutua; ayudar con la vivienda no establece sentimientos. Se excluyen vínculos románticos entre tutores, personas a su cargo y familiares con tutela documentada compartida.

La petición tiene participantes concretos, comunidad, fecha y vencimiento. Financiación y rechazo pasan por las transacciones del motor. Ayudar consume cuatro maderas y seis alimentos, conserva población y registra el hogar. El gobierno autónomo debe pagar las mismas provisiones y mantener reservas. Las relaciones personales no se generan al abrir su pantalla.

Un adulto con hogar puede asumir cuidado documentado sobre un menor que ya pertenece a los grupos del asentamiento. Destacarlo no crea habitantes ni cambia su cumpleaños. La tutela queda diferenciada del parentesco biológico desconocido. El menor conserva cultura, grupo y residencia; al alcanzar dieciocho años cambia su condición y puede iniciar formación propia. La escena lo representa a menor escala mientras es infantil.

Los hogares conservan sus antiguos miembros después de muerte, traslado o separación. Las pérdidas y distancias generan recuerdos persistentes; una baja no elimina la historia familiar. La validación distingue estar vivo ahora de haber actuado antes de morir durante el mismo día. Una petición aceptada necesita un hogar correspondiente, las identidades no se reutilizan y una residencia activa no puede duplicarse.

La interfaz muestra la petición en Barrio y permite revisar hogares, vínculos, antiguos miembros y tutelas. El escenario nativo se obtiene avanzando con las reglas normales desde la semilla 31 y la apertura prehistórica: primera petición financiable en el día 120. `tool/build_family_scenario.dart` no inyecta recursos, personas, sentimientos ni parentescos.

## Evidencia y alcance

- La batería completa final tiene **147 pruebas aprobadas**. Incluye coste y consulta inmutable, idempotencia, tutela sin duplicación, vencimiento, pérdidas y recuperación. La comprobación de dos años compara contacto mensual y guardado/reanudación.
- Se repitieron las pantallas y el recorrido de formación después de añadir acceso a hogares; 320/360/412 y texto ampliado siguen cubiertos por las pruebas existentes.
- Compilación profile y firma se acreditan por separado de instalación y funcionamiento. Los resultados definitivos de Android y de equivalencia temporal están en `results.json` cuando terminan.
- Los fallos del guion se conservan como tales; no cuentan como pruebas aprobadas. El primer guion nativo no llegó a ejecutarse por un error al componer su archivo Python.

## Pendientes

No hay todavía genealogía biológica conocida, nacimientos individualizados de parejas, adopción formal diferenciada de tutela, patrimonios, herencia material o sucesión institucional completa. El consentimiento y los objetivos personales necesitan mayor profundidad; faltan infidelidad, reconciliaciones desarrolladas y cadenas entre comunidades. Los hogares son unidades sociales con comunidad de residencia: aún no se asigna cada uno a una vivienda concreta.

El procesamiento social tiene reglas versionadas en el núcleo; su integración con el director y el contenido declarativo general sigue pendiente de R8. El resto del catálogo conserva las limitaciones documentadas sobre participantes y textos iniciales. Los recuerdos familiares se serializan completos, pero faltan los bloques históricos e intercambio por streaming de R10.

No se presenta esta iteración como aceptación de treinta semillas para todas las reglas nuevas, milenios activos, 32 asentamientos sostenidos o rendimiento de un teléfono físico. Cada batería conserva su propia versión y resultado.

## Diagnóstico de carga madura

También falló el escenario maduro declarado: quedó en mínimos de 21/20 comunidades en mapas 64/96, pese a conservar al menos 1.792 habitantes totales. No hubo inyecciones durante la ejecución; se fijaron reservas iniciales, tecnologías con prerrequisitos completos y rutas iniciales pagadas. Se conserva el programa exacto compilado en `mature-benchmark-source.dart.txt` (la versión de trabajo solo recibió correcciones de llaves del linter). No se rebaja el mínimo exigido de 32 ni se acredita rendimiento físico. La corrección posterior del reparto de trabajo debe volver a probar estos mismos escenarios.

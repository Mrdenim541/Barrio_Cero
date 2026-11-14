# Guía de contenido — BARRIO CERO: ERAS

El contenido es original, local y en español. El mundo reconstruye instituciones entre ruinas; la ficción no presenta intervención genética acelerada como evolución natural. Una noticia distingue observación, explicación conocida e hipótesis. Las pérdidas no se borran cuando cambia el gobierno. No hay llamadas a servicios de lenguaje ni descargas durante el juego.

## Catálogo e inventario

`assets/content/core.json` contiene 12 recursos, 6 biomas, 18 edificios, 30 tecnologías en grafo, 12 rasgos, 6 perfiles, Ana/Leo/Tito, 96 situaciones independientes en ocho categorías, 12 arcos con 62 nodos adicionales, 16 plantillas y ocho familias extraordinarias. Las clasificaciones no se cuentan como eventos extra. Los arcos tienen entre cinco y siete nodos; todas sus terminaciones son alcanzables y tienen efectos diferentes. `CONTENT_INVENTORY.md` enumera identificadores, condiciones, efectos y enlaces.

La instalación admite sellado (entorno), desmontaje (materiales), acceso compartido (relaciones/conocimiento) y estudio (energía o señal). La señal no obliga a una invasión. Cada familia extraordinaria se filtra mediante las opciones del mundo; el texto de un evento no debe saltarse esa habilitación.

## Estructura y operaciones

Cada evento tiene `id` estable, categoría, título, cuerpo, condiciones, participantes, localización, probabilidad base, modificadores condicionados, fecha límite, repetibilidad, espera y grupo de exclusión. `trigger: director` permite selección contextual; `scheduled` identifica una consecuencia que solo entra por una decisión anterior. No se deben seleccionar ramas intermedias como noticias espontáneas.

Las opciones incluyen `costs` por recurso, `effects` tipados y `followUps` con id, días y probabilidad. Se validan los costes antes de aplicar los efectos; una opción sin fondos no se transforma silenciosamente en una decisión gratuita. El motor debe revalidar la comunidad y las condiciones cuando vence una consecuencia. `exclusionGroup` evita iniciar dos veces el mismo arco; sus ramas programadas conservan acceso a sus siguientes nodos.

Vocabulario de efectos: `resource`, `population`, `health`, `morale`, `environment`, `relation`, `housing`, `defense`, `flag`, `technology`, `schedule`. Los deltas de recursos especifican `resource` y `value`; los demás indicadores usan `value`. Las banderas son identificadores de memoria persistente. Los eventos no contienen código ejecutable, expresiones de script ni rutas de archivos.

Las condiciones incluyen `resource_min`, `resource_max`, `minDay`, límites de población/salud/moral/vivienda/relaciones y listas `flags`. Las tecnologías tienen requisitos AND; las rutas alternativas nacen de ramas independientes del grafo que se pueden combinar. Las plantillas declaran un entero acotado y costes/efectos lineales `base + perUnit * parámetro`. No se cuentan como dieciséis eventos hechos con renombrados.

## Paquetes y partidas

`manifest.json` registra id, versión y SHA-256 de los bytes UTF-8 exactos. `example_pack.json` es un paquete de ejemplo que depende de `barrio.core@1.0.0` y agrega un encuentro de señalización de caminos. `lib/content/content_pack.dart` valida tamaño máximo (2 MB), ids únicos, referencias, costes, operaciones permitidas y ciclos tecnológicos. Rechaza versiones con los mismos id/versión y distintos bytes.

`ContentRegistry` compone una lista exacta de pins `{id, version, sha256}`. Importar no cambia los pins de mundos existentes. Una migración explícita debe comprobar las definiciones de todos los acontecimientos pendientes mediante `prepareMigration` y persistir estado y pins juntos. No retire una versión requerida por una partida guardada. Un hash verifica identidad; no convierte un paquete desconocido en contenido de confianza.

## Autoría y comprobaciones

La fuente editable es `tool/build_content.py`, con situaciones redactadas una por una, reglas y arcos. Para regenerar y comprobar:

```sh
python3 tool/build_content.py
python3 tool/validate_content.py
```

El validador verifica mínimos, ocho categorías independientes, ocho familias, referencias, DAG, alcance de arcos, firmas mecánicas de desenlaces, hashes y diez casos negativos (operación prohibida, ciclo, referencia ausente, coste negativo, id duplicado, condición desconocida, programación inválida y banderas mal formadas). Estas son comprobaciones del catálogo; no sustituyen ejecutar las decisiones en la simulación ni la prueba de interfaz.

Al añadir un arco: redacte su tensión, defina costes materiales, agregue una rama de compromiso y otra divergente, programe al menos dos finales con huellas mecánicas distintas y pruebe ambos con una semilla conocida. La crónica debe enlazar al id de la decisión anterior y registrar una cancelación si una guerra, muerte o destrucción vuelve inválida la consecuencia.

## Fuente de la apertura 0.6

`content/catalog.json` gobierna las definiciones ejecutables; `content/scenarios.json` declara las dos aperturas. `python3 tool/generate_catalog.py` genera la copia de arranque y `--check` detecta divergencias. `python3 tool/build_content.py` produce el paquete 2.1.0 y el inventario. `originCapabilities` condiciona un acontecimiento a capacidades según el origen; el ejecutor valida y aplica sus listas. La prehistoria no queda excluida para siempre de crónicas posteriores. Las partidas fijan sus fuentes exactas y los ejecutores antiguos conservan sus tablas.

Hay 25 construcciones, 32 conocimientos y 104 sucesos independientes: estos conteos no acreditan diferenciación mecánica completa ni cumplen aún los objetivos ampliados. Validación: `docs/validation/prehistory/`.

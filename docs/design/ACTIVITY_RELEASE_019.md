# Actividad visible y descarga reducida — 0.19

Este avance continúa el atlas original de 0.18. No cambia las reglas 11, los paquetes fijados ni el formato de las partidas.

- El rótulo PLANETA/REGIÓN/ASENTAMIENTO abre las tres escalas de la misma cámara. Explorar pausa el seguimiento de cámara, no la autonomía.
- Una señal de herramienta identifica producción contabilizada en un edificio único de ese tipo. Solo pulsa al recibir otra jornada confirmada; en pausa permanece estática. Si hay varios edificios iguales, la asignación permanece agregada: el registro actual no permite atribuirla a una parcela concreta.
- La ficha de comunidad abre Actividad: producción del último día, trabajo colectivo y progreso real de obras y formación, incluidas pausas. No crea trabajadores ni órdenes. Las cifras productivas antiguas o de comunidades extinguidas no se muestran como actividad actual.
- Las caravanas usan su ruta, posición y carga confirmadas para mostrar una carreta; no se inventan animales de tiro ni entregas.
- Tocar una noticia con comunidad conocida centra su región.
- Se distribuye una compilación release optimizada dentro de ZIP, firmada con la misma clave de pruebas. El APK universal incluye ARM32, ARM64 y x86_64 para conservar la compatibilidad.

## Alcance pendiente

M3 queda **en curso**: aún faltan asignaciones personales completas, recorridos locales y reservas de parcelas para obras. Este cambio presenta contabilidad existente, no completa esos sistemas. El mundo 2/checkpoint 4, política ampliada, seis eras funcionales, equinos, narrativa ampliada, inmortalidad y aceptación física siguen en los hitos acordados. Ningún requisito final se cierra por contar iconos o compilar el APK.

## Verificación proporcional

Las pruebas focalizadas comprueban conservación del trabajo representado, ausencia de mutación, exclusión de datos antiguos, ambigüedad entre parcelas y progreso de compromisos. La integración ejecuta análisis, suite Flutter, validadores y una compilación release. La prueba Android usa el APK exacto de entrega y un mundo tras un año autónomo; conserva y restaura todos los guardados originales. No se repiten baterías seculares porque no cambian las reglas.

Compilación, instalación, funcionamiento y descarga se registran por separado en `docs/validation/activity/`. Las capturas son del paquete ejecutado; el emulador por software no acredita rendimiento del teléfono de referencia.

# Escena local ejecutada — 0.2.1

R1 continúa parcial. Esta iteración mejora la composición, la escala y la interacción de la escena local. Conserva los atlas originales; todavía faltan el arte de las eras/especies, la simulación de caminos, las familias y los demás sistemas de la ampliación.

Los mundos nuevos usan `siteLayout: 2`: los primeros edificios forman pequeños sectores y el resto busca huecos sin solapar huellas de 2×2. La capacidad sigue siendo 196 edificios. Las partidas sin ese campo siguen usando versión 1, preservan su serialización y sus posiciones futuras; no se redistribuyen silenciosamente. Se rechazan versiones desconocidas y solapes en los planos nuevos. Este campo no constituye el futuro modelo world2/content2/checkpoint3 de R3.

La cámara, el dibujo y la selección comparten una geometría. Solo aparecen edificios confirmados y habitantes destacados vivos; tocar abre información y acciones reales. Las posiciones de las figuras junto a los edificios son representación visual, no reservas de empleo ni rutas simuladas. El terreno texturado, las sombras y las entradas desgastadas son presentación; no se declaran transporte o caminos funcionales. No se inventan habitantes adicionales ni recorridos por azar.

La batería completa pasó 67 pruebas. Las once pruebas focalizadas de interfaz/escena pasaron antes de la última validación adicional de planos; incluyen selección mediante gestos, conservación de estado, compatibilidad antigua y texto ampliado. El análisis final está limpio. Consulte `results.json` y los registros para el resultado temporal y las comprobaciones Android finales.

El APK profile fue instalado por actualización. Se creó una partida nueva en el tercer espacio; la referencia del primer espacio mantiene su SHA-256 exacto. Las capturas 10–13 proceden del APK ejecutado en Android 10/API29, a 320 puntos de ancho. Las capturas 10 y 11 muestran dos iteraciones de la misma escena; 11 corresponde a la versión final compacta.

En el emulador por software, Vulkan dejó el arranque en blanco y UIAutomator devolvió raíces nulas. Reiniciar la actividad con `--ez enable-impeller false` permitió ejecutar y capturar la escena mediante GLES. Esto se registra como limitación de la prueba; no acredita compatibilidad de todos los dispositivos ni rendimiento del teléfono de referencia. La primera comprobación automatizada de selección falló por buscar solo `text` cuando Flutter expuso la etiqueta como `content-desc`; se conservan el fallo y la repetición focalizada corregida.

La corrección final de herencia de planos se probó en un escenario preparado para permitir una colonia real en la transición anual. Pasaron cinco pruebas focalizadas después de la batería completa de 67. El primer fixture no producía ninguna colonia y fue corregido antes de aceptar la prueba; no se cuenta como cobertura una comprobación sin colonias. Las capturas de selección corresponden al APK anterior a esa corrección; `results.json` distingue su hash del APK final, cuyo cambio afecta a colonias de versión 1.

## Arranque final repetido

El APK final sufrió un SIGSEGV nativo en el hilo de rasterizado del emulador. Se conservaron los registros, se reinició el emulador manteniendo sus datos y se apartó un bloqueo de instancia obsoleto que refería al proceso ya cerrado. En el arranque limpio Android mostró un ANR de System UI; se cerró ese diálogo del sistema y se pudo cargar el tercer espacio y capturar otra vez la escena con el APK final y el backend predeterminado. La captura 11 se actualizó con esa ejecución final. Esta repetición acredita ese recorrido; no demuestra que todos los dispositivos estén libres de fallos gráficos.

La prueba temporal focalizada terminó aprobada: semilla 17, catálogo real de 158 eventos, 36.000 días individuales, décadas, siglo completo y guardado/reanudación tienen el mismo estado canónico y la misma secuencia de 50.518 acontecimientos. Es un solo grupo, no la aceptación completa ni las treinta semillas.

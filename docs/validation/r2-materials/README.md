# R2 — componente de materiales

Componente independiente para el futuro motor: cantidades enteras en milésimas, transferencias atómicas de varios recursos, reservas mediante cuentas, devolución, consumos con destino explícito, idempotencia y recuperación por reproducción del historial. El saldo de cada recurso debe cuadrar entre cuentas; un saldo alterado o un recibo fabricado se rechaza incluso si el total aparente permanece equilibrado. Se comprueban rango y desbordamiento antes de multiplicar cantidades.

Pasaron cinco pruebas de comportamiento y análisis limpio. No se conecta todavía a la economía activa, que continúa usando el ejecutor anterior. No convierte guardados ni cambia sus cantidades. No acredita precisión fija de toda la simulación, restos demográficos, conservación global de población/materiales o estabilidad de mil años.

La integración requiere el modelo de entidades y las transacciones de órdenes, la clasificación de fuentes y pérdidas, reservas de trabajo y el almacenamiento de historia por bloques. La recuperación actual tiene límites explícitos de tamaño; no descarta recibos para poder cargarse. R2 permanece en desarrollo.

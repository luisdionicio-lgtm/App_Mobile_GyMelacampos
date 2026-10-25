# Validación de la versión 1.1.0

25 de octubre de 2026.

- Análisis Flutter sin incidencias.
- Ocho pruebas Flutter aprobadas: medidas y serialización, pantalla de acceso, PDF, persistencia de apariencia/favoritos, contraste, sesión sin conexión y revocación, aislamiento de demo y HTTPS externo.
- Prueba de integración aprobada en Motorola Edge 50 Fusion, Android 16/API 36: navegación, tema oscuro, acento azul, favorito, medidas, bosquejo y proforma. Las preferencias y datos locales de demo originales se restauran al terminar.
- Capturas de las pantallas claras y oscuras revisadas desde el dispositivo.
- Claves locales auditadas contra los archivos preparados para Git: sin coincidencias.
- La clave de OpenAI suministrada se guardó únicamente en el backend local y respondió HTTP 401 al consultar el modelo. No se confirmó generación real de imágenes ni se consumió una generación de pago.
- El mismo Docker conserva PostgreSQL, RabbitMQ, backend, cotizaciones y web. La app utiliza el puerto local por USB; no se abrieron puertos a la red.
- Código iOS incluido; no se afirma instalación Apple desde Windows.

La instalación Android es interna y usa firma de desarrollo. Se requiere firma de producción para publicar en una tienda.

## Administración de trabajadores

- Doce pruebas backend aprobadas, ampliadas con edición de nombre, rechazo de cambios sin permiso, restablecimiento de contraseña y revocación de sesiones tras bloqueo/reactivación.
- Compilación de producción de la web y validación Compose aprobadas; backend y frontend reconstruidos en Docker conservando los volúmenes.
- Dos cuentas móviles creadas por solicitud del propietario: Medición móvil y Cotización móvil. Inicio de sesión, identidad, consulta de visitas y cálculo compartido verificados por HTTP contra Docker. Acceso administrativo rechazado para ambas.
- No se crearon clientes ni visitas ficticios durante la validación operativa. Las credenciales quedaron en un archivo privado local excluido de Git.

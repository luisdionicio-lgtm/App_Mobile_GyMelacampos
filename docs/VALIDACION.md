# Verificación de entrega

Fecha: 25 de octubre de 2026.

- Flutter 3.35.3 / Dart 3.9.2; análisis estático sin incidencias.
- Tres pruebas Flutter: medidas/cantidades y serialización, acceso controlado y creación de PDF con varias piezas sin tarifa.
- Doce pruebas del backend: comportamiento existente, permisos móviles, aislamiento, bloqueo inmediato, idempotencia, vínculos con cliente/cotización y tarifas reales.
- Compilación web de producción y validación de Docker Compose correctas.
- API Docker verificada por HTTP: salud, trabajadores, visitas e identidad móvil respondieron 200 con sesión administrativa.
- APK Android debug y release compilados. Versión release interna (54.6 MB) instalada por USB en Motorola Edge 50 Fusion, Android 16/API 36.
- Prueba automatizada completa aprobada en el Motorola: acceso a demo, visita, medidas, catálogo real de Cuarzo, bosquejo y proforma. Código en `integration_test/app_test.dart`; requiere el teléfono desbloqueado y Docker activo.
- No se crearon trabajadores, clientes ni visitas de prueba en PostgreSQL. Las pruebas comerciales usan SQLite en memoria; la demo móvil es local.
- La clave OpenAI existente respondió 401 `invalid_api_key`. No se confirmó generación IA real. Es necesario reemplazar la clave y contar con acceso/cuota.
- Proyecto iOS incluido con iconos de G&M. No compilado ni instalado desde Windows; requiere Mac/Xcode y firma Apple.

Los APK internos usan firma de desarrollo. No equivalen a una publicación en Play Store o App Store.


# Instrucciones del proyecto

Leer README.md e integration/README.md antes de editar. Flutter 3.35.3 / Dart 3.9.2 es la versión validada localmente. Usar pubspec.lock. Mantener las capas core, features/visits/domain, data y presentation.

La web es la autoridad administrativa; compartir API y PostgreSQL existentes. No añadir registro público de trabajadores. Comprobar roles en el servidor, nunca solo en widgets. No incluir credenciales ni claves en código, argumentos de compilación o Git. Conservar identidad, logo y recursos de G&M.

Medidas ingresadas por formulario; no implementar medición por cámara sin nueva solicitud. El bosquejo debe representar las medidas, y la imagen IA debe identificarse como conceptual. No inventar tarifas ni mezclar demo con datos reales.

Verificar flutter analyze, flutter test y compilación Android después de cambios relevantes. La prueba de dispositivo se ejecuta con flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d ID. Para backend: las pruebas del parche usan SQLite en memoria; nunca crear pruebas de negocio en PostgreSQL real.

No usar docker compose down --volumes. No publicar secretos ni archivos de la tesis. El APK distribuido en esta fase es de desarrollo; la firma comercial de Android y Apple debe configurarse antes de publicación.

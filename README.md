# G&M Campo

Aplicación Flutter para visitas técnicas de G&M Melacampos, conectada al mismo backend y PostgreSQL que la web de `D:\GyMelacampos`.

## Versión 1.1

- Navegación con Inicio, Visitas, Materiales y Cuenta; gestos horizontales y transiciones breves.
- Tema claro, oscuro o del sistema; acentos Dorado, Azul y Verde persistentes.
- Ajuste para reducir animaciones y compatibilidad con la accesibilidad del teléfono.
- Visitas con búsqueda y filtros de estado; borradores con guardado automático.
- Catálogo visual con favoritos persistentes y detalle de material para iniciar una visita.
- Indicador de conexión y comprobación automática al volver a la app y cada 20 segundos en primer plano.
- Se conserva la identidad local al arrancar sin servidor; una sesión vencida se revoca al comprobarla con el backend.
- Ayuda de conexión, privacidad y cierre de sesión local incluso si Docker está apagado.

## Flujo

1. El administrador crea una cuenta en `http://localhost:8080/admin/equipo-movil` y asigna Medición, Cotización o Instalación.
2. El trabajador ingresa con esa cuenta. El botón Demo abre un entorno local claramente identificado; no crea registros reales.
3. Registra cliente, teléfono, dirección y ambiente (baño, cocina u otro).
4. Ingresa piezas rectangulares: largo y ancho en **metros**, espesor en **centímetros** y cantidad. No mide con cámara, por aclaración del propietario.
5. Elige un material del catálogo real y la unidad de cotización. Genera bosquejo con cotas, proforma y PDF compartible.
6. Envía la visita para revisión web; se registra también la solicitud en Cotizaciones y el cliente prospecto usando el flujo idempotente existente. Puede adjuntar una fotografía. El administrador valida u observa y puede asignarla a otro trabajador.
7. Genera opcionalmente una imagen conceptual con IA. Se usa la clave de OpenAI del backend; nunca se incorpora en el APK ni en Git.

## Ejecutar en Android por USB

```powershell
cd D:\GyMelacampos
docker compose up -d --wait
cd D:\App_Mobile_GyMelacampos_
.\scripts\conectar-celular.ps1
flutter pub get
flutter run -d ZY22LJ23MF
```

La app usa `http://127.0.0.1:8080`. `adb reverse tcp:8080 tcp:8080` conecta ese puerto del teléfono con Docker en el equipo. En este equipo se activó el asistente local de Windows que restablece el enlace al reconectar el Motorola. Para activarlo en otra instalación: `./scripts/activar-conexion-automatica.ps1`; para detenerlo y quitarlo del inicio: `./scripts/desactivar-conexion-automatica.ps1`. Revisa el enlace cada 12 segundos y solo actúa sobre este dispositivo y el puerto 8080. Si no utilizas el asistente, vuelve a ejecutar el script de conexión tras reiniciar o reconectar. Para otro servidor usa Configurar conexión en el inicio de sesión o `--dart-define=API_BASE_URL=https://servidor` al compilar. Fuera del enlace USB, configura un backend alcanzable con HTTPS; la app rechaza direcciones HTTP externas para proteger la sesión. Localhost del teléfono no es el equipo. La instalación es permanente: no necesita Flutter ejecutándose para abrirse. Docker y USB siguen siendo necesarios para acceder al servidor local.

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

El APK interno optimizado está en `build/app/outputs/flutter-apk/app-release.apk` (`flutter build apk --release`). Se firma con la clave de depuración para la prueba local. El modo debug también está disponible en `build/app/outputs/flutter-apk/app-debug.apk`. Una distribución comercial requiere firma propia y HTTPS.

## iPhone

Se incluye el proyecto iOS y los permisos de cámara/galería. Compilar y firmar en un Mac con Xcode y la cuenta Apple correspondiente:

```sh
flutter pub get
flutter build ios --no-codesign
```

Configurar el servidor HTTPS accesible desde el iPhone. Esta entrega se valida en Android; no se afirma una compilación ni instalación iOS desde Windows.

## Backend compartido y roles

No se crea otra base de datos ni otro Docker. `integration/web/` contiene las fuentes que amplían el proyecto web; consultar `integration/README.md`. Los volúmenes existentes se mantienen. Las cuentas administrativas anteriores conservan su rol; las cuentas nuevas solo pueden ser creadas por un administrador. No hay registro público.

- **Administrador:** gestiona trabajadores, roles, bloqueo, restablecimiento de contraseña y revisión/asignación de visitas.
- **Medición y Cotización:** registran sus propias visitas, calculan propuestas y solicitan imágenes.
- **Instalación:** consulta visitas propias o asignadas; no crea propuestas ni genera imágenes.
- Los permisos se comprueban en cada petición contra la base de datos. Bloquear un usuario invalida el acceso de sus sesiones abiertas.

Los borradores y la cookie de sesión se almacenan mediante almacenamiento seguro del sistema. Los borradores se separan por servidor y usuario. Las fotos se copian al almacenamiento privado de la aplicación. El catálogo se puede consultar desde caché textual; las imágenes requieren red. El borrador se guarda automáticamente después de editarlo y sobrevive al cierre; enviar o calcular precios reales requiere conexión. La demo también conserva sus borradores en un espacio local separado. No hay sincronización automática en segundo plano.

## Cálculos y límites

Área neta = suma de largo × ancho × cantidad. ML = suma de largo × cantidad. No se convierte una unidad en otra. La tarifa de Granito es S/450 por ML, con armado e instalación incluidos, conforme al backend existente. Para m² se usa el precio configurado del material. Cuarzo y otros materiales sin tarifa muestran **Por evaluar**, sin inventar importes.

El bosquejo representa rectángulos independientes, no un levantamiento automático de habitación ni optimización de planchas. No descuenta huecos, añade merma ni calcula despiece industrial. Las notas recogen encuentros, cortes y acabados para revisión. Antes de fabricar se requiere validación técnica.

La imagen IA usa ambiente, nombre del material y medidas como referencia semántica. No reproduce garantizadamente la veta exacta, no edita la foto del cliente ni garantiza dimensiones geométricas. El bosquejo es la referencia dimensional. La foto es evidencia administrativa.

`OPENAI_API_KEY` se configura únicamente en `.env` del proyecto web. Se usa Images API y `OPENAI_IMAGE_MODEL` (predeterminado `gpt-image-1`). Si se desea otro modelo, añadir esa variable al entorno Compose del backend. Tras cambiar `.env`: `docker compose up -d --force-recreate backend`. La clave proporcionada para esta actualización se guardó solo en el `.env` local y también respondió HTTP 401 durante la verificación; la generación real está pendiente de una clave válida con acceso y cuota. No se gastó una generación durante las pruebas.

## Arquitectura

- `lib/core/`: transporte API, sesión y tema de marca.
- `lib/features/auth/`: acceso controlado.
- `lib/features/visits/domain/`: modelo de piezas y medidas, sin dependencias de transporte.
- `lib/features/visits/data/`: repositorio de borradores y API de visitas.
- `lib/features/visits/presentation/`: formulario, bosquejo y proforma PDF.
- `android/`, `ios/`: proyectos nativos Flutter.
- `integration/web/`: extensión de API y panel administrativo por capas del proyecto existente.
- `test/`: unidades, contrato del borrador, acceso y PDF.

Identidad adaptada del componente Logo.tsx de la web: monograma G rojo, &M azul y Melacampos. Fuentes DM Sans y Playfair Display con licencias OFL incluidas. La textura de portada procede de los recursos originales de G&M.


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

1. El administrador crea una cuenta en `http://localhost:8080/admin/equipo-movil` y asigna Medición y cotización o Instalación. Las cuentas anteriores de Cotización conservan acceso a ambas funciones.
2. El trabajador ingresa con esa cuenta. El botón Demo abre un entorno local claramente identificado; no crea registros reales.
3. Registra cliente, teléfono, dirección y ambiente (baño, cocina u otro).
4. Ingresa piezas rectangulares: largo y ancho en **metros**, espesor en **centímetros** y cantidad. No mide con cámara, por aclaración del propietario.
5. Elige un material del catálogo real y la unidad de cotización. Genera una propuesta PDF única con cotización y bosquejos acotados; el fondo de las piezas usa la imagen del material seleccionado.
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

## iPhone en esta Mac

El proyecto iOS usa Xcode, CocoaPods y Flutter 3.35.3. El iPhone físico debe estar enlazado con la Mac, tener el modo desarrollador activo y confiar en el perfil de desarrollo desde **Ajustes > General > VPN y gestión de dispositivos**. Xcode debe tener iniciada la cuenta Apple del equipo configurado en `ios/Runner.xcodeproj`.

La app usa el mismo servidor Docker de la web. En la carpeta hermana `MELACAMPOS_WEB`, configura `LAN_HOME_HOST=MacBook-Air-de-Andy.local` y `LAN_LISTEN_IP=0.0.0.0` en `.env`. El nombre local se mantiene aunque cambie la IP Wi-Fi de la Mac. Inicia los servicios con `docker compose up -d --wait`. El certificado público de esta instalación está incluido en `assets/lan-root-ca-mac.pem`; si se reemplaza el volumen de Caddy, exporta el nuevo certificado público antes de recompilar. No incluyas su clave privada.

```sh
cd ~/Documents/Trabajo/MELACAMPOS_MOBIL
~/Developer/flutter-3.35.3/flutter/bin/flutter pub get --enforce-lockfile
~/Developer/flutter-3.35.3/flutter/bin/flutter devices
PATH="$HOME/Developer/ruby-3.4.12/bin:$PATH" SSL_CERT_FILE=/etc/ssl/cert.pem \
  ~/Developer/flutter-3.35.3/flutter/bin/flutter run --release \
  -d ID_DEL_IPHONE \
  --dart-define=API_BASE_URL=https://MacBook-Air-de-Andy.local:8443
```

El ID se obtiene de `flutter devices`. La instalación permanece en el iPhone después de cerrar Flutter; para utilizar la app, mantén Docker y el iPhone en la misma red. El nombre local evita reconfigurar la app cuando cambia la IP. Si cambias el nombre local de la Mac, actualiza `LAN_HOME_HOST` y la URL de compilación. Con una cuenta Apple gratuita, iOS permite un número limitado de apps de desarrollo instaladas simultáneamente.

## Backend compartido y roles

No se crea otra base de datos ni otro Docker. `integration/web/` contiene las fuentes que amplían el proyecto web; consultar `integration/README.md`. Los volúmenes existentes se mantienen. Las cuentas administrativas anteriores conservan su rol; las cuentas nuevas solo pueden ser creadas por un administrador. No hay registro público.

- **Administrador:** gestiona trabajadores, edición de nombres, roles, bloqueo, restablecimiento de contraseña y revisión/asignación de visitas. El correo permanece como identificador fijo de acceso.
- **Medición y cotización:** una cuenta registra sus propias visitas, calcula propuestas y solicita imágenes. Genera un PDF completo con cotización y bosquejos, para conservar juntos los datos del cliente, las medidas y el importe preliminar. Las cuentas anteriores con rol Cotización mantienen estas mismas funciones.
- **Instalación:** consulta visitas propias o asignadas; no crea propuestas ni genera imágenes.
- Los permisos se comprueban en cada petición contra la base de datos. Bloquear un usuario o restablecer su contraseña invalida sus sesiones anteriores. Reactivar la cuenta exige iniciar sesión de nuevo; las sesiones antiguas no recuperan acceso.

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


## Cuentas de trabajadores

El módulo de administración está en `http://localhost:8080/admin/equipo-movil`. Permite crear cuentas, editar nombres, asignar roles, bloquear/reactivar accesos y restablecer contraseñas. Solo el administrador web puede utilizarlo. Los perfiles operativos de Medición móvil y Cotización móvil fueron creados en la base PostgreSQL local por solicitud del propietario. No se distribuyen contraseñas ni usuarios precargados en Git. Las credenciales locales se guardan en `.local/Accesos-trabajadores-GM.txt`, excluido del repositorio.

Las modificaciones se registran en auditoría sin guardar contraseñas en texto plano. El backend almacena las contraseñas con scrypt y comprueba los permisos y la versión de sesión en cada solicitud.

## Tu propia red Wi-Fi sin modo desarrollador

Conecta el teléfono y el equipo a la misma red. La configuración local actual utiliza **DIONICIO-2.4G-GQUD** y `https://192.168.18.103:8443`. Es una dirección privada de esta instalación; para tu equipo utiliza su propia IP Wi-Fi.

```powershell
cd D:\App_Mobile_GyMelacampos_
.\scripts\configurar-wifi.ps1 -WebRoot D:\GyMelacampos -Flutter D:\flutter\flutter\bin\flutter.bat -Build
```

El script detecta el Wi-Fi del equipo, configura `LAN_BIND_IP` en el `.env` de la web, inicia el servicio HTTPS de `compose.override.yaml`, exporta el certificado público y compila el APK apuntando a esa IP. La red debe permitir comunicación entre dispositivos; no hace falta conocer ni guardar la contraseña del Wi-Fi en la app.

Si necesitas permitir el acceso en el firewall, ejecuta como administrador desde la carpeta web:

```powershell
.\scripts\permitir-wifi.ps1 -ServerIP IP_DEL_EQUIPO
```

La regla se limita a Wi-Fi, TCP 8443 y la subred local. La app usa HTTPS y verifica el certificado; no incluye claves privadas ni claves de OpenAI. La autoridad local se conserva dentro de un volumen de Docker, y solo su certificado público se incluye en `assets/lan-root-ca.pem`.

Instala `build/app/outputs/flutter-apk/app-release.apk`. Puedes instalarlo por USB una vez o descargarlo al teléfono y abrir el instalador de Android. Esta última opción no necesita modo desarrollador, aunque Android puede solicitar permiso para instalar desde esa aplicación. Después abre G&M Campo, inicia sesión con tu cuenta de trabajador y mantén Docker activo. El USB se puede retirar y la depuración desactivar: el tráfico usa la red Wi-Fi.

Al actualizar una instalación que antes usaba localhost/USB, el APK Wi-Fi copia los borradores y el catálogo locales a la nueva dirección sin eliminar los originales y pide iniciar sesión de nuevo. Si eliges explícitamente otro servidor HTTPS, la app respeta esa configuración.

Si cambia la IP del equipo, actualiza el servicio y la URL desde «Configurar conexión» en el inicio de sesión. Para conservarla entre reinicios conviene reservarla en el router. Al probar con otra instalación de Docker, exporta su certificado antes de recompilar; no copies claves privadas. Un APK compilado con otro certificado no confiará automáticamente en esa instalación.

Para volver al modo USB se puede configurar `http://127.0.0.1:8080` y ejecutar el asistente USB con depuración habilitada. El Wi-Fi y la web siguen compartiendo los mismos clientes, cuentas y visitas; no se crean servidores de datos alternativos.

### Guardado de medidas y cotización

En una cuenta de trabajador, **Guardar en admin** envía el formulario válido, medidas, piezas, material y cotización al backend compartido. La visita queda visible en «Equipo móvil» y la solicitud vinculada aparece en «Cotizaciones». El detalle administrativo muestra el vínculo entre ambos registros. «Enviar visita al administrador» desde la proforma conserva el mismo flujo.

El guardado automático es un borrador local: permite continuar sin conexión o con campos incompletos. Si falla la red al enviar, el borrador permanece en el teléfono para reintentar; no se indica como enviado. La demo guarda únicamente datos locales.


## Dos redes guardadas: casa y Motorola (Android 1.3)

La app prueba por HTTPS las dos direcciones de esta instalación y utiliza la disponible:

- Casa, DIONICIO-2.4G-GQUD: `https://192.168.18.103:8443`.
- Datos compartidos del Motorola, motoedge50fusion_9340: `https://10.149.160.129:8444`.

Ambas rutas llegan al mismo backend, PostgreSQL y administración. No es necesario cambiar la URL al pasar de una red a otra con el APK 1.3. Los borradores usan una identidad común; al actualizar se combinan por UUID los borradores de las direcciones anteriores, conservando el borrador existente de casa si hay duplicados. Los originales se conservan. Un servidor HTTPS personalizado no participa en este cambio automático ni comparte su sesión con estas rutas.

Docker mantiene dos entradas Caddy, con certificados de la misma autoridad local y puertos separados. En esta instalación `LAN_LISTEN_IP=0.0.0.0` permite conservar los puertos al cambiar de Wi-Fi; Windows debe limitar el acceso con la regla del proyecto a Wi-Fi, las dos IP locales y los puertos 8443/8444. No abrir puertos en el router. En copias nuevas el enlace predeterminado sigue limitado a localhost. Para habilitar la regla, ejecutar en PowerShell como administrador:

```powershell
cd D:\GyMelacampos
.\scripts\permitir-wifi.ps1 -ServerIP 10.149.160.129
```

Si el equipo está conectado a casa, usar `-ServerIP 192.168.18.103`. Este parámetro verifica que la interfaz esté conectada antes de configurar la regla. Después, `docker compose up -d` conserva ambas entradas sin reconfiguración por cambio de red. Las IP deben seguir siendo las indicadas; si DHCP las cambia, se deben actualizar las direcciones, la regla y el APK. No hay descubrimiento automático de IP ni acceso remoto por internet. El teléfono debe poder alcanzar la PC por la red elegida, y la PC y Docker deben permanecer encendidos. No requiere USB ni modo desarrollador.


## Android 1.4: diseño compartido con iOS

La actualización Android incorpora los diseños Flutter compartidos de acceso, Inicio, Visitas, catálogo con filtros, Cuenta con foto opcional, seguimiento y formulario por pasos. La propuesta PDF reúne cotización y bosquejos con identidad G&M. El catálogo y los estados proceden del backend web actual; las medidas siguen ingresándose manualmente. No se modifica la firma ni la configuración nativa de iOS para esta entrega Android.

Para esta laptop Windows compilar con `--dart-define=API_BASE_URL=https://192.168.18.103:8443`. Se conservan las conexiones de casa y Motorola, y los certificados públicos ya incluidos. No reinstalar borrando datos. La actualización usa el mismo identificador y firma interna para conservar almacenamiento local.

Si otro contenedor ocupa específicamente `192.168.18.103:8443`, la app puede recibir el certificado de otro sistema aunque G&M publique en `0.0.0.0:8443`. Detener el proyecto en conflicto o asignarle otro puerto antes de probar; nunca desactivar la validación TLS. El APK sigue siendo una distribución interna con firma de desarrollo.

Validación de esta entrega: 17 pruebas Flutter y recorridos en Motorola edge 50 fusion (Android 16) del formulario y la propuesta PDF, más acceso HTTPS y catálogo real por Wi-Fi de casa. El acceso del punto de acceso Motorola se conserva; no se vuelve a afirmar una prueba de calle si no se cambia a esa red. La imagen IA sigue dependiendo de una clave válida y cuota del backend.

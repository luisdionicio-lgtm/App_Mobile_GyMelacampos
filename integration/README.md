# Integración con la web existente

La aplicación usa el repositorio Proyecto-de-tesis---GyMelacampos y sus mismos servicios Docker. No hay un servidor móvil independiente.

`web.patch` contiene todas las ampliaciones de backend, roles, pruebas y panel web desarrolladas con la app. La revisión base está en `web-base-commit.txt`. Ya se aplicaron localmente en `D:\GyMelacampos` y los contenedores fueron reconstruidos conservando los volúmenes. No aplicar nuevamente sobre esa copia.

Para una copia limpia de esa revisión del proyecto web:

```powershell
cd D:\GyMelacampos
git apply --check D:\App_Mobile_GyMelacampos_\integration\web.patch
git apply D:\App_Mobile_GyMelacampos_\integration\web.patch
npm --prefix backend ci
npm --prefix backend test
npm --prefix frontend ci
npm --prefix frontend run build
docker compose config --quiet
docker compose up --build -d --wait
```

Si `--check` falla, revisar diferencias antes de integrar; no sobrescribir código ni secretos. El parche nunca modifica `.env`, imágenes, credenciales ni volúmenes.

Rutas nuevas:

- `GET/POST /api/admin/workers`: listar/crear trabajadores (solo administrador).
- `PATCH /api/admin/workers/:email`: rol, bloqueo y restablecimiento de contraseña.
- `GET/PATCH /api/admin/visits`: revisión y asignación (PATCH usa `/:id`).
- `GET /api/mobile/me`: identidad y rol vigentes.
- `GET /api/mobile/visits`: visitas propias o asignadas.
- `POST /api/mobile/preview`: validar piezas y calcular con el catálogo real.
- `POST /api/mobile/visits`: guardar la visita, solicitud y cliente prospecto de forma idempotente por UUID.
- `POST /api/mobile/visits/:id/photo`: evidencia JPG/PNG validada.
- `POST /api/mobile/visits/:id/image`: imagen IA con clave del servidor.
- `GET /api/mobile/visits/:id/files/:file`: archivos con comprobación de propiedad/asignación.
- `/admin/equipo-movil`: pantalla web de administración.

La creación de solicitud y outbox conserva la transacción existente. La visita usa una segunda transacción y conserva el UUID para que un reintento recupere la misma cotización si ocurre un corte entre ambas. La cola de cotizaciones sigue procesando solicitudes y pedidos como antes.

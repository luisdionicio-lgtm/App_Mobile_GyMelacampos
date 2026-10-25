import 'package:flutter/material.dart';
import '../../../core/api.dart';
import '../../../core/connection.dart';
import '../../../core/preferences.dart';
import '../../../core/theme.dart';

class SettingsPage extends StatelessWidget {
  final Session session;
  final ConnectionMonitor monitor;
  const SettingsPage({super.key, required this.session, required this.monitor});
  void information(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(c).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(content, style: const TextStyle(height: 1.7)),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesScope.of(context),
        scheme = Theme.of(context).colorScheme;
    return ListView(
      key: const PageStorageKey('settings'),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
      children: [
        Text('A tu manera.', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.person_outline, color: scheme.onPrimaryContainer),
          ),
          title: Text(
            session.user?['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            session.demo ? 'Demo de trabajador' : session.user?['email'] ?? '',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rol: ${{'admin': 'Administrador', 'medicion': 'Medición', 'cotizacion': 'Cotización', 'instalacion': 'Instalación'}[session.user?['role']] ?? 'Trabajador'}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const Divider(height: 36),
        Text('Apariencia', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('Claro'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('Oscuro'),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_outlined),
              label: Text('Sistema'),
            ),
          ],
          selected: {prefs.mode},
          onSelectionChanged: (v) => prefs.setMode(v.first),
        ),
        const SizedBox(height: 22),
        const Text(
          'Color de acento',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in [
              (Accent.gold, 'Dorado', const Color(0xff946A29)),
              (Accent.blue, 'Azul', const Color(0xff15357E)),
              (Accent.forest, 'Verde', const Color(0xff29634C)),
            ])
              ChoiceChip(
                avatar: CircleAvatar(backgroundColor: entry.$3, radius: 9),
                label: Text(entry.$2),
                selected: prefs.accent == entry.$1,
                onSelected: (_) => prefs.setAccent(entry.$1),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reducir animaciones'),
          subtitle: const Text(
            'Transiciones más discretas. También respeta el ajuste de accesibilidad del teléfono.',
          ),
          value: prefs.reduceMotion,
          onChanged: prefs.setMotion,
        ),
        const Divider(height: 32),
        Text('Conexión y datos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: monitor,
          builder: (c, _) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              monitor.state == ServerState.online
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              color: scheme.primary,
            ),
            title: Text(
              monitor.state == ServerState.online
                  ? 'Servidor disponible'
                  : 'Servidor sin conexión',
            ),
            subtitle: Text(session.api.base),
            trailing: IconButton(
              tooltip: 'Comprobar conexión',
              onPressed: monitor.check,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ),
        const Note(
          'Los borradores se guardan en este teléfono. Al enviar una visita, el administrador la recibe en la web. La sesión necesita renovarse cuando vence.',
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.help_outline),
          title: const Text('Cómo conectar con Docker'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => information(
            context,
            'Tu móvil y la web',
            'Mantén el Motorola conectado por USB y Docker encendido. El enlace local usa el puerto 8080. El asistente del equipo restablece ese enlace al reconectar el celular.\n\nLa app comprueba el servidor al abrirse y cada 20 segundos mientras está en primer plano. Si Docker está apagado, puedes continuar guardando borradores.\n\nPara trabajar fuera de este equipo necesitas un servidor HTTPS accesible desde el teléfono.',
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Privacidad y acceso'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => information(
            context,
            'Tu información, protegida',
            'El administrador de G&M crea las cuentas y asigna los permisos. Las claves de servicios de IA se almacenan únicamente en el backend; no se incluyen en el APK.\n\nTu sesión y borradores se guardan con almacenamiento seguro. Las fotos permanecen en el espacio privado de la app hasta enviarlas. Al compartir un PDF, tú eliges la aplicación y el destinatario.\n\nLa demo usa registros locales separados de los clientes reales.',
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: const Text('G&M Campo'),
          subtitle: const Text('Versión 1.1.0 · Visitas técnicas'),
          onTap: () => information(
            context,
            'G&M Campo',
            'Aplicación de trabajo para G&M Melacampos. Registro de medidas, catálogo, bosquejo, proforma y seguimiento administrativo.\n\nLas imágenes IA son conceptuales. Las medidas y el importe requieren validación técnica y administrativa.',
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            await session.logout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../core/api.dart';
import '../../../core/brand_ui.dart';
import '../../../core/connection.dart';
import '../../../core/preferences.dart';

class SettingsPage extends StatelessWidget {
  final Session session;
  final ConnectionMonitor monitor;
  const SettingsPage({super.key, required this.session, required this.monitor});

  void sheet(BuildContext context, String title, Widget content) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (c) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GmPageTitle(title),
                const SizedBox(height: 18),
                content,
                const SizedBox(height: 20),
                GmAction(label: 'Entendido', onPressed: () => Navigator.pop(c)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesScope.of(context);
    final role =
        {
          'admin': 'Administrador',
          'medicion': 'Medición y cotización',
          'cotizacion': 'Medición y cotización',
          'instalacion': 'Instalación',
        }[session.user?['role']] ??
        'Trabajador';
    return ListView(
      key: const PageStorageKey('settings'),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
      children: [
        GmPanel(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: gmRed,
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.user?['name']?.toString() ?? 'Trabajador',
                      style: const TextStyle(
                        color: gmNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role,
                      style: const TextStyle(color: Color(0xff53606b)),
                    ),
                    if (!session.demo)
                      Text(
                        session.user?['email']?.toString() ?? '',
                        style: const TextStyle(
                          color: Color(0xff6c7680),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        GmPanel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _item(
                Icons.wifi,
                'Conexión',
                () => sheet(
                  context,
                  'Conexión',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListenableBuilder(
                        listenable: monitor,
                        builder: (c, _) => Text(
                          monitor.state == ServerState.online
                              ? 'Servidor G&M disponible'
                              : 'Servidor sin conexión',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(session.api.endpoint),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: monitor.check,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Comprobar conexión'),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              _item(
                Icons.sync,
                'Sincronización y datos',
                () => sheet(
                  context,
                  'Sincronización y datos',
                  const Text(
                    'Los borradores se guardan en este iPhone. Cuando envías una visita, el administrador la recibe en la web. Desliza hacia abajo en Inicio o Visitas para actualizar los datos.',
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ),
              const Divider(height: 1),
              _item(
                Icons.palette_outlined,
                'Apariencia',
                () => sheet(
                  context,
                  'Apariencia',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Claro'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Oscuro'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('Sistema'),
                          ),
                        ],
                        selected: {prefs.mode},
                        onSelectionChanged: (v) => prefs.setMode(v.first),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Reducir animaciones'),
                        value: prefs.reduceMotion,
                        onChanged: prefs.setMotion,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              _item(
                Icons.help_outline,
                'Ayuda',
                () => sheet(
                  context,
                  'Ayuda',
                  const Text(
                    'Registra cliente, piezas y medidas; elige un material y prepara el PDF único con cotización y bosquejos. La visualización con IA es conceptual. Para cambiar la dirección del servidor, usa Configurar conexión en el acceso.',
                    style: TextStyle(height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: session.logout,
          style: OutlinedButton.styleFrom(
            foregroundColor: gmRed,
            side: const BorderSide(color: gmRed),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) => ListTile(
    leading: Icon(icon, color: gmNavy),
    title: Text(
      title,
      style: const TextStyle(color: gmNavy, fontWeight: FontWeight.w600),
    ),
    trailing: const Icon(Icons.chevron_right, color: gmNavy),
    onTap: onTap,
  );
}

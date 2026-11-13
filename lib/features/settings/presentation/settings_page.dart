import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api.dart';
import '../../../core/brand_ui.dart';
import '../../../core/connection.dart';
import '../../../core/preferences.dart';

class SettingsPage extends StatelessWidget {
  final Session session;
  final ConnectionMonitor monitor;
  const SettingsPage({super.key, required this.session, required this.monitor});

  Future<void> changeAvatar(BuildContext context, ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 82,
      );
      if (image == null) return;
      await session.uploadAvatar(image.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la foto: $error')),
        );
      }
    }
  }

  Future<void> removeAvatar(BuildContext context) async {
    try {
      await session.removeAvatar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil eliminada')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo quitar la foto: $error')),
        );
      }
    }
  }

  void avatarOptions(BuildContext context) {
    if (session.demo) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Foto de perfil',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(sheetContext);
                changeAvatar(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de Fotos'),
              onTap: () {
                Navigator.pop(sheetContext);
                changeAvatar(context, ImageSource.gallery);
              },
            ),
            if (session.avatarFile != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: gmRed),
                title: const Text('Quitar foto'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  removeAvatar(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget profileAvatar(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) => GestureDetector(
      onTap: session.demo ? null : () => avatarOptions(context),
      child: Semantics(
        button: !session.demo,
        label: 'Cambiar foto de perfil',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: gmRed,
                shape: BoxShape.circle,
                border: Border.all(color: gmGold, width: 2),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: session.avatarFile == null
                    ? const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 34,
                      )
                    : Image.network(
                        '${session.api.endpoint}/api/mobile/avatar?v=${session.avatarFile}',
                        headers: {
                          if (session.api.cookie != null)
                            'Cookie': session.api.cookie!,
                        },
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
              ),
            ),
            if (!session.demo)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    color: gmGold,
                    shape: BoxShape.circle,
                    border: Border.all(color: gmNavy, width: 1.5),
                  ),
                  child: const Icon(Icons.camera_alt, color: gmNavy, size: 14),
                ),
              ),
          ],
        ),
      ),
    ),
  );

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
      padding: const EdgeInsets.fromLTRB(18, 54, 18, 36),
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: gmGold, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3c06233c),
                blurRadius: 13,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 19, 14, 19),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login-navy-marble.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _AccountCorner())),
                Row(
                  children: [
                    profileAvatar(context),
                    const SizedBox(width: 14),
                    Container(width: 1, height: 75, color: gmGold),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (session.user?['name']?.toString() ?? 'Trabajador')
                                .toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          if (!session.demo) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.mail_outline,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    session.user?['email']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: gmGold, width: 1.6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2506233c),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
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
              const Divider(height: 1, indent: 14, endIndent: 14),
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
              const Divider(height: 1, indent: 14, endIndent: 14),
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
              const Divider(height: 1, indent: 14, endIndent: 14),
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
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xffa00010), gmRed, Color(0xff77000c)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: gmGold, width: 1.7),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3806233c),
                blurRadius: 11,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: session.logout,
              borderRadius: BorderRadius.circular(22),
              child: const SizedBox(
                height: 58,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xfffbe9e7),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: gmRed, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: gmNavy,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: gmNavy),
        ],
      ),
    ),
  );
}

class _AccountCorner extends CustomPainter {
  const _AccountCorner();
  @override
  void paint(Canvas canvas, Size size) {
    final corner = Path()
      ..moveTo(size.width - 55, size.height)
      ..lineTo(size.width, size.height - 60)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(corner, Paint()..color = gmRed);
    canvas.drawLine(
      Offset(size.width - 58, size.height),
      Offset(size.width, size.height - 63),
      Paint()
        ..color = gmGold
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'core/api.dart';
import 'core/theme.dart';
import 'features/auth/login.dart';
import 'features/visits/data/visit_repository.dart';
import 'features/visits/presentation/visit_editor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = Api();
  await api.init();
  final session = Session(api);
  await session.restore();
  runApp(GmApp(session));
}

class GmApp extends StatelessWidget {
  final Session session;
  const GmApp(this.session, {super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'G&M Campo',
    debugShowCheckedModeBanner: false,
    theme: gmTheme(),
    home: ListenableBuilder(
      listenable: session,
      builder: (c, _) => session.user == null
          ? LoginPage(session)
          : Workspace(
              session,
              key: ValueKey('${session.demo}:${session.user?['email']}'),
            ),
    ),
  );
}

class Workspace extends StatefulWidget {
  final Session session;
  const Workspace(this.session, {super.key});
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  late final VisitRepository repo;
  int tab = 0;
  bool loading = true;
  String search = '', category = 'Todos';
  @override
  void initState() {
    super.initState();
    repo = VisitRepository(widget.session);
    reload();
  }

  Future<void> reload() async {
    setState(() => loading = true);
    await repo.load();
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    repo.dispose();
    super.dispose();
  }

  Future<void> editor([int? index]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisitEditor(
          repo,
          existing: index == null ? null : repo.visits[index],
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final expanded = MediaQuery.sizeOf(context).width >= 700;
    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: 'Visitas',
      ),
      NavigationDestination(
        icon: Icon(Icons.layers_outlined),
        selectedIcon: Icon(Icons.layers),
        label: 'Materiales',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Cuenta',
      ),
    ];
    final body = SafeArea(
      child: RefreshIndicator(
        onRefresh: reload,
        child: ListenableBuilder(
          listenable: repo,
          builder: (c, _) => ListView(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 100),
            children: [
              if (widget.session.demo)
                const Note(
                  'DEMO DE TRABAJADOR · Datos locales de ejemplo',
                  icon: Icons.science_outlined,
                ),
              if (loading) const LinearProgressIndicator(),
              if (repo.error != null)
                Note(
                  '${repo.error!.replaceFirst('Exception: ', '')} Los borradores siguen disponibles.',
                ),
              if (tab == 0) ...[
                Text(
                  'Cada detalle\ncuenta.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Registra tu visita. Dale forma a la propuesta.',
                  style: TextStyle(color: Color(0xff6C6963)),
                ),
                const SizedBox(height: 24),
                if (widget.session.canEdit)
                  FilledButton.icon(
                    onPressed: () => editor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva visita técnica'),
                  ),
                const SizedBox(height: 26),
                Text(
                  'Mis visitas',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 14),
                if (repo.visits.isEmpty && !loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 38),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_outlined, size: 48, color: gold),
                        SizedBox(height: 18),
                        Text(
                          'Tu primera visita empieza aquí',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Agrega el cliente, las piezas y el material para preparar tu propuesta.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                for (int i = 0; i < repo.visits.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        repo.visits[i].project == 'Baño'
                            ? Icons.bathtub_outlined
                            : Icons.countertops_outlined,
                        color: gold,
                      ),
                      title: Text(
                        repo.visits[i].client.isEmpty
                            ? 'Visita sin nombre'
                            : repo.visits[i].client,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${repo.visits[i].project} · ${repo.visits[i].area.toStringAsFixed(2)} m²\n${repo.visits[i].status}',
                        ),
                      ),
                      isThreeLine: true,
                      trailing: Icon(
                        repo.visits[i].synced
                            ? Icons.cloud_done_outlined
                            : Icons.edit_note,
                        color: gold,
                      ),
                      onTap: () => editor(i),
                    ),
                  ),
              ] else if (tab == 1) ...[
                Text(
                  'La piedra indicada.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                const Text('El catálogo de G&M, actualizado desde la web.'),
                const SizedBox(height: 20),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar material',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => search = v),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children:
                      ['Todos', 'Cuarzo', 'Granito', 'Mármol', 'Sinterizada']
                          .map(
                            (x) => ChoiceChip(
                              label: Text(x),
                              selected: category == x,
                              onSelected: (_) => setState(() => category = x),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
                for (final m in repo.materials.where(
                  (m) =>
                      (category == 'Todos' || m['cat'] == category) &&
                      '${m['name']} ${m['cat']}'.toLowerCase().contains(
                        search.toLowerCase(),
                      ),
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            '${widget.session.api.base}${m['img']}',
                            height: 170,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => const SizedBox(
                              height: 100,
                              child: Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          m['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text('${m['cat']} · ${m['finish']} · ${m['thick']}'),
                        const SizedBox(height: 4),
                        Text(
                          m['desc'] ?? '',
                          style: const TextStyle(color: Color(0xff6C6963)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (m['pricePerM2'] as num) > 0
                              ? 'S/ ${m['pricePerM2']} por m²'
                              : 'Tarifa por evaluar',
                          style: const TextStyle(
                            color: gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                Text(
                  'Tu cuenta',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xffF3EFE8),
                    child: Icon(Icons.person_outline, color: gold),
                  ),
                  title: Text(widget.session.user?['name'] ?? ''),
                  subtitle: Text(
                    widget.session.demo
                        ? 'Modo de demostración'
                        : widget.session.user?['email'] ?? '',
                  ),
                ),
                const Divider(height: 32),
                Text('Rol: ${widget.session.user?['role']}'),
                const SizedBox(height: 12),
                Text('Servidor: ${widget.session.api.base}'),
                const Note(
                  'El administrador crea las cuentas, asigna roles, bloquea accesos y revisa las visitas desde la web. Los borradores se guardan cifrados en el dispositivo.',
                ),
                const Note(
                  'Para conectarte por USB, mantén Docker activo y ejecuta el script conectar-celular.ps1 en el equipo.',
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await widget.session.logout();
                    } catch (e) {
                      if (context.mounted) showError(context, e);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Brand(),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: loading ? null : reload,
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: expanded
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: tab,
                  onDestinationSelected: (v) => setState(() => tab = v),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      label: Text('Visitas'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.layers_outlined),
                      label: Text('Materiales'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      label: Text('Cuenta'),
                    ),
                  ],
                ),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: expanded
          ? null
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (v) => setState(() => tab = v),
              destinations: destinations,
            ),
    );
  }
}

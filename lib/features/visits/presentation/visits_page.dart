import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../workspace/presentation/widgets.dart';
import '../data/visit_repository.dart';
import '../domain/visit.dart';

class VisitsPage extends StatefulWidget {
  final VisitRepository repo;
  final void Function(Visit?) onOpen;
  const VisitsPage({super.key, required this.repo, required this.onOpen});
  @override
  State<VisitsPage> createState() => _VisitsState();
}

class _VisitsState extends State<VisitsPage> {
  String search = '';
  int filter = 0;
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> remove(Visit visit) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Eliminar este borrador?'),
        content: const Text(
          'Se quitará de este dispositivo. Las visitas enviadas a la web se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar borrador'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await widget.repo.removeDraft(visit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visits = widget.repo.visits.where((v) {
      final text =
          '${v.client} ${v.project} ${v.location} ${v.material?['name'] ?? ''}'
              .toLowerCase();
      return text.contains(search.toLowerCase()) &&
          switch (filter) {
            0 => true,
            1 => !v.synced,
            2 => v.synced && v.status == 'En revisión',
            3 => v.status == 'Validada',
            _ => v.status == 'Observada',
          };
    }).toList();
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis visitas',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text('Cada medida y propuesta, en su lugar.'),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  onChanged: (v) => setState(() => search = v),
                  decoration: InputDecoration(
                    labelText: 'Buscar cliente o proyecto',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: search.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: () {
                              controller.clear();
                              setState(() => search = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (value) => setState(() => filter = value),
            tabs: const [
              Tab(text: 'Todas'),
              Tab(text: 'Borradores'),
              Tab(text: 'En revisión'),
              Tab(text: 'Validadas'),
              Tab(text: 'Observadas'),
            ],
          ),
          Expanded(
            child: ListView(
              key: const PageStorageKey('visits'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              children: [
                if (visits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 46,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          search.isEmpty
                              ? 'Todavía no hay visitas aquí'
                              : 'No encontramos esa visita',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          search.isEmpty
                              ? 'Crea una visita o prueba otro filtro.'
                              : 'Prueba con otro nombre, ambiente o material.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                for (final visit in visits)
                  VisitTile(
                    visit,
                    onTap: () => widget.onOpen(visit),
                    onDelete: !visit.synced ? () => remove(visit) : null,
                  ),
                if (widget.repo.session.demo)
                  const Note(
                    'Los datos de demostración permanecen separados de los registros reales.',
                    icon: Icons.science_outlined,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

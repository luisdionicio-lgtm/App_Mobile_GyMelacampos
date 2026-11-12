import 'package:flutter/material.dart';
import '../../../core/brand_ui.dart';
import '../../../core/theme.dart';
import '../../visits/data/visit_repository.dart';
import '../../visits/domain/visit.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  final VisitRepository repo;
  final void Function(Visit?) onOpen;
  final VoidCallback onVisits;
  final VoidCallback onMaterials;
  const HomePage({
    super.key,
    required this.repo,
    required this.onOpen,
    required this.onVisits,
    required this.onMaterials,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        repo.session.user?['name']?.toString().split(' ').first ?? 'equipo';
    final last = repo.visits.isEmpty ? null : repo.visits.first;
    return ListView(
      key: const PageStorageKey('home'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
      children: [
        Text(
          'Hola, $name 👋',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: gmNavy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '¿Qué deseas hacer hoy?',
          style: TextStyle(color: Color(0xff5d6770)),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.52,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _Shortcut(
              Icons.add_circle,
              'Nueva visita',
              repo.session.canEdit ? () => onOpen(null) : null,
            ),
            _Shortcut(Icons.assignment_outlined, 'Mis visitas', onVisits),
            _Shortcut(Icons.timeline, 'Seguimiento', onVisits),
            _Shortcut(Icons.layers_outlined, 'Materiales', onMaterials),
          ],
        ),
        const SizedBox(height: 24),
        const GmPageTitle('Último trabajo'),
        const SizedBox(height: 12),
        if (last == null)
          const GmPanel(
            child: Text(
              'Todavía no hay visitas. Empieza registrando un cliente y sus piezas.',
            ),
          )
        else
          VisitTile(
            last,
            onTap: () => onOpen(last),
            serverBase: repo.session.api.endpoint,
          ),
        if (repo.session.demo)
          const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Note(
              'Demo local: los datos de ejemplo no se envían a la web.',
              icon: Icons.science_outlined,
            ),
          ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _Shortcut(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(18),
    elevation: 2,
    shadowColor: gmNavy.withValues(alpha: .12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: gmGold, size: 31),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, color: gmNavy),
          ),
        ],
      ),
    ),
  );
}

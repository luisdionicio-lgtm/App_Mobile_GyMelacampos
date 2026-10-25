import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../visits/data/visit_repository.dart';
import '../../visits/domain/visit.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  final VisitRepository repo;
  final void Function(Visit?) onOpen;
  final VoidCallback onVisits;
  const HomePage({
    super.key,
    required this.repo,
    required this.onOpen,
    required this.onVisits,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final drafts = repo.visits.where((v) => !v.synced).length;
    return ListView(
      key: const PageStorageKey('home'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
      children: [
        Text(
          'Hola, ${repo.session.user?['name']?.toString().split(' ').first ?? 'equipo'}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Text(
          'Buenas ideas.\nMedidas claras.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Image.asset(
                'assets/stone.png',
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: .45)),
              ),
              const Positioned(
                left: 22,
                right: 22,
                bottom: 22,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Del material al detalle.',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tu próxima propuesta empieza en la visita.',
                      style: TextStyle(color: Colors.white, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (repo.session.canEdit)
          FilledButton.icon(
            onPressed: () => onOpen(null),
            icon: const Icon(Icons.add),
            label: const Text('Nueva visita técnica'),
          ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.edit_note, size: 18),
              label: Text('$drafts borradores'),
            ),
            Chip(
              avatar: const Icon(Icons.cloud_done_outlined, size: 18),
              label: Text(
                '${repo.visits.where((v) => v.synced).length} enviadas',
              ),
            ),
          ],
        ),
        SectionTitle(
          'Mis visitas',
          trailing: TextButton(
            onPressed: onVisits,
            child: const Text('Ver todas'),
          ),
        ),
        if (repo.visits.isEmpty)
          const Note(
            'Registra el cliente y sus piezas para preparar tu primera propuesta.',
            icon: Icons.assignment_outlined,
          ),
        for (final visit in repo.visits.take(3))
          VisitTile(visit, onTap: () => onOpen(visit)),
        if (repo.session.demo)
          const Note(
            'Estás en la demo. Puedes probar medidas, materiales y proformas sin crear registros reales en la web.',
            icon: Icons.science_outlined,
          ),
        const SectionTitle('Tu flujo de trabajo'),
        for (final item in [
          (
            Icons.straighten,
            'Registra las piezas',
            'Largo, ancho, espesor y cantidad.',
          ),
          (
            Icons.layers_outlined,
            'Encuentra el material',
            'El catálogo que administra G&M en la web.',
          ),
          (
            Icons.draw_outlined,
            'Prepara la propuesta',
            'Bosquejo con cotas y proforma PDF.',
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$1, color: scheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$2,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.$3,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

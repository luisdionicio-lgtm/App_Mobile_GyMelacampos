import 'package:flutter/material.dart';
import '../../../core/brand_ui.dart';
import '../../workspace/presentation/widgets.dart';
import '../data/visit_repository.dart';
import '../domain/visit.dart';

class TrackingPage extends StatefulWidget {
  final VisitRepository repo;
  const TrackingPage(this.repo, {super.key});
  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  String search = '';
  String filter = 'Todos';

  @override
  Widget build(BuildContext context) {
    final visits = widget.repo.visits.where((v) {
      final text = '${v.client} ${v.project} ${v.material?['name'] ?? ''}'
          .toLowerCase();
      return v.synced &&
          text.contains(search.toLowerCase()) &&
          (filter == 'Todos' || v.status == filter);
    }).toList();
    final statuses =
        widget.repo.visits
            .where((v) => v.synced)
            .map((v) => v.status)
            .toSet()
            .toList()
          ..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
        children: [
          const GmPageTitle(
            'Mis trabajos',
            subtitle: 'Estado actualizado por administración',
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => search = value),
            decoration: const InputDecoration(
              hintText: 'Buscar cliente o material',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final status in ['Todos', ...statuses])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: filter == status,
                      onSelected: (_) => setState(() => filter = status),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (visits.isEmpty)
            const GmPanel(
              child: Text(
                'No hay visitas enviadas para este filtro. Los borradores siguen en Mis visitas.',
              ),
            ),
          for (final visit in visits)
            VisitTile(
              visit,
              serverBase: widget.repo.session.api.endpoint,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TrackingDetailPage(visit)),
              ),
            ),
        ],
      ),
    );
  }
}

class TrackingDetailPage extends StatelessWidget {
  final Visit visit;
  const TrackingDetailPage(this.visit, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del trabajo')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
      children: [
        GmPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GmPageTitle(
                visit.client.isEmpty ? 'Cliente sin nombre' : visit.client,
                subtitle: visit.project,
              ),
              const SizedBox(height: 10),
              GmStatus(visit.status),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GmPanel(
          child: Column(
            children: [
              _fact(
                Icons.layers_outlined,
                'Material',
                visit.material?['name']?.toString() ?? 'Sin material',
              ),
              const Divider(height: 22),
              _fact(
                Icons.straighten,
                'Área medida',
                '${visit.area.toStringAsFixed(3)} m²',
              ),
              const Divider(height: 22),
              _fact(Icons.location_on_outlined, 'Ubicación', visit.location),
              if (visit.phone.isNotEmpty) ...[
                const Divider(height: 22),
                _fact(Icons.phone_outlined, 'Teléfono', visit.phone),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        const GmPageTitle('Estado de la visita'),
        const SizedBox(height: 10),
        GmPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined, color: gmGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      visit.status,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'El administrador actualiza la revisión de esta visita desde la web. Las etapas de fabricación e instalación aparecerán cuando estén vinculadas a este trabajo.',
                style: TextStyle(color: Color(0xff53606b), height: 1.4),
              ),
            ],
          ),
        ),
        if (visit.notes.isNotEmpty) ...[
          const SizedBox(height: 22),
          const GmPageTitle('Observaciones'),
          const SizedBox(height: 10),
          GmPanel(child: Text(visit.notes)),
        ],
      ],
    ),
  );

  Widget _fact(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, color: gmGold, size: 22),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xff63707a), fontSize: 12),
            ),
            Text(
              value.isEmpty ? 'Por confirmar' : value,
              style: const TextStyle(
                color: gmNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

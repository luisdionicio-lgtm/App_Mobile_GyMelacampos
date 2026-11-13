import 'package:flutter/material.dart';
import '../../../core/brand_ui.dart';
import '../../../core/theme.dart';
import '../data/visit_repository.dart';
import '../domain/visit.dart';

const _navyMarble = 'assets/login-navy-marble.jpg';
const _blackMarble = 'assets/home-black-gold-marble.png';

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
  static const filters = [
    'Todas',
    'Borradores',
    'En revisión',
    'Validadas',
    'Observadas',
  ];

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
    if (yes == true) await widget.repo.removeDraft(visit);
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 15),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3406233c),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              onChanged: (v) => setState(() => search = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar cliente, ambiente o material...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff64707c),
                ),
                prefixIcon: const Icon(Icons.search, color: gmNavy, size: 25),
                suffixIcon: search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          controller.clear();
                          setState(() => search = '');
                        },
                        icon: const Icon(Icons.close, color: gmNavy),
                      ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: .93),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: gmGold, width: 1.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: gmRed, width: 2),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 55,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final selected = index == filter;
              return Semantics(
                selected: selected,
                button: true,
                child: Material(
                  color: selected ? gmRed : Colors.white.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => filter = index),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? gmRed : gmGold,
                          width: 1.3,
                        ),
                      ),
                      child: Text(
                        filters[index],
                        style: TextStyle(
                          color: selected ? Colors.white : gmNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 7),
        Expanded(
          child: ListView(
            key: const PageStorageKey('visits'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 105),
            children: [
              if (visits.isEmpty) _EmptyVisits(search.isEmpty),
              for (final visit in visits)
                _VisitCard(
                  visit: visit,
                  serverBase: widget.repo.session.api.endpoint,
                  onTap: () => widget.onOpen(visit),
                  onDelete: !visit.synced ? () => remove(visit) : null,
                ),
              if (widget.repo.session.demo)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Note(
                    'Los datos de demostración permanecen separados de los registros reales.',
                    icon: Icons.science_outlined,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Visit visit;
  final String serverBase;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const _VisitCard({
    required this.visit,
    required this.serverBase,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final img = visit.material?['img']?.toString();
    final draft = !visit.synced;
    final review = visit.status == 'En revisión';
    final validated = visit.status == 'Validada';
    final chipColor = draft
        ? const Color(0xffdce8ff)
        : review
        ? const Color(0xffffe398)
        : validated
        ? const Color(0xffbfeccb)
        : const Color(0xffffd5d5);
    final chipIcon = draft
        ? Icons.edit_outlined
        : review
        ? Icons.schedule
        : validated
        ? Icons.check_circle_outline
        : Icons.info_outline;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(23),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3806233c),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(23),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(_navyMarble, fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: ColoredBox(color: gmNavy.withValues(alpha: .32)),
                ),
                const Positioned(right: 0, bottom: 0, child: _VisitCorner()),
                Padding(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      Container(
                        width: 67,
                        height: 67,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: gmGold, width: 1.7),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: img == null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(_blackMarble, fit: BoxFit.cover),
                                  const Center(
                                    child: Icon(
                                      Icons.layers_outlined,
                                      color: Color(0xffffd46d),
                                      size: 32,
                                    ),
                                  ),
                                ],
                              )
                            : Image.network(
                                '$serverBase$img',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      _blackMarble,
                                      fit: BoxFit.cover,
                                    ),
                                    const Center(
                                      child: Icon(
                                        Icons.layers_outlined,
                                        color: Color(0xffffd46d),
                                        size: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(width: 11),
                      Container(width: 1, height: 67, color: gmGold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visit.client.isEmpty
                                  ? 'Visita sin nombre'
                                  : visit.client,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  _projectIcon(visit.project),
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    '${visit.project} · ${visit.material?['name'] ?? 'Sin material'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xffe8edf5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: chipColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(chipIcon, size: 14, color: gmNavy),
                                  const SizedBox(width: 4),
                                  Text(
                                    draft ? 'Borrador' : visit.status,
                                    style: const TextStyle(
                                      color: gmNavy,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onDelete != null)
                        PopupMenuButton<String>(
                          tooltip: 'Opciones del borrador',
                          icon: const Icon(
                            Icons.more_horiz,
                            color: Colors.white,
                          ),
                          onSelected: (_) => onDelete!(),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar borrador'),
                            ),
                          ],
                        )
                      else
                        const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(color: gmGold, width: 1.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _projectIcon(String project) {
  final name = project.toLowerCase();
  if (name.contains('baño')) return Icons.bathtub_outlined;
  if (name.contains('cocina')) return Icons.kitchen_outlined;
  return Icons.home_work_outlined;
}

class _VisitCorner extends StatelessWidget {
  const _VisitCorner();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(49, 33), painter: _VisitCornerPainter());
}

class _VisitCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = gmRed);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      Paint()
        ..color = const Color(0xffffd676)
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyVisits extends StatelessWidget {
  final bool noSearch;
  const _EmptyVisits(this.noSearch);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const Icon(Icons.assignment_outlined, size: 43, color: gmGold),
        const SizedBox(height: 12),
        Text(
          noSearch
              ? 'Todavía no hay visitas aquí'
              : 'No encontramos esa visita',
          style: const TextStyle(
            color: gmNavy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          noSearch
              ? 'Crea una visita o prueba otro filtro.'
              : 'Prueba con otro nombre, ambiente o material.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xff59636d)),
        ),
      ],
    ),
  );
}

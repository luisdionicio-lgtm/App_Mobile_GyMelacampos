import 'package:flutter/material.dart';
import '../../../core/brand_ui.dart';
import '../../../core/theme.dart';
import '../../visits/data/visit_repository.dart';
import '../../visits/domain/visit.dart';

const _whiteMarble = 'assets/home-white-gold-marble.png';
const _blackMarble = 'assets/home-black-gold-marble.png';

class HomePage extends StatelessWidget {
  final VisitRepository repo;
  final void Function(Visit?) onOpen;
  final VoidCallback onVisits;
  final VoidCallback onMaterials;
  final VoidCallback onTracking;
  const HomePage({
    super.key,
    required this.repo,
    required this.onOpen,
    required this.onVisits,
    required this.onMaterials,
    required this.onTracking,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        repo.session.user?['name']?.toString().split(' ').first ?? 'equipo';
    final last = repo.visits.isEmpty ? null : repo.visits.first;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/login-white-marble-v2.jpg',
            fit: BoxFit.cover,
            color: Colors.white.withValues(alpha: .82),
            colorBlendMode: BlendMode.srcOver,
          ),
        ),
        ListView(
          key: const PageStorageKey('home'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 48,
                  decoration: BoxDecoration(
                    color: gmRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Hola, ',
                              style: TextStyle(color: gmNavy),
                            ),
                            TextSpan(
                              text: name.toUpperCase(),
                              style: const TextStyle(color: gmRed),
                            ),
                            const TextSpan(
                              text: ' 👋',
                              style: TextStyle(color: gmNavy),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '¿Qué deseas hacer hoy?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xff58616d),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) => GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: constraints.maxWidth < 350 ? 1.15 : 1.33,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  _MarbleShortcut(
                    Icons.add,
                    'Nueva visita',
                    false,
                    repo.session.canEdit ? () => onOpen(null) : null,
                  ),
                  _MarbleShortcut(
                    Icons.assignment_outlined,
                    'Mis visitas',
                    true,
                    onVisits,
                  ),
                  _MarbleShortcut(
                    Icons.show_chart,
                    'Seguimiento',
                    true,
                    onTracking,
                  ),
                  _MarbleShortcut(
                    Icons.layers_outlined,
                    'Materiales',
                    false,
                    onMaterials,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 33,
                  decoration: BoxDecoration(
                    color: gmRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Último trabajo',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: gmNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _LastWork(
              last,
              onTap: last == null ? onVisits : () => onOpen(last),
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
        ),
      ],
    );
  }
}

class _MarbleShortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool dark;
  final VoidCallback? onTap;
  const _MarbleShortcut(this.icon, this.label, this.dark, this.onTap);

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: gmNavy.withValues(alpha: .22),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(dark ? _blackMarble : _whiteMarble, fit: BoxFit.cover),
            if (dark) Container(color: Colors.black.withValues(alpha: .12)),
            const Positioned(right: 0, bottom: 0, child: _RedCorner()),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: gmGold, width: 2.4),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: dark
                            ? [const Color(0xfff6cf72), const Color(0xff996519)]
                            : [
                                const Color(0xfff31d2a),
                                const Color(0xffa90014),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 31),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : gmNavy,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RedCorner extends StatelessWidget {
  const _RedCorner();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(67, 45), painter: _RedCornerPainter());
}

class _RedCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xffe60020), Color(0xff9a0012)],
      ).createShader(Offset.zero & size);
    final gold = Paint()
      ..color = const Color(0xffefc45c)
      ..strokeWidth = 3;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, red);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LastWork extends StatelessWidget {
  final Visit? visit;
  final VoidCallback onTap;
  final String serverBase;
  const _LastWork(this.visit, {required this.onTap, required this.serverBase});

  @override
  Widget build(BuildContext context) {
    final img = visit?.material?['img']?.toString();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: gmNavy.withValues(alpha: .25),
            blurRadius: 12,
            offset: const Offset(0, 7),
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
                child: Image.asset(_blackMarble, fit: BoxFit.cover),
              ),
              const Positioned(right: 0, bottom: 0, child: _RedCorner()),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: gmGold, width: 2),
                      ),
                      child: img == null
                          ? Image.asset(_whiteMarble, fit: BoxFit.cover)
                          : Image.network(
                              '$serverBase$img',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  Image.asset(_whiteMarble, fit: BoxFit.cover),
                            ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit?.client.isNotEmpty == true
                                ? visit!.client
                                : 'Sin trabajos registrados',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            visit == null
                                ? 'Consulta tus visitas'
                                : '${visit!.project} · ${visit!.material?['name'] ?? 'Sin material'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xffdadde2),
                              fontSize: 13,
                            ),
                          ),
                          if (visit != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xfff9d16e),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                visit!.status,
                                style: const TextStyle(
                                  color: Color(0xff3d2700),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 27,
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: gmGold, width: 2.4),
                      borderRadius: BorderRadius.circular(23),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

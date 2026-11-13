import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api.dart';
import '../../../core/connection.dart';
import '../../../core/preferences.dart';
import '../../../core/theme.dart';
import '../../../core/brand_ui.dart';
import '../../catalog/presentation/catalog_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../visits/data/visit_repository.dart';
import '../../visits/domain/visit.dart';
import '../../visits/presentation/visit_editor.dart';
import '../../visits/presentation/visits_page.dart';
import '../../visits/presentation/tracking_page.dart';
import 'home_page.dart';

class Workspace extends StatefulWidget {
  final Session session;
  const Workspace(this.session, {super.key});
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  late final VisitRepository repo;
  late final ConnectionMonitor monitor;
  final pages = PageController();
  int tab = 0;
  bool loading = false, _wasOnline = false;
  @override
  void initState() {
    super.initState();
    repo = VisitRepository(widget.session);
    monitor = ConnectionMonitor(widget.session.api)
      ..addListener(connectionChanged);
    refresh();
  }

  void connectionChanged() {
    final online = monitor.state == ServerState.online;
    if (online && !_wasOnline) unawaited(refresh());
    _wasOnline = online;
  }

  Future<void> refresh() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      if (!widget.session.demo) await widget.session.verify();
      if (!mounted || widget.session.user == null) return;
      await repo.load();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> open(Visit? visit) async {
    if (!widget.session.canEdit && visit != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TrackingDetailPage(visit)),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VisitEditor(repo, existing: visit)),
    );
    if (mounted) setState(() {});
  }

  void openTracking() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => TrackingPage(repo)),
  );

  void select(int index) {
    if (index == tab) return;
    HapticFeedback.selectionClick();
    final reduce =
        PreferencesScope.of(context).reduceMotion ||
        MediaQuery.disableAnimationsOf(context);
    if (reduce || (index - tab).abs() > 1) {
      pages.jumpToPage(index);
    } else {
      pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 180),
        curve: gmEase,
      );
    }
    setState(() => tab = index);
  }

  @override
  void dispose() {
    monitor.removeListener(connectionChanged);
    monitor.dispose();
    repo.dispose();
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expanded = MediaQuery.sizeOf(context).width >= 700;
    final brandedPage = tab <= 1;
    final preferences = PreferencesScope.of(context);
    final reduce =
        preferences.reduceMotion || MediaQuery.disableAnimationsOf(context);
    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
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
    final content = Column(
      children: [
        if (loading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: refresh,
            notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
            child: ListenableBuilder(
              listenable: repo,
              builder: (c, _) => PageView(
                controller: pages,
                onPageChanged: (index) => setState(() => tab = index),
                physics: reduce ? const NeverScrollableScrollPhysics() : null,
                children: [
                  HomePage(
                    repo: repo,
                    onOpen: open,
                    onVisits: () => select(1),
                    onMaterials: () => select(2),
                    onTracking: openTracking,
                  ),
                  KeepAlivePage(
                    child: VisitsPage(repo: repo, onOpen: open),
                  ),
                  KeepAlivePage(
                    child: CatalogPage(repo: repo, onUse: open),
                  ),
                  KeepAlivePage(
                    child: SettingsPage(
                      session: widget.session,
                      monitor: monitor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    return PopScope(
      canPop: tab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) select(0);
      },
      child: Stack(
        children: [
          if (brandedPage)
            Positioned.fill(
              child: Image.asset(
                'assets/login-white-marble-v2.jpg',
                fit: BoxFit.cover,
                color: Colors.white.withValues(alpha: .82),
                colorBlendMode: BlendMode.srcOver,
              ),
            ),
          Scaffold(
            backgroundColor: brandedPage ? Colors.transparent : null,
            appBar: AppBar(
              toolbarHeight: brandedPage ? 96 : null,
              backgroundColor: brandedPage ? Colors.transparent : null,
              elevation: 0,
              flexibleSpace: brandedPage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipPath(
                          clipper: _HeaderWaveClipper(),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/login-navy-marble.jpg',
                                fit: BoxFit.cover,
                              ),
                              Container(color: gmNavy.withValues(alpha: .22)),
                            ],
                          ),
                        ),
                        const IgnorePointer(
                          child: CustomPaint(painter: _HeaderWavePainter()),
                        ),
                      ],
                    )
                  : null,
              title: brandedPage
                  ? const Brand(onNavy: true)
                  : Text(
                      const ['Inicio', 'Visitas', 'Materiales', 'Cuenta'][tab],
                    ),
              actions: [
                ListenableBuilder(
                  listenable: monitor,
                  builder: (context, _) {
                    final state = monitor.state;
                    final connected = state == ServerState.online;
                    final checking = state == ServerState.checking;
                    return IconButton(
                      tooltip: widget.session.demo
                          ? 'Actualizar datos de la demo'
                          : checking
                          ? 'Comprobando conexión con la web'
                          : connected
                          ? 'Conectado con la web G&M. Toca para actualizar'
                          : 'Sin conexión con la web. Toca para reintentar',
                      onPressed: loading
                          ? null
                          : () async {
                              await monitor.check();
                              await refresh();
                            },
                      icon: Icon(
                        widget.session.demo
                            ? Icons.sync
                            : checking
                            ? Icons.cloud_sync_outlined
                            : connected
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_off_rounded,
                        color: widget.session.demo
                            ? Colors.white
                            : checking
                            ? const Color(0xffefc967)
                            : connected
                            ? const Color(0xff51de99)
                            : const Color(0xffff777b),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: SafeArea(
              bottom: false,
              child: expanded
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: tab,
                          onDestinationSelected: select,
                          labelType: NavigationRailLabelType.all,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.home_outlined),
                              label: Text('Inicio'),
                            ),
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
                        Expanded(child: content),
                      ],
                    )
                  : content,
            ),
            floatingActionButton: tab == 1 && widget.session.canEdit
                ? FloatingActionButton.extended(
                    onPressed: () => open(null),
                    backgroundColor: gmRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                      side: const BorderSide(color: gmGold, width: 2),
                    ),
                    icon: const Icon(Icons.add, size: 25),
                    label: const Text(
                      'Nueva visita',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  )
                : null,
            bottomNavigationBar: expanded
                ? null
                : brandedPage
                ? _HomeNavigationBar(selected: tab, onSelect: select)
                : NavigationBar(
                    animationDuration: Duration(milliseconds: reduce ? 0 : 180),
                    selectedIndex: tab,
                    onDestinationSelected: select,
                    destinations: destinations,
                  ),
          ),
        ],
      ),
    );
  }
}

Path _headerWaveEdge(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(0, h - 46)
    ..cubicTo(w * .13, h - 8, w * .24, h - 4, w * .39, h - 16)
    ..cubicTo(w * .65, h - 38, w * .85, h - 29, w, h - 5);
}

class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _headerWaveEdge(size)
    ..lineTo(size.width, 0)
    ..lineTo(0, 0)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HeaderWavePainter extends CustomPainter {
  const _HeaderWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final redRibbon = Path()
      ..moveTo(0, h - 46)
      ..cubicTo(w * .13, h - 8, w * .24, h - 4, w * .39, h - 16)
      ..cubicTo(w * .22, h + 10, w * .09, h - 9, 0, h - 22)
      ..close();
    canvas.drawPath(
      redRibbon,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xfff10022), gmRed],
        ).createShader(Offset.zero & size),
    );

    final goldRibbon = Path()
      ..moveTo(w * .28, h - 9)
      ..cubicTo(w * .51, h - 35, w * .78, h - 40, w, h - 5)
      ..lineTo(w, h + 8)
      ..cubicTo(w * .79, h - 32, w * .52, h - 28, w * .28, h - 9)
      ..close();
    canvas.drawPath(
      goldRibbon,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xfff9df93), gmGold, Color(0xffe8b44d)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeNavigationBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _HomeNavigationBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: gmNavy,
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 16)],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 5),
        child: Row(
          children: List.generate(4, (i) {
            const icons = [
              Icons.home,
              Icons.assignment_outlined,
              Icons.layers_outlined,
              Icons.person_outline,
            ];
            const labels = ['Inicio', 'Visitas', 'Materiales', 'Cuenta'];
            final active = selected == i;
            return Expanded(
              child: Material(
                color: active ? gmRed : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => onSelect(i),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icons[i], color: Colors.white, size: 25),
                        const SizedBox(height: 3),
                        Text(
                          labels[i],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

class KeepAlivePage extends StatefulWidget {
  final Widget child;
  const KeepAlivePage({super.key, required this.child});
  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

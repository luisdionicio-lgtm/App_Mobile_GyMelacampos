import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api.dart';
import '../../../core/connection.dart';
import '../../../core/preferences.dart';
import '../../../core/theme.dart';
import '../../catalog/presentation/catalog_page.dart';
import '../../settings/presentation/settings_page.dart';
import '../../visits/data/visit_repository.dart';
import '../../visits/domain/visit.dart';
import '../../visits/presentation/visit_editor.dart';
import '../../visits/presentation/visits_page.dart';
import 'home_page.dart';
import 'widgets.dart';

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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VisitEditor(repo, existing: visit)),
    );
    if (mounted) setState(() {});
  }

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
        ConnectionStrip(monitor, demo: widget.session.demo),
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
                  HomePage(repo: repo, onOpen: open, onVisits: () => select(1)),
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
      child: Scaffold(
        appBar: AppBar(
          title: const Brand(),
          actions: [
            IconButton(
              tooltip: 'Actualizar datos',
              onPressed: loading
                  ? null
                  : () async {
                      await monitor.check();
                      await refresh();
                    },
              icon: const Icon(Icons.sync),
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
                icon: const Icon(Icons.add),
                label: const Text('Nueva visita'),
              )
            : null,
        bottomNavigationBar: expanded
            ? null
            : NavigationBar(
                animationDuration: Duration(milliseconds: reduce ? 0 : 180),
                selectedIndex: tab,
                onDestinationSelected: select,
                destinations: destinations,
              ),
      ),
    );
  }
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

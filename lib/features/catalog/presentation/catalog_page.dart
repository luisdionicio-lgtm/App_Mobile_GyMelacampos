import 'package:flutter/material.dart';
import '../../../core/brand_ui.dart';
import '../../../core/inner_ui.dart';
import '../../../core/preferences.dart';
import '../../../core/theme.dart';
import '../../visits/data/visit_repository.dart';
import '../../visits/domain/visit.dart';

class CatalogPage extends StatefulWidget {
  final VisitRepository repo;
  final void Function(Visit) onUse;
  const CatalogPage({super.key, required this.repo, required this.onUse});
  @override
  State<CatalogPage> createState() => _CatalogState();
}

class _CatalogState extends State<CatalogPage> {
  String search = '', category = 'Mármol';
  bool favoritesOnly = false;
  bool gridView = true;
  final searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget heading() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 54, 20, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Nuestro ',
                          style: TextStyle(color: gmNavy),
                        ),
                        TextSpan(
                          text: 'catálogo',
                          style: TextStyle(color: gmRed),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Explora los materiales disponibles en G&M.',
                    style: TextStyle(fontSize: 14, color: Color(0xff626d78)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3006233c),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            onChanged: (v) => setState(() => search = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar material por nombre o veta...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xff64707c),
              ),
              prefixIcon: const Icon(Icons.search, color: gmNavy),
              suffixIcon: search.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: () {
                        searchController.clear();
                        setState(() => search = '');
                      },
                      icon: const Icon(Icons.close, color: gmNavy),
                    ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: .92),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
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
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CatalogFilter(
                label: 'Favoritos',
                icon: favoritesOnly ? Icons.favorite : Icons.favorite_border,
                selected: favoritesOnly,
                onTap: () => setState(() => favoritesOnly = !favoritesOnly),
              ),
              for (final value in [
                'Mármol',
                'Granito',
                'Cuarzo',
                'Sinterizada',
              ]) ...[
                const SizedBox(width: 9),
                _CatalogFilter(
                  label: value,
                  icon: category == value ? Icons.check : _categoryIcon(value),
                  selected: category == value,
                  onTap: () => setState(() => category = value),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
  Widget tile(Map<String, dynamic> material, AppPreferences prefs) {
    final favorite = prefs.favorites.contains(material['id']);
    return Material(
      color: gmGold,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: gmNavy,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MaterialPage(
                  material,
                  repo: widget.repo,
                  onUse: widget.onUse,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'material-${material['id']}',
                        child: ClipRect(
                          child: Transform.scale(
                            // Algunas fotos de cuarzo incluyen un marco blanco
                            // dentro del propio archivo del catálogo.
                            scale: material['cat'] == 'Cuarzo' ? 1.12 : 1,
                            child: Image.network(
                              '${widget.repo.session.api.endpoint}${material['img']}',
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, s) => const Center(
                                child: Icon(
                                  Icons.layers_outlined,
                                  color: gmGold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: favorite ? gmRed : gmNavy,
                          ),
                          tooltip: favorite
                              ? 'Quitar de favoritos'
                              : 'Agregar a favoritos',
                          onPressed: () => prefs.toggleFavorite(material['id']),
                          icon: Icon(
                            favorite ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 64,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: gmGold, width: 1.2)),
                    image: DecorationImage(
                      image: AssetImage('assets/login-navy-marble.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _CatalogCorner()),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 9, 18, 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              material['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.layers_outlined,
                                  color: Colors.white,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  material['cat'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesScope.of(context);
    final materials = widget.repo.materials
        .where(
          (m) =>
              (category == 'Todos' || m['cat'] == category) &&
              '${m['cat']} ${m['name']}'.toLowerCase().contains(
                search.toLowerCase(),
              ) &&
              (!favoritesOnly || prefs.favorites.contains(m['id'])),
        )
        .toList();
    return CustomScrollView(
      key: const PageStorageKey('catalog'),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: heading()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Icon(Icons.grid_view_rounded, color: gmNavy),
                const SizedBox(width: 9),
                Text(
                  '${materials.length} materiales',
                  style: const TextStyle(
                    color: Color(0xff626d78),
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                _ViewToggle(
                  icon: Icons.grid_view_rounded,
                  selected: gridView,
                  tooltip: 'Ver cuadrícula',
                  onTap: () => setState(() => gridView = true),
                ),
                const SizedBox(width: 5),
                _ViewToggle(
                  icon: Icons.view_list_rounded,
                  selected: !gridView,
                  tooltip: 'Ver lista',
                  onTap: () => setState(() => gridView = false),
                ),
              ],
            ),
          ),
        ),
        if (materials.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.all(30),
            sliver: SliverToBoxAdapter(
              child: Note(
                'No hay materiales para este filtro. Cambia la búsqueda o agrega tus favoritos.',
                icon: Icons.layers_outlined,
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          sliver: gridView
              ? SliverLayoutBuilder(
                  builder: (c, constraints) => SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.crossAxisExtent >= 700
                          ? 3
                          : 2,
                      mainAxisExtent:
                          MediaQuery.textScalerOf(context).scale(64) + 137,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 18,
                    ),
                    itemCount: materials.length,
                    itemBuilder: (c, i) => tile(materials[i], prefs),
                  ),
                )
              : SliverList.separated(
                  itemCount: materials.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (c, i) =>
                      SizedBox(height: 190, child: tile(materials[i], prefs)),
                ),
        ),
      ],
    );
  }
}

IconData _categoryIcon(String category) => switch (category) {
  'Cuarzo' => Icons.diamond_outlined,
  'Granito' => Icons.dashboard_outlined,
  _ => Icons.layers_outlined,
};

class _CatalogFilter extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _CatalogFilter({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? gmRed : Colors.white.withValues(alpha: .88),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? gmRed : gmGold),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : gmNavy),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : gmNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;
  const _ViewToggle({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: selected ? gmRed : Colors.white.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: gmGold),
          ),
          child: Icon(icon, color: selected ? Colors.white : gmNavy, size: 22),
        ),
      ),
    ),
  );
}

class _CatalogCorner extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final corner = Path()
      ..moveTo(size.width - 47, size.height)
      ..lineTo(size.width, size.height - 42)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(corner, Paint()..color = gmRed);
    canvas.drawLine(
      Offset(size.width - 50, size.height),
      Offset(size.width, size.height - 45),
      Paint()
        ..color = gmGold
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MaterialPage extends StatelessWidget {
  final Map<String, dynamic> material;
  final VisitRepository repo;
  final void Function(Visit) onUse;
  const MaterialPage(
    this.material, {
    super.key,
    required this.repo,
    required this.onUse,
  });
  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesScope.of(context);
    return Scaffold(
      appBar: gmInnerAppBar(
        title: material['cat']?.toString() ?? 'Material',
        actions: [
          IconButton(
            tooltip: 'Alternar favorito',
            onPressed: () => prefs.toggleFavorite(material['id']),
            icon: Icon(
              prefs.favorites.contains(material['id'])
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
          ),
        ],
      ),
      body: GmInnerBackground(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: gmGold, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3306233c),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Hero(
                tag: 'material-${material['id']}',
                child: Image.network(
                  '${repo.session.api.endpoint}${material['img']}',
                  height: 280,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => const SizedBox(
                    height: 160,
                    child: Center(child: Icon(Icons.layers_outlined, size: 40)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            GmInnerHeading(
              eyebrow: material['cat']?.toString() ?? 'Colección G&M',
              title: material['name']?.toString() ?? 'Material',
              subtitle: 'Conoce sus características antes de elegirlo.',
              icon: Icons.layers_outlined,
            ),
            const SizedBox(height: 18),
            GmInnerCard(
              child: Text(
                material['desc']?.toString() ?? '',
                style: const TextStyle(
                  height: 1.55,
                  color: gmNavy,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GmInnerCard(
              child: Column(
                children: [
                  for (final entry in [
                    ('Categoría', material['cat']),
                    ('Colección', material['col']),
                    ('Acabado', material['finish']),
                    ('Espesor', material['thick']),
                  ])
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        entry.$1,
                        style: const TextStyle(
                          color: Color(0xff53606b),
                          fontSize: 13,
                        ),
                      ),
                      trailing: Text(
                        entry.$2?.toString() ?? 'Por confirmar',
                        style: const TextStyle(
                          color: gmNavy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GmInnerCard(
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: gmGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ((material['pricePerM2'] as num?)?.toDouble() ?? 0) > 0
                          ? 'S/ ${material['pricePerM2']} por m²'
                          : 'Tarifa por evaluar',
                      style: const TextStyle(
                        fontFamily: 'Playfair Display',
                        color: gmNavy,
                        fontWeight: FontWeight.w700,
                        fontSize: 21,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Note(
              'La cotización utiliza las tarifas configuradas en la web. El precio final requiere revisión administrativa.',
            ),
            if (repo.session.canEdit)
              GmAction(
                onPressed: () {
                  Navigator.pop(context);
                  onUse(Visit(materialId: material['id'], material: material));
                },
                icon: Icons.check_circle_outline,
                label: 'Seleccionar para una visita',
              ),
          ],
        ),
      ),
    );
  }
}

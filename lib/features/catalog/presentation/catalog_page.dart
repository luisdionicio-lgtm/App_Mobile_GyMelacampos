import 'package:flutter/material.dart';
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
  String search = '', category = 'Todos';
  bool favoritesOnly = false;
  final searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget heading(AppPreferences prefs) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'La piedra indicada.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        const Text('Texturas y materiales del catálogo de G&M.'),
        const SizedBox(height: 20),
        TextField(
          controller: searchController,
          onChanged: (v) => setState(() => search = v),
          decoration: const InputDecoration(
            labelText: 'Buscar material',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                avatar: Icon(
                  favoritesOnly ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                ),
                label: const Text('Favoritos'),
                selected: favoritesOnly,
                onSelected: (v) => setState(() => favoritesOnly = v),
              ),
              const SizedBox(width: 8),
              for (final value in [
                'Todos',
                'Cuarzo',
                'Granito',
                'Mármol',
                'Sinterizada',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(value),
                    selected: category == value,
                    onSelected: (_) => setState(() => category = value),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
  Widget tile(Map<String, dynamic> material, AppPreferences prefs) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MaterialPage(material, repo: widget.repo, onUse: widget.onUse),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'material-${material['id']}',
                  child: Image.network(
                    '${widget.repo.session.api.base}${material['img']}',
                    height: 135,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => SizedBox(
                      height: 135,
                      child: Center(
                        child: Icon(
                          Icons.layers_outlined,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filledTonal(
                    tooltip: prefs.favorites.contains(material['id'])
                        ? 'Quitar de favoritos'
                        : 'Agregar a favoritos',
                    onPressed: () => prefs.toggleFavorite(material['id']),
                    icon: Icon(
                      prefs.favorites.contains(material['id'])
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                material['name'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                material['cat'],
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
          ],
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
        SliverToBoxAdapter(child: heading(prefs)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${materials.length} materiales',
              style: Theme.of(context).textTheme.labelLarge,
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
          sliver: SliverLayoutBuilder(
            builder: (c, constraints) => SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.crossAxisExtent >= 700 ? 3 : 2,
                mainAxisExtent:
                    MediaQuery.textScalerOf(context).scale(90) + 145,
                crossAxisSpacing: 12,
                mainAxisSpacing: 18,
              ),
              itemCount: materials.length,
              itemBuilder: (c, i) => tile(materials[i], prefs),
            ),
          ),
        ),
      ],
    );
  }
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
    final prefs = PreferencesScope.of(context),
        scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(material['cat']),
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
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Hero(
              tag: 'material-${material['id']}',
              child: Image.network(
                '${repo.session.api.base}${material['img']}',
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
          Text(
            material['name'],
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            material['desc'] ?? '',
            style: TextStyle(height: 1.65, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          for (final entry in [
            ('Categoría', material['cat']),
            ('Colección', material['col']),
            ('Acabado', material['finish']),
            ('Espesor', material['thick']),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.$1),
              trailing: Text(
                entry.$2 ?? 'Por confirmar',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          const Divider(height: 32),
          Text(
            (material['pricePerM2'] as num) > 0
                ? 'S/ ${material['pricePerM2']} por m²'
                : 'Tarifa por evaluar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Note(
            'La cotización utiliza las tarifas configuradas en la web. El precio final requiere revisión administrativa.',
          ),
          if (repo.session.canEdit)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onUse(Visit(materialId: material['id'], material: material));
              },
              icon: const Icon(Icons.add),
              label: const Text('Usar en nueva visita'),
            ),
        ],
      ),
    );
  }
}

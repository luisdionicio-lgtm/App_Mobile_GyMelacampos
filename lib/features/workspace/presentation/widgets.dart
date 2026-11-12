import 'package:flutter/material.dart';
import '../../../core/brand_ui.dart';
import '../../../core/connection.dart';
import '../../visits/domain/visit.dart';

class ConnectionStrip extends StatelessWidget {
  final ConnectionMonitor monitor;
  final bool demo;
  const ConnectionStrip(this.monitor, {super.key, this.demo = false});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: monitor,
    builder: (c, _) {
      final scheme = Theme.of(c).colorScheme;
      final ready = monitor.state == ServerState.online;
      return Semantics(
        liveRegion: true,
        child: Material(
          color: ready ? scheme.surfaceContainerLow : scheme.errorContainer,
          child: InkWell(
            onTap: monitor.check,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    ready
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_off_outlined,
                    size: 17,
                    color: ready ? scheme.primary : scheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      monitor.state == ServerState.checking
                          ? 'Comprobando conexión…'
                          : ready
                          ? (demo
                                ? 'Demo local · catálogo conectado'
                                : 'Conectado con la web G&M')
                          : 'Sin conexión · tus borradores están guardados',
                      style: TextStyle(
                        fontSize: 12,
                        color: ready
                            ? scheme.onSurfaceVariant
                            : scheme.onErrorContainer,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.refresh,
                    size: 17,
                    color: ready
                        ? scheme.onSurfaceVariant
                        : scheme.onErrorContainer,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class VisitTile extends StatelessWidget {
  final Visit visit;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final String? serverBase;
  const VisitTile(
    this.visit, {
    super.key,
    required this.onTap,
    this.onDelete,
    this.serverBase,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final img = visit.material?['img']?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: gmCream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: img != null && serverBase != null
                      ? Image.network(
                          '$serverBase$img',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.layers_outlined, color: gmGold),
                        )
                      : const Icon(Icons.layers_outlined, color: gmGold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.client.isEmpty
                            ? 'Visita sin nombre'
                            : visit.client,
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              color: gmNavy,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${visit.project} · ${visit.material?['name'] ?? 'Sin material'}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 9),
                      GmStatus(visit.status),
                    ],
                  ),
                ),
                if (onDelete != null)
                  PopupMenuButton<String>(
                    tooltip: 'Opciones de borrador',
                    onSelected: (_) => onDelete!(),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar borrador'),
                      ),
                    ],
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Icon(Icons.chevron_right),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

import 'package:flutter/material.dart';
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
  const VisitTile(this.visit, {super.key, required this.onTap, this.onDelete});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    visit.project == 'Baño'
                        ? Icons.bathtub_outlined
                        : Icons.countertops_outlined,
                    color: scheme.onPrimaryContainer,
                  ),
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
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${visit.project} · ${visit.area.toStringAsFixed(2)} m²',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Icon(
                            visit.synced
                                ? Icons.cloud_done_outlined
                                : Icons.edit_note,
                            size: 15,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              visit.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
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

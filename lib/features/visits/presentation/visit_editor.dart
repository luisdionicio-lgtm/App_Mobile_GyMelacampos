import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme.dart';
import '../domain/visit.dart';
import '../data/visit_repository.dart';
import 'sketch.dart';
import 'proforma.dart';

class VisitEditor extends StatefulWidget {
  final VisitRepository repository;
  final Visit? existing;
  const VisitEditor(this.repository, {super.key, this.existing});
  @override
  State<VisitEditor> createState() => _EditorState();
}

class _EditorState extends State<VisitEditor> {
  late Visit visit;
  final form = GlobalKey<FormState>();
  final scrollController = ScrollController();
  Timer? _autosave;
  bool busy = false;
  int step = 0;
  String? imageUrl;
  late final TextEditingController client, phone, location, notes;
  VisitRepository get repo => widget.repository;
  @override
  void initState() {
    super.initState();
    visit = widget.existing == null
        ? Visit()
        : Visit.fromJson(widget.existing!.toJson());
    client = TextEditingController(text: visit.client);
    phone = TextEditingController(text: visit.phone);
    location = TextEditingController(text: visit.location);
    notes = TextEditingController(text: visit.notes);
    if (visit.imageFile != null) {
      imageUrl =
          '${repo.session.api.base}/api/mobile/visits/${visit.id}/files/${visit.imageFile}';
    }
  }

  @override
  void dispose() {
    _autosave?.cancel();
    if (!visit.synced) {
      collect();
      unawaited(repo.save(visit));
    }
    for (final c in [client, phone, location, notes]) {
      c.dispose();
    }
    scrollController.dispose();
    super.dispose();
  }

  void queueSave() {
    if (visit.synced) return;
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        collect();
        unawaited(repo.save(visit));
      }
    });
  }

  void collect() {
    visit.client = client.text.trim();
    visit.phone = phone.text.trim();
    visit.location = location.text.trim();
    visit.notes = notes.text.trim();
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> preview() async {
    if (visit.synced) {
      setState(() => step = 1);
      if (scrollController.hasClients) scrollController.jumpTo(0);
      return;
    }
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    collect();
    if (visit.materialId.isEmpty) {
      showError(context, 'Selecciona un material del catálogo');
      return;
    }
    await run(() async {
      await repo.save(visit);
      if (repo.session.demo) {
        final m = repo.materials.firstWhere((m) => m['id'] == visit.materialId);
        visit.material = m;
        final quantity = visit.unit == 'ML' ? visit.linear : visit.area;
        final rate = visit.unit == 'ML'
            ? (m['cat'] == 'Granito' ? 450.0 : 0.0)
            : (m['pricePerM2'] as num?)?.toDouble() ?? 0;
        visit.preview = {
          'code': 'DEMO-${visit.id.substring(0, 8)}',
          'preliminary': rate > 0
              ? {
                  'amount': double.parse((quantity * rate).toStringAsFixed(2)),
                  'rate': rate,
                  'unit': visit.unit,
                  'quantity': quantity,
                  'assemblyIncluded':
                      visit.unit == 'ML' && m['cat'] == 'Granito',
                }
              : null,
        };
        await repo.save(visit);
      } else {
        await repo.calculate(visit);
      }
      if (mounted) {
        setState(() => step = 1);
        if (scrollController.hasClients) scrollController.jumpTo(0);
      }
    });
  }

  Future<void> photograph(ImageSource source) async {
    await run(() async {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1800,
      );
      if (image != null) {
        final directory = await getApplicationSupportDirectory();
        final saved = await File(
          image.path,
        ).copy("${directory.path}/${visit.id}.jpg");
        visit.photo = saved.path;
        await repo.save(visit);
      }
    });
  }

  Future<void> saveToAdmin() async {
    if (repo.session.demo) {
      collect();
      await repo.save(visit);
      if (mounted) Navigator.pop(context);
      return;
    }
    if (visit.synced) {
      Navigator.pop(context);
      return;
    }
    if (!form.currentState!.validate()) return;
    collect();
    if (visit.materialId.isEmpty) {
      showError(
        context,
        'Selecciona un material para guardar la cotización en administración.',
      );
      return;
    }
    await repo.save(visit);
    await send();
    if (mounted && visit.synced && visit.photo == null) Navigator.pop(context);
  }

  Future<void> send() async {
    await run(() async {
      await repo.send(visit);
      if (visit.photo != null) {
        await repo.session.api.photo(visit.id, visit.photo!);
        visit.photo = null;
        await repo.save(visit);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita enviada al administrador para revisión'),
          ),
        );
      }
    });
  }

  Future<void> generate() async {
    if (repo.session.demo) {
      showError(
        context,
        'La demo genera bosquejos y proformas locales. Para generar una imagen IA ingresa con una cuenta de trabajador.',
      );
      return;
    }
    await run(() async {
      if (!visit.synced) {
        await repo.send(visit);
      }
      final result = await repo.session.api.call(
        '/mobile/visits/${visit.id}/image',
        method: 'POST',
      );
      visit.imageFile = result['fileId'];
      imageUrl =
          '${repo.session.api.base}/api/mobile/visits/${visit.id}/files/${visit.imageFile}';
      await repo.save(visit);
    });
  }

  Widget field(
    String label,
    TextEditingController c, {
    TextInputType? keyboard,
    int maxLines = 1,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      readOnly: visit.synced,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: (v) => required && (v == null || v.trim().length < 2)
          ? 'Completa este dato'
          : null,
    ),
  );
  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 18),
    child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
  );
  @override
  Widget build(BuildContext context) {
    final editable = repo.session.canEdit && !visit.synced;
    return Scaffold(
      appBar: AppBar(
        title: Text(step == 0 ? 'Visita técnica' : 'Propuesta del proyecto'),
        actions: [
          if (step == 0)
            TextButton(
              onPressed: busy ? null : saveToAdmin,
              child: Text(
                repo.session.demo
                    ? 'Guardar demo'
                    : visit.synced
                    ? 'Cerrar'
                    : 'Guardar en admin',
              ),
            ),
        ],
      ),
      bottomNavigationBar: step == 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
                child: FilledButton.icon(
                  onPressed: busy ? null : preview,
                  icon: const Icon(Icons.architecture),
                  label: const Text('Generar bosquejo y proforma'),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
            children: [
              if (repo.session.demo)
                const Note(
                  'DEMO · Solo en este dispositivo. Los datos de ejemplo no se envían a la web.',
                  icon: Icons.science_outlined,
                ),
              if (visit.synced)
                Note(
                  '${visit.status} · Registro enviado a la web. El administrador revisa las medidas.',
                ),
              if (busy) const LinearProgressIndicator(),
              if (step == 0) ...[
                heading('El proyecto'),
                field('Nombre del cliente', client),
                TextFormField(
                  controller: phone,
                  readOnly: visit.synced,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  validator: (v) =>
                      RegExp(r'^\+?[\d ()-]{7,30}$').hasMatch(v ?? '')
                      ? null
                      : 'Escribe un teléfono válido',
                ),
                const SizedBox(height: 16),
                field('Dirección o distrito', location),
                DropdownButtonFormField<String>(
                  initialValue: visit.project,
                  decoration: const InputDecoration(labelText: 'Ambiente'),
                  items: ['Baño', 'Cocina', 'Otro']
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: editable
                      ? (v) => setState(() => visit.project = v!)
                      : null,
                ),
                heading('Medidas de las piezas'),
                const Note(
                  'Largo y ancho en metros; espesor en centímetros. Agrega cada encimera, zócalo o pared como una pieza rectangular independiente.',
                ),
                for (int i = 0; i < visit.pieces.length; i++)
                  pieceForm(i, editable),
                if (editable && visit.pieces.length < 30)
                  OutlinedButton.icon(
                    onPressed: () => setState(
                      () => visit.pieces.add(
                        Piece(label: 'Pieza ${visit.pieces.length + 1}'),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar pieza'),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Área neta: ${visit.area.toStringAsFixed(3)} m² · ${visit.linear.toStringAsFixed(2)} ML',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                heading('El material'),
                if (repo.materials.isEmpty)
                  const Note(
                    'Catálogo no disponible. Comprueba la conexión al servidor.',
                  ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue:
                      repo.materials.any((m) => m['id'] == visit.materialId)
                      ? visit.materialId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Material del catálogo',
                  ),
                  items: repo.materials
                      .map(
                        (m) => DropdownMenuItem<String>(
                          value: m['id'],
                          child: Text(
                            '${m['cat']} · ${m['name']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: editable
                      ? (value) => setState(() {
                          visit.materialId = value!;
                          visit.material = repo.materials.firstWhere(
                            (m) => m['id'] == value,
                          );
                        })
                      : null,
                ),
                if (visit.material != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '${repo.session.api.base}${visit.material!['img']}',
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => const SizedBox(
                        height: 60,
                        child: Center(child: Icon(Icons.image_outlined)),
                      ),
                    ),
                  ),
                  Text(
                    '${visit.material?['name']} · ${visit.material?['cat']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: visit.unit,
                  decoration: const InputDecoration(
                    labelText: 'Unidad de cotización',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'm²',
                      child: Text('m² · área neta de todas las piezas'),
                    ),
                    DropdownMenuItem(
                      value: 'ML',
                      child: Text('ML · largo total de las piezas'),
                    ),
                  ],
                  onChanged: editable
                      ? (v) => setState(() => visit.unit = v!)
                      : null,
                ),
                const Note(
                  'Se aplican las tarifas de la web. Los materiales sin precio quedan por evaluar. El área no incluye merma ni optimización de cortes.',
                ),
                heading('Evidencias y detalles'),
                field(
                  'Observaciones, cortes y acabados',
                  notes,
                  maxLines: 3,
                  required: false,
                ),
                if (visit.photo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Image.file(
                      File(visit.photo!),
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (editable)
                  Wrap(
                    spacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => photograph(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Tomar foto'),
                      ),
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => photograph(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galería'),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                const Note(
                  "El borrador se guarda automáticamente en este teléfono. Usa «Guardar en admin» para enviar medidas y cotización a la web.",
                  icon: Icons.save_outlined,
                ),
              ] else ...[
                heading(visit.project),
                Text('${visit.client} · ${visit.location}'),
                const SizedBox(height: 10),
                Text(
                  '${visit.material?['cat']} · ${visit.material?['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                heading('Bosquejo de mediciones'),
                Sketch(visit),
                const Note(
                  'Vista superior de piezas independientes. Revisa huecos, uniones y tolerancias antes de fabricar.',
                ),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Proforma preliminar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        visit.preview?['preliminary'] == null
                            ? 'Por evaluar'
                            : 'S/ ${(visit.preview!['preliminary']['amount'] as num).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${visit.area.toStringAsFixed(3)} m² · ${visit.linear.toStringAsFixed(2)} ML',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        visit.preview?['preliminary'] == null
                            ? 'El administrador debe configurar o confirmar la tarifa.'
                            : '${visit.preview!['preliminary']['quantity']} ${visit.unit} × S/ ${visit.preview!['preliminary']['rate']}',
                      ),
                      if (visit.preview?['preliminary']?['assemblyIncluded'] ==
                          true)
                        const Text('Incluye armado e instalación.'),
                      const SizedBox(height: 8),
                      const Text(
                        'Sujeta a revisión administrativa.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => run(() async {
                          await shareProforma(visit, demo: repo.session.demo);
                        }),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Compartir proforma PDF'),
                ),
                heading('Imagen referencial'),
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl!,
                      headers: repo.session.api.cookie == null
                          ? {}
                          : {'Cookie': repo.session.api.cookie!},
                      errorBuilder: (_, e, s) => const Note(
                        'No se pudo cargar la imagen. Revisa tu sesión.',
                      ),
                    ),
                  ),
                const Note(
                  'La IA representa el ambiente y material elegidos. Las proporciones son orientativas; no sustituye el bosquejo ni un plano de fabricación. Requiere conexión y una clave válida en el servidor.',
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : generate,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    busy ? 'Procesando…' : 'Generar imagen referencial',
                  ),
                ),
                const SizedBox(height: 24),
                if (!visit.synced && !repo.session.demo)
                  FilledButton.icon(
                    onPressed: busy ? null : send,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Enviar visita al administrador'),
                  ),
                if (visit.synced && visit.photo != null)
                  FilledButton(
                    onPressed: busy ? null : send,
                    child: const Text('Reintentar envío de foto'),
                  ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          setState(() => step = 0);
                          if (scrollController.hasClients) {
                            scrollController.jumpTo(0);
                          }
                        },
                  child: Text(
                    visit.synced ? 'Ver datos de la visita' : 'Editar medidas',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget pieceForm(int index, bool editable) {
    final p = visit.pieces[index];
    Widget number(
      String name,
      double value,
      void Function(double) update, {
      bool integer = false,
    }) => TextFormField(
      key: ValueKey('${visit.id}-$index-$name'),
      initialValue: value.toString(),
      enabled: editable,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: name),
      validator: (v) {
        final n = double.tryParse((v ?? '').replaceAll(',', '.'));
        return n == null ||
                !n.isFinite ||
                n <= 0 ||
                n > (name == 'Espesor (cm)' ? 30 : 100) ||
                (integer && n != n.roundToDouble())
            ? 'Valor válido > 0'
            : null;
      },
      onChanged: (v) {
        final n = double.tryParse(v.replaceAll(',', '.'));
        if (n != null && n.isFinite && n > 0) setState(() => update(n));
      },
    );
    return Padding(
      key: ValueKey(p),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: p.label,
                  enabled: editable,
                  decoration: InputDecoration(labelText: 'Pieza ${index + 1}'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nombra la pieza' : null,
                  onChanged: (v) => p.label = v,
                ),
              ),
              if (editable && visit.pieces.length > 1)
                IconButton(
                  tooltip: 'Quitar pieza',
                  onPressed: () => setState(() => visit.pieces.removeAt(index)),
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: number('Largo (m)', p.length, (v) => p.length = v),
              ),
              const SizedBox(width: 12),
              Expanded(child: number('Ancho (m)', p.width, (v) => p.width = v)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: number(
                  'Espesor (cm)',
                  p.thickness,
                  (v) => p.thickness = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: number(
                  'Cantidad',
                  p.quantity.toDouble(),
                  (v) => p.quantity = v.toInt(),
                  integer: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

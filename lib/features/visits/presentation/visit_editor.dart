import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/brand_ui.dart';
import '../../../core/inner_ui.dart';
import '../../catalog/presentation/catalog_page.dart';
import 'proposal_preview.dart';
import '../../../core/theme.dart';
import '../domain/visit.dart';
import '../data/visit_repository.dart';
import '../data/material_texture.dart';
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
    for (final c in [client, phone, location, notes]) {
      c.addListener(queueSave);
    }
    if (visit.imageFile != null) {
      imageUrl =
          '${repo.session.api.endpoint}/api/mobile/visits/${visit.id}/files/${visit.imageFile}';
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
      setState(() => step = 3);
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
        setState(() => step = 3);
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
        'La demo genera propuestas locales con cotización y bosquejos. Para generar una imagen IA ingresa con una cuenta de trabajador.',
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
          '${repo.session.api.endpoint}/api/mobile/visits/${visit.id}/files/${visit.imageFile}';
      await repo.save(visit);
    });
  }

  Widget field(
    String label,
    TextEditingController c, {
    IconData? icon,
    TextInputType? keyboard,
    int maxLines = 1,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      readOnly: visit.synced,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon, color: gmGold),
      ),
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: (v) => required && (v == null || v.trim().length < 2)
          ? 'Completa este dato'
          : null,
    ),
  );
  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 18),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Playfair Display',
        color: gmNavy,
        fontSize: 25,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  void moveTo(int nextStep) {
    FocusScope.of(context).unfocus();
    collect();
    if (!visit.synced) unawaited(repo.save(visit));
    setState(() => step = nextStep);
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  Future<void> next() async {
    if (step == 0 || step == 1) {
      if (!form.currentState!.validate()) return;
      moveTo(step + 1);
    } else if (step == 2) {
      await preview();
    } else if (step == 3) {
      moveTo(4);
    }
  }

  void openPdf() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProposalPreviewPage(
        visit,
        serverBase: repo.session.api.base,
        demo: repo.session.demo,
      ),
    ),
  );

  Future<void> pickMaterial() async {
    final selected = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: gmInnerAppBar(title: 'Elegir material'),
          body: CatalogPage(
            repo: repo,
            onUse: (choice) => Navigator.pop(context, choice.material),
          ),
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      visit.material = selected;
      visit.materialId = selected['id'];
    });
    queueSave();
    unawaited(loadMaterialTexture(visit, repo.session.api.base));
  }

  Widget progress() => Padding(
    padding: const EdgeInsets.fromLTRB(3, 20, 3, 22),
    child: Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2.5,
                color: i <= step ? gmGold : const Color(0xffd3c9b8),
              ),
            ),
          InkWell(
            onTap: i < step ? () => moveTo(i) : null,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: i == step
                        ? gmRed
                        : i < step
                        ? gmNavy
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: gmGold, width: 1.5),
                    boxShadow: i == step
                        ? const [
                            BoxShadow(color: Color(0x3306233c), blurRadius: 8),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: i < step
                        ? const Icon(Icons.check, color: Colors.white, size: 17)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: i == step ? Colors.white : gmNavy,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  const ['Cliente', 'Piezas', 'Material', 'IA', 'PDF'][i],
                  style: TextStyle(
                    fontSize: 10,
                    color: i == step ? gmRed : gmNavy,
                    fontWeight: i == step ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final editable = repo.session.canEdit && !visit.synced;
    final role = repo.session.demo ? 'medicion' : repo.session.user?['role'];
    final canPropose = canGenerateProposal(role?.toString() ?? '');
    return Scaffold(
      appBar: gmInnerAppBar(
        title: const [
          'Nueva visita',
          'Piezas y medidas',
          'Material',
          'Visualizar con IA',
          'Propuesta',
        ][step],
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () =>
              step == 0 ? Navigator.pop(context) : moveTo(step - 1),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (step == 4)
            TextButton(
              onPressed: busy ? null : saveToAdmin,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
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
      bottomNavigationBar: canPropose
          ? Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: gmGold, width: 1.5)),
                boxShadow: [
                  BoxShadow(color: Color(0x2806233c), blurRadius: 14),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
                  child: GmAction(
                    onPressed: busy
                        ? null
                        : step == 4
                        ? openPdf
                        : next,
                    icon: step == 4
                        ? Icons.picture_as_pdf_outlined
                        : Icons.arrow_forward,
                    label: step == 4
                        ? 'Ver PDF completo'
                        : step == 2
                        ? 'Calcular propuesta'
                        : 'Siguiente',
                  ),
                ),
              ),
            )
          : null,
      body: GmInnerBackground(
        child: SafeArea(
          child: Theme(
            data: Theme.of(
              context,
            ).copyWith(inputDecorationTheme: gmInnerInputTheme()),
            child: Form(
              key: form,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                children: [
                  progress(),
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
                    const GmInnerHeading(
                      eyebrow: 'Paso 01 · Nueva visita',
                      title: 'Datos del',
                      accent: 'cliente',
                      subtitle:
                          'Comencemos por la persona y el espacio que visitaste.',
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 20),
                    GmInnerCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INFORMACIÓN DE CONTACTO',
                            style: TextStyle(
                              color: Color(0xffa47722),
                              letterSpacing: 1.5,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          field(
                            'Nombre del cliente',
                            client,
                            icon: Icons.person_outline,
                          ),
                          TextFormField(
                            controller: phone,
                            readOnly: visit.synced,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: gmGold,
                              ),
                            ),
                            validator: (v) =>
                                RegExp(r'^\+?[\d ()-]{7,30}$').hasMatch(v ?? '')
                                ? null
                                : 'Escribe un teléfono válido',
                          ),
                          const SizedBox(height: 16),
                          field(
                            'Dirección o distrito',
                            location,
                            icon: Icons.place_outlined,
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: visit.project,
                            decoration: const InputDecoration(
                              labelText: 'Ambiente',
                              prefixIcon: Icon(
                                Icons.home_work_outlined,
                                color: gmGold,
                              ),
                            ),
                            items: ['Baño', 'Cocina', 'Otro']
                                .map(
                                  (x) => DropdownMenuItem(
                                    value: x,
                                    child: Text(x),
                                  ),
                                )
                                .toList(),
                            onChanged: editable
                                ? (v) => setState(() => visit.project = v!)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (step == 1) ...[
                    const GmInnerHeading(
                      eyebrow: 'Paso 02 · Levantamiento',
                      title: 'Piezas y',
                      accent: 'medidas',
                      subtitle:
                          'Cada pieza conserva sus medidas y su propio bosquejo.',
                      icon: Icons.straighten_rounded,
                    ),
                    const SizedBox(height: 12),
                    const Note(
                      'Largo y ancho en metros; espesor en centímetros. Agrega cada encimera, zócalo o pared como una pieza rectangular independiente.',
                    ),
                    for (int i = 0; i < visit.pieces.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: GmInnerCard(child: pieceForm(i, editable)),
                      ),
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
                    GmInnerCard(
                      child: Row(
                        children: [
                          const Icon(Icons.square_foot_rounded, color: gmGold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${visit.area.toStringAsFixed(3)} m²  ·  ${visit.linear.toStringAsFixed(2)} ML',
                              style: const TextStyle(
                                color: gmNavy,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Sketch(visit),
                    heading('Evidencias y detalles'),
                    GmInnerCard(
                      child: field(
                        'Observaciones, cortes y acabados',
                        notes,
                        maxLines: 3,
                        required: false,
                      ),
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
                  ],
                  if (step == 2) ...[
                    const GmInnerHeading(
                      eyebrow: 'Paso 03 · Selección',
                      title: 'Elige el',
                      accent: 'material',
                      subtitle:
                          'Explora las piedras y elige la que acompañará tu propuesta.',
                      icon: Icons.layers_outlined,
                    ),
                    const SizedBox(height: 16),
                    if (editable) ...[
                      GmAction(
                        label: 'Explorar catálogo',
                        icon: Icons.search,
                        onPressed: pickMaterial,
                        gold: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (repo.materials.isEmpty)
                      const Note(
                        'Catálogo no disponible. Comprueba la conexión al servidor.',
                      ),
                    GmInnerCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue:
                                repo.materials.any(
                                  (m) => m['id'] == visit.materialId,
                                )
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
                                ? (value) {
                                    setState(() {
                                      visit.materialId = value!;
                                      visit.material = repo.materials
                                          .firstWhere((m) => m['id'] == value);
                                    });
                                    unawaited(
                                      loadMaterialTexture(
                                        visit,
                                        repo.session.api.base,
                                      ),
                                    );
                                  }
                                : null,
                          ),
                          if (visit.material != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                '${repo.session.api.endpoint}${visit.material!['img']}',
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, e, s) => const SizedBox(
                                  height: 60,
                                  child: Center(
                                    child: Icon(Icons.image_outlined),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              '${visit.material?['name']} · ${visit.material?['cat']}',
                              style: const TextStyle(
                                color: gmNavy,
                                fontFamily: 'Playfair Display',
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
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
                                child: Text(
                                  'm² · área neta de todas las piezas',
                                ),
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
                        ],
                      ),
                    ),
                  ],
                  if (step == 3) ...[
                    const GmInnerHeading(
                      eyebrow: 'Paso 04 · Inspiración',
                      title: 'Visualizar con',
                      accent: 'IA',
                      subtitle:
                          'Una vista conceptual para conversar sobre el resultado.',
                      icon: Icons.auto_awesome_outlined,
                    ),
                    const SizedBox(height: 16),
                    GmInnerCard(
                      padding: const EdgeInsets.all(7),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: imageUrl == null
                            ? Image.asset(
                                'assets/stone.png',
                                height: 230,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                imageUrl!,
                                height: 230,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                headers: repo.session.api.cookie == null
                                    ? {}
                                    : {'Cookie': repo.session.api.cookie!},
                                errorBuilder: (_, e, s) => const Note(
                                  'No se pudo cargar la imagen. Revisa tu sesión.',
                                ),
                              ),
                      ),
                    ),
                    const Note(
                      'Imagen conceptual. No reproduce las medidas exactas ni reemplaza el bosquejo técnico.',
                    ),
                    GmAction(
                      onPressed: busy ? null : generate,
                      icon: Icons.auto_awesome,
                      label: busy ? 'Procesando…' : 'Generar visualización',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Puedes continuar sin generar una imagen.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (step == 4) ...[
                    const GmInnerHeading(
                      eyebrow: 'Paso 05 · Entrega',
                      title: 'Propuesta',
                      accent: 'completa',
                      subtitle:
                          'Cotización, cliente y bosquejos en un solo PDF.',
                      icon: Icons.picture_as_pdf_outlined,
                    ),
                    const SizedBox(height: 16),
                    GmInnerCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.client,
                            style: const TextStyle(
                              color: gmNavy,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${visit.project} · ${visit.location}'),
                          if (visit.phone.isNotEmpty) Text(visit.phone),
                          const Divider(height: 22),
                          Text(
                            '${visit.material?['name'] ?? 'Material por confirmar'}',
                            style: const TextStyle(
                              color: gmNavy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${visit.pieces.length} pieza(s) · ${visit.area.toStringAsFixed(3)} m²',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (canPropose)
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('assets/login-navy-marble.jpg'),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: gmGold, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2806233c),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL ESTIMADO',
                              style: TextStyle(
                                color: gmGold,
                                letterSpacing: 2,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              visit.preview?['preliminary'] == null
                                  ? 'Por evaluar'
                                  : 'S/ ${(visit.preview!['preliminary']['amount'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Playfair Display',
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${visit.area.toStringAsFixed(3)} m² · ${visit.linear.toStringAsFixed(2)} ML',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              visit.preview?['preliminary'] == null
                                  ? 'El administrador debe configurar o confirmar la tarifa.'
                                  : '${visit.preview!['preliminary']['quantity']} ${visit.unit} × S/ ${visit.preview!['preliminary']['rate']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if (visit
                                    .preview?['preliminary']?['assemblyIncluded'] ==
                                true)
                              const Text(
                                'Incluye armado e instalación.',
                                style: TextStyle(color: Colors.white),
                              ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sujeta a revisión administrativa.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    const GmPanel(
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            color: gmRed,
                            size: 30,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'PDF único: cotización + bosquejos + datos del cliente',
                              style: TextStyle(
                                color: gmNavy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: busy || !canPropose
                          ? null
                          : () => run(() async {
                              await shareProforma(
                                visit,
                                role: role?.toString() ?? '',
                                serverBase: repo.session.api.base,
                                demo: repo.session.demo,
                              );
                            }),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Compartir propuesta completa PDF'),
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
                        visit.synced
                            ? 'Ver datos de la visita'
                            : 'Editar medidas',
                      ),
                    ),
                  ],
                ],
              ),
            ),
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

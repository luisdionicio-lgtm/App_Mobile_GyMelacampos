import 'package:uuid/uuid.dart';

class Piece {
  String label;
  double length, width, thickness;
  int quantity;
  Piece({
    this.label = 'Encimera',
    this.length = 1.2,
    this.width = .55,
    this.thickness = 2,
    this.quantity = 1,
  });
  double get area => length * width * quantity;
  double get linear => length * quantity;
  Map<String, dynamic> toJson() => {
    'label': label,
    'length': length,
    'width': width,
    'thickness': thickness,
    'quantity': quantity,
  };
  factory Piece.fromJson(Map<String, dynamic> m) => Piece(
    label: m['label'],
    length: (m['length'] as num).toDouble(),
    width: (m['width'] as num).toDouble(),
    thickness: (m['thickness'] as num?)?.toDouble() ?? 2,
    quantity: m['quantity'],
  );
}

class Visit {
  String id, client, phone, location, project, materialId, unit, notes, status;
  List<Piece> pieces;
  Map<String, dynamic>? material, preview;
  String? photo, imageFile;
  bool synced;
  Visit({
    String? id,
    this.client = '',
    this.phone = '',
    this.location = '',
    this.project = 'Baño',
    this.materialId = '',
    this.unit = 'm²',
    this.notes = '',
    this.status = 'Borrador',
    List<Piece>? pieces,
    this.material,
    this.preview,
    this.photo,
    this.imageFile,
    this.synced = false,
  }) : id = id ?? const Uuid().v4(),
       pieces = pieces ?? [Piece()];
  double get area => pieces.fold(0, (s, p) => s + p.area);
  double get linear => pieces.fold(0, (s, p) => s + p.linear);
  Map<String, dynamic> payload() => {
    'id': id,
    'client': client,
    'phone': phone,
    'location': location,
    'project': project,
    'materialId': materialId,
    'unit': unit,
    'notes': notes,
    'pieces': pieces.map((p) => p.toJson()).toList(),
  };
  Map<String, dynamic> toJson() => {
    ...payload(),
    'status': status,
    'material': material,
    'preview': preview,
    'photo': photo,
    'imageFile': imageFile,
    'synced': synced,
  };
  factory Visit.fromJson(Map<String, dynamic> m) => Visit(
    id: m['id'],
    client: m['client'],
    phone: m['phone'],
    location: m['location'],
    project: m['project'],
    materialId: m['materialId'],
    unit: m['unit'],
    notes: m['notes'] ?? '',
    status: m['status'] ?? 'Borrador',
    pieces: (m['pieces'] as List)
        .map((p) => Piece.fromJson(Map<String, dynamic>.from(p)))
        .toList(),
    material: m['material'],
    preview: m['preview'],
    photo: m['photo'],
    imageFile: m['imageFile'],
    synced: m['synced'] ?? false,
  );
}

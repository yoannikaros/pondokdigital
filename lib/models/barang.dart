class Barang {
  final int? id;
  final String nama;
  final double harga;
  final int stok;
  final String satuan;
  final String? barcode;
  final double? hargaBeli;
  final int? supplierId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Barang({
    this.id,
    required this.nama,
    required this.harga,
    required this.stok,
    required this.satuan,
    this.barcode,
    this.hargaBeli,
    this.supplierId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'harga': harga,
      'stok': stok,
      'satuan': satuan,
      'barcode': barcode,
      'harga_beli': hargaBeli,
      'supplier_id': supplierId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Barang.fromMap(Map<String, dynamic> map) {
    return Barang(
      id: map['id'],
      nama: map['nama'],
      harga: map['harga']?.toDouble() ?? 0.0,
      stok: map['stok'] ?? 0,
      satuan: map['satuan'],
      barcode: map['barcode'],
      hargaBeli: map['harga_beli']?.toDouble(),
      supplierId: map['supplier_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Barang copyWith({
    int? id,
    String? nama,
    double? harga,
    int? stok,
    String? satuan,
    String? barcode,
    double? hargaBeli,
    int? supplierId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Barang(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      harga: harga ?? this.harga,
      stok: stok ?? this.stok,
      satuan: satuan ?? this.satuan,
      barcode: barcode ?? this.barcode,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      supplierId: supplierId ?? this.supplierId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

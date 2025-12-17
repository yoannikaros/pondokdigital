class Supplier {
  final int? id;
  final String nama;
  final String? noKontak;
  final String? alamat;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier({
    this.id,
    required this.nama,
    this.noKontak,
    this.alamat,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'no_kontak': noKontak,
      'alamat': alamat,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      nama: map['nama'],
      noKontak: map['no_kontak'],
      alamat: map['alamat'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

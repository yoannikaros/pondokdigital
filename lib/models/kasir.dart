enum LevelAkses { kasir, admin }

class Kasir {
  final int? id;
  final String nama;
  final String idPengguna;
  final String password;
  final LevelAkses levelAkses;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Kasir({
    this.id,
    required this.nama,
    required this.idPengguna,
    required this.password,
    this.levelAkses = LevelAkses.kasir,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'id_pengguna': idPengguna,
      'password': password,
      'level_akses': levelAkses.name,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Kasir.fromMap(Map<String, dynamic> map) {
    return Kasir(
      id: map['id'],
      nama: map['nama'],
      idPengguna: map['id_pengguna'],
      password: map['password'],
      levelAkses: LevelAkses.values.firstWhere(
        (e) => e.name == map['level_akses']
      ),
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

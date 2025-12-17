class Karyawan {
  final int? id;
  final String nama;
  final String idPengguna;
  final String password;
  final String levelAkses;
  final String shift; // pagi, siang, malam
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Karyawan({
    this.id,
    required this.nama,
    required this.idPengguna,
    required this.password,
    required this.levelAkses,
    required this.shift,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'id_pengguna': idPengguna,
      'password': password,
      'level_akses': levelAkses,
      'shift': shift,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Karyawan.fromMap(Map<String, dynamic> map) {
    return Karyawan(
      id: map['id']?.toInt(),
      nama: map['nama'] ?? '',
      idPengguna: map['id_pengguna'] ?? '',
      password: map['password'] ?? '',
      levelAkses: map['level_akses'] ?? 'karyawan',
      shift: map['shift'] ?? 'pagi',
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Karyawan copyWith({
    int? id,
    String? nama,
    String? idPengguna,
    String? password,
    String? levelAkses,
    String? shift,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Karyawan(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      idPengguna: idPengguna ?? this.idPengguna,
      password: password ?? this.password,
      levelAkses: levelAkses ?? this.levelAkses,
      shift: shift ?? this.shift,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Karyawan{id: $id, nama: $nama, idPengguna: $idPengguna, levelAkses: $levelAkses, shift: $shift, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Karyawan &&
        other.id == id &&
        other.nama == nama &&
        other.idPengguna == idPengguna &&
        other.levelAkses == levelAkses &&
        other.shift == shift &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nama.hashCode ^
        idPengguna.hashCode ^
        levelAkses.hashCode ^
        shift.hashCode ^
        isActive.hashCode;
  }
}
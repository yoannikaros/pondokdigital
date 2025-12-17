class Santri {
  final int? id;
  final String nomorKartu;
  final String nama;
  final String nis;
  final String kelas;
  final String? pin;
  final double saldo;
  final double limitHarian;
  final DateTime createdAt;
  final DateTime updatedAt;

  Santri({
    this.id,
    required this.nomorKartu,
    required this.nama,
    required this.nis,
    required this.kelas,
    this.pin,
    this.saldo = 0.0,
    this.limitHarian = 50000.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomor_kartu': nomorKartu,
      'nama': nama,
      'nis': nis,
      'kelas': kelas,
      'pin': pin,
      'saldo': saldo,
      'limit_harian': limitHarian,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Santri.fromMap(Map<String, dynamic> map) {
    return Santri(
      id: map['id'],
      nomorKartu: map['nomor_kartu'],
      nama: map['nama'],
      nis: map['nis'],
      kelas: map['kelas'],
      pin: map['pin'],
      saldo: map['saldo']?.toDouble() ?? 0.0,
      limitHarian: map['limit_harian']?.toDouble() ?? 50000.0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Santri copyWith({
    int? id,
    String? nomorKartu,
    String? nama,
    String? nis,
    String? kelas,
    String? pin,
    double? saldo,
    double? limitHarian,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Santri(
      id: id ?? this.id,
      nomorKartu: nomorKartu ?? this.nomorKartu,
      nama: nama ?? this.nama,
      nis: nis ?? this.nis,
      kelas: kelas ?? this.kelas,
      pin: pin ?? this.pin,
      saldo: saldo ?? this.saldo,
      limitHarian: limitHarian ?? this.limitHarian,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

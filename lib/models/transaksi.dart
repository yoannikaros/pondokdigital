enum JenisTransaksi { topup, penarikan, belanja, penarikanMasal }

class Transaksi {
  final int? id;
  final String nomorKartu;
  final JenisTransaksi jenis;
  final double nominal;
  final String? keterangan;
  final String kasir;
  final Map<String, dynamic>? detailBarang;
  final DateTime createdAt;

  Transaksi({
    this.id,
    required this.nomorKartu,
    required this.jenis,
    required this.nominal,
    this.keterangan,
    required this.kasir,
    this.detailBarang,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomor_kartu': nomorKartu,
      'jenis': jenis.name,
      'nominal': nominal,
      'keterangan': keterangan,
      'kasir': kasir,
      'detail_barang': detailBarang != null ? 
        detailBarang.toString() : null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Transaksi.fromMap(Map<String, dynamic> map) {
    return Transaksi(
      id: map['id'],
      nomorKartu: map['nomor_kartu'],
      jenis: JenisTransaksi.values.firstWhere(
        (e) => e.name == map['jenis']
      ),
      nominal: map['nominal']?.toDouble() ?? 0.0,
      keterangan: map['keterangan'],
      kasir: map['kasir'],
      detailBarang: map['detail_barang'] != null ? 
        {'raw': map['detail_barang']} : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

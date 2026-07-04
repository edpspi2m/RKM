class PromoModel {
  final int id;
  final String judul;
  final String deskripsi;
  final double? hargaNormal;
  final double? hargaPromo;
  final String? tanggalMulai;
  final String? tanggalSelesai;
  final String? gambarUrl;

  const PromoModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    this.hargaNormal,
    this.hargaPromo,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.gambarUrl,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      judul: json['judul'] as String? ?? '-',
      deskripsi: json['deskripsi'] as String? ?? '',
      hargaNormal: json['harga_normal'] != null ? double.tryParse(json['harga_normal'].toString()) : null,
      hargaPromo: json['harga_promo'] != null ? double.tryParse(json['harga_promo'].toString()) : null,
      tanggalMulai: json['tanggal_mulai'] as String?,
      tanggalSelesai: json['tanggal_selesai'] as String?,
      gambarUrl: json['gambar_url'] as String?,
    );
  }
}

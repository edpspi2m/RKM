class MemberModel {
  final int id;
  final String kodeMember;
  final String nama;
  final String? noHp;
  final String? alamat;
  final String? kota;
  final String? kecamatan;
  final String? salesman;
  final double? latitude;
  final double? longitude;
  final String? belanjaTerakhir;
  final bool sudahKunjungan;

  const MemberModel({
    required this.id,
    required this.kodeMember,
    required this.nama,
    this.noHp,
    this.alamat,
    this.kota,
    this.kecamatan,
    this.salesman,
    this.latitude,
    this.longitude,
    this.belanjaTerakhir,
    this.sudahKunjungan = false,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      kodeMember: json['kode_member'] as String? ?? '-',
      nama: json['nama'] as String? ?? '-',
      noHp: json['no_hp'] as String?,
      alamat: json['alamat'] as String?,
      kota: json['kota'] as String?,
      kecamatan: json['kecamatan'] as String?,
      salesman: json['salesman'] as String?,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      belanjaTerakhir: json['belanja_terakhir'] as String?,
      sudahKunjungan: (int.tryParse(json['sudah_kunjungan']?.toString() ?? '0') ?? 0) > 0,
    );
  }
}

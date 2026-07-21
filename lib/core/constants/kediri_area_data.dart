class KediriAreaData {
  static const List<String> kecamatanKabupaten = [
    'Badas', 'Ngasem', 'Kayen Kidul', 'Gampengrejo', 'Kunjang', 'Plemahan',
    'Pagu', 'Purwoasri', 'Papar', 'Puncu', 'Kandangan', 'Kepung',
    'Plosoklaten', 'Gurah', 'Pare', 'Ngancar', 'Wates', 'Ringinrejo',
    'Kandat', 'Kras', 'Ngadiluwih', 'Tarokan', 'Banyakan', 'Grogol',
    'Mojo', 'Semen',
  ];

  static const List<String> kecamatanKota = [
    'Mojoroto', 'Kota', 'Pesantren',
  ];

  static List<String> get semuaKecamatan => [...kecamatanKabupaten, ...kecamatanKota];
}

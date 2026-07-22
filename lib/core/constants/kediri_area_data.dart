/// Data wilayah Kabupaten & Kota Kediri — desa/kelurahan LENGKAP per kecamatan.
/// Sumber: Daftar Desa Kabupaten Kediri (dokumen resmi) + kedirikota.go.id.
/// Kabupaten Kediri: 26 kecamatan. Kota Kediri: 3 kecamatan.
library kediri_area_data;

class KediriAreaData {
  KediriAreaData._();

  /// Peta kecamatan -> daftar desa/kelurahan (Kabupaten Kediri)
  static const Map<String, List<String>> kabupatenKediri = {
    'Semen': ['Bulu', 'Sidomulyo', 'Pohrubuh', 'Selopanggung', 'Kanyoran', 'Pohsarang', 'Bobang', 'Semen', 'Titik', 'Kedak', 'Pagung', 'Joho'],
    'Mojo': ['Jugo', 'Blimbing', 'Pamongan', 'Petungroto', 'Ngetrep', 'Ponggok', 'Ngadi', 'Kranding', 'Maesan', 'Kedawung', 'Ploso', 'Kraton', 'Tambibendo', 'Mojo', 'Mlati', 'Surat', 'Sukoanyar', 'Keniten', 'Mondo', 'Petok'],
    'Kandat': ['Sumberjo', 'Selosari', 'Karangrejo', 'Kandat', 'Cendono', 'Ringinsari', 'Tegalan', 'Ngletih', 'Purworejo', 'Pule', 'Blabak', 'Ngreco'],
    'Wates': ['Duwet', 'Pojok', 'Segaran', 'Gadungan', 'Wates', 'Tawang', 'Jajar', 'Tunge', 'Tempurejo', 'Plaosan', 'Karanganyar', 'Wonorejo', 'Pagu', 'Joho', 'Silir', 'Sumberagung', 'Sidomulyo', 'Janti'],
    'Ngancar': ['Sempu', 'Pandantoyo', 'Margourip', 'Bedali', 'Kunjang', 'Manggis', 'Ngancar', 'Sugihwaras', 'Babadan', 'Jagul'],
    'Gurah': ['Nglumbang', 'Blimbing', 'Ngasem', 'Bogem', 'Kranggan', 'Turus', 'Gabru', 'Wonojoyo', 'Bangkok', 'Gurah', 'Banyuanyar', 'Besuk', 'Sumbercangkring', 'Sukorejo', 'Kerkep', 'Gempolan', 'Tambakrejo', 'Tirukidul', 'Tirulor', 'Gayam', 'Adan-Adan'],
    'Pagu': ['Bulupasar', 'Wonosari', 'Kambingan', 'Tanjung', 'Wates', 'Menang', 'Tenggerkidul', 'Semanding', 'Sitimerto', 'Pagu', 'Bendo', 'Semen', 'Jagung'],
    'Purwoasri': ['Jantok', 'Pesing', 'Mranggen', 'Purwoasri', 'Wonotengah', 'Ketawang', 'Belor', 'Blawe', 'Pandansari', 'Purwodadi', 'Bulu', 'Tugu', 'Sidomulyo', 'Klampitan', 'Woromarto', 'Muneng', 'Merjoyo', 'Mekikis', 'Karangpakis', 'Dayu', 'Dawuhan', 'Kempleng', 'Sumberjo'],
    'Plemahan': ['Langenharjo', 'Tegowangi', 'Puhjarak', 'Mejono', 'Payaman', 'Bogokidul', 'Kayenlor', 'Wonokerto', 'Ngino', 'Sebet', 'Banjarejo', 'Sidowarek', 'Ringinpitu', 'Sukoharjo', 'Mojoayu', 'Plemahan', 'Mojokerep'],
    'Tarokan': ['Kalirong', 'Kaliboto', 'Bulusari', 'Tarokan', 'Kedungsari', 'Sumberduren', 'Kerep', 'Blimbing', 'Jati', 'Cengkok'],
    'Kunjang': ['Kuwik', 'Balongjeruk', 'Kapas', 'Klepek', 'Kunjang', 'Kapi', 'Tenggerlor', 'Wonorejo', 'Dungus', 'Juwet', 'Pakis', 'Parelor'],
    'Banyakan': ['Banyakan', 'Jatirejo', 'Manyaran', 'Tiron', 'Parang', 'Sendang', 'Maron', 'Ngablak', 'Jabon'],
    'Kras': ['Setonorejo', 'Pelas', 'Bleber', 'Butuh', 'Jabang', 'Mojosari', 'Rejomulyo', 'Karangtalun', 'Nyawangan', 'Purwodadi', 'Kras', 'Bendosari', 'Kanigoro', 'Krandang', 'Banjaranyar', 'Jambean'],
    'Ngadiluwih': ['Tales', 'Seketi', 'Banggle', 'Branggahan', 'Slumbung', 'Dukuh', 'Purwokerto', 'Ngadiluwih', 'Badal', 'Badalpandean', 'Rembang', 'Rembangkepuh', 'Bedug', 'Mangunrejo', 'Banjarejo', 'Wonorejo'],
    'Puncu': ['Puncu', 'Asmorobangun', 'Manggis', 'Sidomulyo', 'Watugede', 'Gadungan', 'Wonorejo', 'Satak'],
    'Plosoklaten': ['Gondang', 'Kayunan', 'Panjer', 'Jarak', 'Plosokidul', 'Plosolor', 'Brenggolo', 'Donganti', 'Kawedusan', 'Klanderan', 'Punjul', 'Pranggang', 'Sumberagung', 'Wonorejotrisulo', 'Sepawon'],
    'Badas': ['Lamong', 'Canggu', 'Bringin', 'Sekoto', 'Tunglur', 'Krecek', 'Badas', 'Blaru'],
    'Gampengrejo': ['Jongbiru', 'Putih', 'Sambirejo', 'Kepuhrejo', 'Kalibelo', 'Plosorejo', 'Turus', 'Sambiresik', 'Gampeng', 'Ngebrak', 'Wanengpaten'],
    'Grogol': ['Kalipang', 'Grogol', 'Cerme', 'Wonoasri', 'Sonorejo', 'Datengan', 'Sumberjo', 'Gambyok', 'Bakalan'],
    'Papar': ['Purwotengah', 'Kwaron', 'Minggiran', 'Pehkulon', 'Pehwetan', 'Dawuhankidul', 'Janti', 'Ngampel', 'Kedungmalang', 'Jambangan', 'Maduretno', 'Papar', 'Tanon', 'Srikaton', 'Kepuh', 'Sukomoro', 'Puhjajar'],
    'Pare': ['Sidorejo', 'Sambirejo', 'Gedangsewu', 'Sumberbendo', 'Darungan', 'Bendo', 'Pelem', 'Tulungrejo', 'Tertek', 'Pare'],
    'Kepung': ['Kebonrejo', 'Kampungbaru', 'Besowo', 'Siman', 'Brumbung', 'Kepung', 'Krenceng', 'Kencong', 'Keling', 'Damarwulan'],
    'Kandangan': ['Kemiri', 'Klampisan', 'Karangtengah', 'Kasreman', 'Jerukwangi', 'Jerukgulung', 'Jlumbang', 'Bukur', 'Kandangan', 'Banaran', 'Mlancu', 'Medowo'],
    'Ringinrejo': ['Ringinrejo', 'Batuaji', 'Deyeng', 'Dawung', 'Purwodadi', 'Sambi', 'Susuhbango', 'Selodono', 'Nambaan', 'Srikaton', 'Jemekan'],
    'Kayen Kidul': ['Baye', 'Bangsongan', 'Senden', 'Sambirobyong', 'Kayenkidul', 'Mukuh', 'Sukoharjo', 'Jambu', 'Sekaran', 'Padangan', 'Nanggungan', 'Semambung'],
    'Ngasem': ['Tugurejo', 'Sumberejo', 'Paron', 'Gogorante', 'Doko', 'Sukorejo', 'Ngasem', 'Karangrejo', 'Kwadungan', 'Nambaan', 'Toyoresmi', 'Wonocatur'],
  };

  /// Peta kecamatan -> daftar kelurahan (Kota Kediri)
  static const Map<String, List<String>> kotaKediri = {
    'Kota': ['Semampir', 'Dandangan', 'Ngadirejo', 'Pakelan', 'Pocanan', 'Banjaran', 'Jagalan', 'Kemasan', 'Kaliombo', 'Kampung Dalem', 'Ngronggo', 'Manisrenggo', 'Balowerti', 'Rejomulyo', 'Ringin Anom', 'Setono Gedong', 'Setono Pande'],
    'Mojoroto': ['Lirboyo', 'Campurejo', 'Bandar Lor', 'Dermo', 'Mrican', 'Mojoroto', 'Ngampel', 'Gayam', 'Sukorame', 'Pojok', 'Tamanan', 'Bandar Kidul', 'Banjarmelati', 'Bujel'],
    'Pesantren': ['Jamsaren', 'Bangsal', 'Burengan', 'Pesantren', 'Pakunden', 'Singonegaran', 'Tinalan', 'Banaran', 'Tosaren', 'Betet', 'Blabak', 'Bawang', 'Ngletih', 'Tempurejo', 'Ketami'],
  };

  static List<String> get semuaKecamatan => [
        ...kabupatenKediri.keys,
        ...kotaKediri.keys,
      ];

  static List<String> get kecamatanKabupaten => kabupatenKediri.keys.toList();
  static List<String> get kecamatanKota => kotaKediri.keys.toList();

  /// Ambil daftar desa/kelurahan untuk kecamatan tertentu (cari di keduanya).
  static List<String> desaUntukKecamatan(String kecamatan) {
    if (kabupatenKediri.containsKey(kecamatan)) return kabupatenKediri[kecamatan]!;
    if (kotaKediri.containsKey(kecamatan)) return kotaKediri[kecamatan]!;
    return [];
  }

  /// Tentukan kabupaten/kota berdasarkan nama kecamatan.
  static String kabupatenKotaUntuk(String kecamatan) {
    if (kabupatenKediri.containsKey(kecamatan)) return 'Kabupaten Kediri';
    if (kotaKediri.containsKey(kecamatan)) return 'Kota Kediri';
    return '-';
  }
}

class UserModel {
  final String id;
  final String nama;
  final String email;
  final String token;
  final String? jabatan;

  const UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.token,
    this.jabatan,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      nama: json['nama'] as String? ?? '-',
      email: json['email'] as String? ?? '-',
      token: json['token'] as String? ?? '',
      jabatan: json['jabatan'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'email': email,
        'token': token,
        'jabatan': jabatan,
      };
}

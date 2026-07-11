class UserModel {
  final String id;
  final String nama;
  final String username;
  final String role;
  final String token;
  final String? fotoProfil;

  const UserModel({
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
    this.token = '',
    this.fotoProfil,
  });

  String get email => username;
  String get jabatan => role;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      nama: json['nama'] as String? ?? '-',
      username: json['username'] as String? ?? '-',
      role: json['role'] as String? ?? '-',
      token: json['token'] as String? ?? '',
      fotoProfil: json['foto_profil'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'username': username,
        'role': role,
        'token': token,
        'foto_profil': fotoProfil,
      };
}

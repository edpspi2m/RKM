class UserModel {
  final String id;
  final String nama;
  final String username;
  final String role;
  final String token;

  const UserModel({
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
    this.token = '',
  });

  // Alias untuk kompatibilitas jika ada kode lama yang masih memanggil field ini
  String get email => username;
  String get jabatan => role;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      nama: json['nama'] as String? ?? '-',
      username: json['username'] as String? ?? '-',
      role: json['role'] as String? ?? '-',
      token: json['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'username': username,
        'role': role,
        'token': token,
      };
}

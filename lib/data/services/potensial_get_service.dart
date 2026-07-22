import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/member_model.dart';

class PotensialGetService {
  static const String _baseUrl = 'https://api.isreport.my.id/absen';

  Future<List<MemberModel>> fetchPotensialGet(String userId) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/potensial_get.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId}),
        )
        .timeout(const Duration(seconds: 15));

    final json = jsonDecode(response.body);
    final list = json['data'] as List<dynamic>? ?? [];
    return list.map((e) => MemberModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

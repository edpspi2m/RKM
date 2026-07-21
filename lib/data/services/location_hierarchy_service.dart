import '../../core/network/api_client.dart';
import '../models/location_hierarchy_model.dart';

class LocationHierarchyService {
  final ApiClient _apiClient;
  LocationHierarchyService(this._apiClient);

  /// Fetch semua kota/kabupaten
  Future<List<LocationHierarchyModel>> getKotas({String? region}) async {
    final params = <String, dynamic>{
      'type': 'kota',
      if (region != null) 'region': region,
    };

    final response = await _apiClient.get('/get_locations.php', queryParams: params);
    
    if (response is List) {
      return response
          .map((item) => LocationHierarchyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetch kecamatan berdasarkan kota
  Future<List<LocationHierarchyModel>> getKecamatan({required String kotaId}) async {
    final params = <String, dynamic>{
      'type': 'kecamatan',
      'parent_id': kotaId,
    };

    final response = await _apiClient.get('/get_locations.php', queryParams: params);
    
    if (response is List) {
      return response
          .map((item) => LocationHierarchyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetch desa berdasarkan kecamatan
  Future<List<LocationHierarchyModel>> getDesa({required String kecamatanId}) async {
    final params = <String, dynamic>{
      'type': 'desa',
      'parent_id': kecamatanId,
    };

    final response = await _apiClient.get('/get_locations.php', queryParams: params);
    
    if (response is List) {
      return response
          .map((item) => LocationHierarchyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Search desa berdasarkan nama (untuk filter dropdown)
  Future<List<LocationHierarchyModel>> searchDesa({
    required String query,
    String? kecamatanId,
  }) async {
    final params = <String, dynamic>{
      'type': 'desa',
      'search': query,
      if (kecamatanId != null) 'parent_id': kecamatanId,
    };

    final response = await _apiClient.get('/get_locations.php', queryParams: params);
    
    if (response is List) {
      return response
          .map((item) => LocationHierarchyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get all locations untuk region tertentu (hierarchy lengkap)
  Future<Map<String, List<LocationHierarchyModel>>> getLocationsByRegion({
    required String region,
  }) async {
    final params = <String, dynamic>{
      'region': region,
      'include_hierarchy': '1',
    };

    final response = await _apiClient.get('/get_locations.php', queryParams: params);
    
    if (response is Map) {
      final result = <String, List<LocationHierarchyModel>>{};
      
      if (response['kotas'] is List) {
        result['kotas'] = (response['kotas'] as List)
            .map((item) => LocationHierarchyModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      if (response['kecamatan'] is List) {
        result['kecamatan'] = (response['kecamatan'] as List)
            .map((item) => LocationHierarchyModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      if (response['desa'] is List) {
        result['desa'] = (response['desa'] as List)
            .map((item) => LocationHierarchyModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      
      return result;
    }
    
    return {};
  }
}

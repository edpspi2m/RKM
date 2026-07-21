class LocationHierarchyModel {
  final String id;
  final String name;
  final String type; // 'kota', 'kecamatan', 'desa'
  final String? parentId;
  final double? latitude;
  final double? longitude;
  final String region; // area wilayah sales (e.g., 'Kediri', 'Surabaya')

  const LocationHierarchyModel({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.latitude,
    this.longitude,
    required this.region,
  });

  factory LocationHierarchyModel.fromJson(Map<String, dynamic> json) {
    return LocationHierarchyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      parentId: json['parent_id'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      region: json['region'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'parent_id': parentId,
        'latitude': latitude,
        'longitude': longitude,
        'region': region,
      };
}

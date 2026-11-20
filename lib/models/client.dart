class Client {
  const Client({
    required this.id,
    required this.name,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.locationCapturedAt,
    this.isSynced = false,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final DateTime? locationCapturedAt;
  final bool isSynced;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'lat': latitude,
    'lng': longitude,
    'location_accuracy_m': locationAccuracy,
    'location_captured_at': locationCapturedAt?.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'is_synced': isSynced ? 1 : 0,
  };

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'].toString(),
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
      locationAccuracy: (map['location_accuracy_m'] as num?)?.toDouble(),
      locationCapturedAt: map['location_captured_at'] == null
          ? null
          : DateTime.parse(map['location_captured_at'] as String),
      isSynced: (map['is_synced'] as num?) == 1,
    );
  }
}

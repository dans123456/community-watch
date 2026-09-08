class Report {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime incidentAt;
  final String status;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.incidentAt,
    required this.status,
    required this.imageUrl,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory Report.fromMap(Map<String, dynamic> map) => Report(
    id: map['id'].toString(),
    userId: map['user_id'].toString(),
    title: map['title'] ?? '',
    description: map['description'] ?? '',
    category: map['category'] ?? '',
    location: map['location'] ?? '',
    incidentAt: DateTime.parse(map['incident_at'].toString()),
    status: map['status'] ?? 'Pending',
    imageUrl: map['image_url'],
    latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
    longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
    createdAt: DateTime.parse(map['created_at'].toString()),
  );
}
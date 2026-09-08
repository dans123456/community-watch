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
  final List<String> imageUrls;
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
    this.imageUrls = const [],
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory Report.fromMap(Map<String, dynamic> map) {
    final rawUrls = map['image_urls'];
    List<String> urls = [];
    if (rawUrls is List) {
      urls = rawUrls.map((e) => e.toString()).toList();
    } else if (map['image_url'] != null && map['image_url'].toString().isNotEmpty) {
      urls = [map['image_url'].toString()];
    }

    final singleUrl = map['image_url']?.toString();
    final effectiveImageUrl = (singleUrl != null && singleUrl.isNotEmpty)
        ? singleUrl
        : (urls.isNotEmpty ? urls.first : null);

    return Report(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      location: map['location'] ?? '',
      incidentAt: DateTime.tryParse(map['incident_at']?.toString() ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'Pending',
      imageUrl: effectiveImageUrl,
      imageUrls: urls.isNotEmpty ? urls : (effectiveImageUrl != null ? [effectiveImageUrl] : []),
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
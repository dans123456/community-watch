class ReportComment {
  final String id;
  final String reportId;
  final String userId;
  final String userName;
  final String comment;
  final bool isOfficial;
  final DateTime createdAt;

  ReportComment({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.isOfficial,
    required this.createdAt,
  });

  factory ReportComment.fromMap(Map<String, dynamic> map) => ReportComment(
    id: map['id'].toString(),
    reportId: map['report_id'].toString(),
    userId: map['user_id'].toString(),
    userName: map['user_name'] ?? 'Anonymous',
    comment: map['comment'] ?? '',
    isOfficial: map['is_official'] == true,
    createdAt: DateTime.parse(map['created_at'].toString()),
  );
}

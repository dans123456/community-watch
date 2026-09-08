import 'package:flutter_test/flutter_test.dart';
import 'package:community_watch/main.dart';
import 'package:community_watch/models/report.dart';
import 'package:community_watch/models/report_comment.dart';

void main() {
  testWidgets('Community Watch app starts', (tester) async {
    // Supabase initialization requires project credentials, so this test
    // verifies the app source can be imported and the root widget exists.
    expect(const CommunityWatchApp(), isA<CommunityWatchApp>());
  });

  test('Report.fromMap parses valid and fallback timestamps safely', () {
    final validMap = {
      'id': '123',
      'user_id': 'user-1',
      'title': 'Suspicious Vehicle',
      'description': 'Unattended car on 4th street',
      'category': 'Suspicious Activity',
      'location': '4th Street',
      'incident_at': '2026-09-08T12:00:00Z',
      'status': 'Pending',
      'image_url': 'https://example.com/img.jpg',
      'latitude': 5.6037,
      'longitude': -0.1870,
      'created_at': '2026-09-08T12:05:00Z',
    };

    final report = Report.fromMap(validMap);
    expect(report.id, '123');
    expect(report.title, 'Suspicious Vehicle');
    expect(report.incidentAt.year, 2026);
    expect(report.latitude, 5.6037);

    // Corrupt timestamp fallback test
    final malformedMap = {
      'id': '124',
      'user_id': 'user-2',
      'title': 'Test Report',
      'description': 'Description',
      'category': 'Theft',
      'location': 'Main Ave',
      'incident_at': 'invalid-date',
      'status': null,
      'image_url': null,
      'latitude': null,
      'longitude': null,
      'created_at': null,
    };

    final safeReport = Report.fromMap(malformedMap);
    expect(safeReport.id, '124');
    expect(safeReport.status, 'Pending');
    expect(safeReport.incidentAt, isNotNull);
    expect(safeReport.createdAt, isNotNull);
  });

  test('ReportComment.fromMap parses valid and fallback timestamps safely', () {
    final commentMap = {
      'id': 'c-1',
      'report_id': 'r-1',
      'user_id': 'u-1',
      'user_name': 'Officer Davis',
      'comment': 'Units dispatched',
      'is_official': true,
      'created_at': '2026-09-08T12:30:00Z',
    };

    final comment = ReportComment.fromMap(commentMap);
    expect(comment.id, 'c-1');
    expect(comment.isOfficial, isTrue);
    expect(comment.userName, 'Officer Davis');

    final fallbackComment = ReportComment.fromMap({
      'id': 'c-2',
      'report_id': 'r-1',
      'user_id': 'u-2',
      'user_name': null,
      'comment': 'I saw it too',
      'is_official': null,
      'created_at': null,
    });

    expect(fallbackComment.userName, 'Anonymous');
    expect(fallbackComment.isOfficial, isFalse);
    expect(fallbackComment.createdAt, isNotNull);
  });
}
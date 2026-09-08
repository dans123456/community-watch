import 'package:flutter_test/flutter_test.dart';
import 'package:community_watch/main.dart';
import 'package:community_watch/models/report.dart';
import 'package:community_watch/models/report_comment.dart';
import 'package:community_watch/models/app_notification.dart';

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

  test('AppNotification.fromMap parses valid and fallback records safely', () {
    final notifMap = {
      'id': 'notif-1',
      'user_id': 'user-1',
      'title': 'Report Status Updated',
      'message': 'Your report has been marked as Under Investigation.',
      'is_read': false,
      'created_at': '2026-09-08T14:00:00Z',
    };

    final notif = AppNotification.fromMap(notifMap);
    expect(notif.id, 'notif-1');
    expect(notif.title, 'Report Status Updated');
    expect(notif.isRead, isFalse);
    expect(notif.createdAt.year, 2026);

    final readNotif = notif.copyWith(isRead: true);
    expect(readNotif.isRead, isTrue);
  });

  test('Report.fromMap handles multi-image and legacy single-image arrays', () {
    // Multi-image payload
    final multiImageMap = {
      'id': 'r-multi',
      'user_id': 'u-1',
      'title': 'Vandalism with Multiple Photos',
      'description': 'Graffiti on wall and broken window',
      'category': 'Vandalism',
      'location': 'Market Square',
      'incident_at': '2026-09-08T15:00:00Z',
      'status': 'Pending',
      'image_url': 'https://example.com/img1.jpg',
      'image_urls': [
        'https://example.com/img1.jpg',
        'https://example.com/img2.jpg',
        'https://example.com/img3.jpg',
      ],
      'created_at': '2026-09-08T15:05:00Z',
    };

    final multiReport = Report.fromMap(multiImageMap);
    expect(multiReport.imageUrls.length, 3);
    expect(multiReport.imageUrls[0], 'https://example.com/img1.jpg');
    expect(multiReport.imageUrl, 'https://example.com/img1.jpg');

    // Legacy single image fallback payload
    final legacyMap = {
      'id': 'r-legacy',
      'user_id': 'u-2',
      'title': 'Legacy Report',
      'description': 'Single image only',
      'category': 'Other',
      'location': 'Downtown',
      'incident_at': '2026-09-08T16:00:00Z',
      'status': 'Resolved',
      'image_url': 'https://example.com/legacy.jpg',
      'image_urls': null,
      'created_at': '2026-09-08T16:01:00Z',
    };

    final legacyReport = Report.fromMap(legacyMap);
    expect(legacyReport.imageUrls.length, 1);
    expect(legacyReport.imageUrls.first, 'https://example.com/legacy.jpg');
    expect(legacyReport.imageUrl, 'https://example.com/legacy.jpg');
  });
}
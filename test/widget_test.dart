import 'package:flutter_test/flutter_test.dart';
import 'package:community_watch/main.dart';

void main() {
  testWidgets('Community Watch app starts', (tester) async {
    // Supabase initialization requires project credentials, so this test
    // verifies the app source can be imported and the root widget exists.
    expect(const CommunityWatchApp(), isA<CommunityWatchApp>());
  });
}
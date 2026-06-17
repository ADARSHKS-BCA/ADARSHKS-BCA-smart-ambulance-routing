import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ambulance_auth/main.dart';


void main() {
  testWidgets('Authentication Module smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the title of our system is displayed.
    expect(find.text('Smart Ambulance System'), findsOneWidget);

    // Verify that the registration instruction subtitle is displayed.
    expect(find.text('PATIENT & STAFF REGISTRATION'), findsOneWidget);

    // Verify that the Google Continue button is present.
    expect(find.text('Continue with Google'), findsOneWidget);

    // Verify that the form starts with the Sign-Up page (finds manual fields).
    expect(find.text('FIRST NAME'), findsOneWidget);
    expect(find.text('SURNAME'), findsOneWidget);
    expect(find.text('AGE'), findsOneWidget);
  });
}

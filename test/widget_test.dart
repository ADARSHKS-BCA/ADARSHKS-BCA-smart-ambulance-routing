import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_app/main.dart';

void main() {
  testWidgets('App launches with Start Emergency screen', (tester) async {
    await tester.pumpWidget(const EmergencyApp());
    expect(find.text('Emergency'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });
}

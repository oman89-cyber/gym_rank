// This file is intentionally minimal — widget tests use GymRankApp.
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_rank/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GymRankApp());
    expect(find.byType(GymRankApp), findsOneWidget);
  });
}

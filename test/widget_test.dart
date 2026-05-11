import 'package:flutter_test/flutter_test.dart';

import 'package:lostandfound/main.dart';

void main() {
  testWidgets('shows the campus lost and found feed', (tester) async {
    await tester.pumpWidget(const LostFoundCampusApp());
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('lostandfound'), findsOneWidget);
    expect(find.text('Latest posts'), findsOneWidget);
    expect(find.text('Wireless earbuds'), findsOneWidget);
    expect(find.text('Blue backpack'), findsOneWidget);
  });
}

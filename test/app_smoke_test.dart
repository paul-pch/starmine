import 'package:flutter_test/flutter_test.dart';
import 'package:starmine/main.dart';

void main() {
  testWidgets("l'app démarre", (tester) async {
    await tester.pumpWidget(const StarmineApp());
    expect(find.text('Starmine'), findsOneWidget);
  });
}

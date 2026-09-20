import 'package:flutter_test/flutter_test.dart';
import 'package:velyntora/main.dart';

void main() {
  testWidgets('muestra la galería de Velyntora', (tester) async {
    await tester.pumpWidget(const VelyntoraApp());
    expect(find.text('Velyntora'), findsOneWidget);
    expect(find.text('Tus proyectos'), findsOneWidget);
    expect(find.text('Nuevo proyecto'), findsOneWidget);
  });
}

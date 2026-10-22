import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brilliant_mobile/main.dart';

void main() {
  testWidgets('El contador de números iniciales aumenta', (
    WidgetTester tester,
  ) async {
    // Construimos la app y dibujamos el primer cuadro.
    await tester.pumpWidget(const BrilliantApp());

    // Entramos al Mapa 1 para ver el tablero.
    await tester.tap(find.byKey(const Key('map-choice-1')));
    await tester.pumpAndSettle();

    // Verificamos que el contador empieza en 0.
    expect(find.text('0/6'), findsOneWidget);
    expect(find.text('1/6'), findsNothing);

    // Tocamos una celda inicial, elegimos un número y redibujamos.
    await tester.tap(find.byKey(const Key('initial-cell-1-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('initial-value-1')));
    await tester.pumpAndSettle();

    // Verificamos que el contador aumentó.
    expect(find.text('0/6'), findsNothing);
    expect(find.text('1/6'), findsOneWidget);
  });
}

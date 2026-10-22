import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'package:brilliantdart/mapa_uno.dart';

void main() {
  group('Widgets: preparación de la partida', () {
    testWidgets('Antes de comenzar solo se pueden tocar las celdas iniciales', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      await tester.tap(find.byKey(const Key('board-cell-1-1')));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsNothing);

      await tester.tap(find.byKey(const Key('initial-cell-1-3')));
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsOneWidget);
    });

    testWidgets('Las seis celdas iniciales muestran un +', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      for (final (fila, columna) in mapaUno.celdasIniciales) {
        expect(textoEn('initial-cell-$fila-$columna', '+'), findsOneWidget);
      }
      expect(find.text('+'), findsNWidgets(6));
    });

    testWidgets('Vaciar una celda inicial actualiza el progreso', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      await tester.tap(find.byKey(const Key('initial-cell-1-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('initial-value-4')));
      await tester.pumpAndSettle();
      expect(find.text('1/6'), findsOneWidget);
      expect(textoEn('initial-cell-1-3', '4'), findsOneWidget);

      await tester.tap(find.byKey(const Key('initial-cell-1-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clear-initial-value')));
      await tester.pumpAndSettle();
      expect(find.text('0/6'), findsOneWidget);
      expect(textoEn('initial-cell-1-3', '+'), findsOneWidget);
    });

    testWidgets('Comenzar sigue desactivado con solo cinco números', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      for (var i = 0; i < 5; i++) {
        final (fila, columna) = mapaUno.celdasIniciales[i];
        await tester.tap(find.byKey(Key('initial-cell-$fila-$columna')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('initial-value-${i + 1}')));
        await tester.pumpAndSettle();
      }

      expect(find.text('5/6'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(find.byKey(const Key('roll-dice-button')), findsNothing);
    });
  });
}

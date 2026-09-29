import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Brilliant app shows the board title', (tester) async {
    await tester.pumpWidget(const BrilliantApp());

    expect(find.text('Tablero'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('Duplicate initial values move and enable Comenzar at 1..6',
      (tester) async {
    await tester.pumpWidget(const BrilliantApp());

    await tester.tap(find.byKey(const Key('initial-cell-1-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('initial-value-4')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('initial-cell-6-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('initial-value-4')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('initial-cell-1-3')),
        matching: find.text('+'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('initial-cell-6-3')),
        matching: find.text('4'),
      ),
      findsOneWidget,
    );

    const asignaciones = <String, int>{
      '1-3': 6,
      '2-6': 1,
      '4-2': 2,
      '4-5': 3,
      '7-5': 5,
    };
    for (final asignacion in asignaciones.entries) {
      await tester.tap(find.byKey(Key('initial-cell-${asignacion.key}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('initial-value-${asignacion.value}')));
      await tester.pumpAndSettle();
    }

    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Comenzar'));
    await tester.pump();
    expect(find.text('Partida iniciada'), findsOneWidget);
    expect(find.text('En partida'), findsOneWidget);
  });
}

import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Map selection shows one available map and two locked maps',
      (tester) async {
    await tester.pumpWidget(const BrilliantApp());

    expect(find.text('Elige tu mapa'), findsOneWidget);
    expect(find.text('Mapa 1'), findsOneWidget);
    expect(find.text('Mapa 2'), findsOneWidget);
    expect(find.text('Mapa 3'), findsOneWidget);
    expect(find.text('Próximamente'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('map-choice-1')));
    await tester.pumpAndSettle();

    expect(find.text('Tablero'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(
      find.text('Coloca los 6 números iniciales para comenzar'),
      findsOneWidget,
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('Duplicate initial values move and enable Comenzar at 1..6',
      (tester) async {
    await tester.pumpWidget(const BrilliantApp());
    await tester.tap(find.byKey(const Key('map-choice-1')));
    await tester.pumpAndSettle();

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
    expect(find.byKey(const Key('roll-dice-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pump();
    expect(find.text('Lanzando dados...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Lanzando dados...'), findsNothing);
    expect(find.textContaining(RegExp(r'Dado 1: [1-6]')), findsOneWidget);
    expect(find.textContaining(RegExp(r'Dado 2: [1-6]')), findsOneWidget);

    await tester.tap(find.byKey(const Key('roll-dice-button')));
    await tester.pump();
    expect(find.text('Lanzando dados...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'Dado 1: [1-6]')), findsOneWidget);
    expect(find.textContaining(RegExp(r'Dado 2: [1-6]')), findsOneWidget);
  });
}

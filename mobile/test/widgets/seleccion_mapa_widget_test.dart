import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widgets: selección de mapa', () {
    testWidgets('El mapa bloqueado no abre ningún tablero', (tester) async {
      await tester.pumpWidget(const BrilliantApp());

      await tester.tap(find.byKey(const Key('map-choice-3')));
      await tester.pumpAndSettle();

      expect(find.text('Elige tu mapa'), findsOneWidget);
      expect(find.byType(TableroPage), findsNothing);
    });

    testWidgets('La vista previa del mapa 1 tiene las 49 celdas', (
      tester,
    ) async {
      await tester.pumpWidget(const BrilliantApp());

      final vistaPrevia = find.descendant(
        of: find.byKey(const Key('map-choice-1')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'map-preview-cell-',
              ),
        ),
      );
      expect(vistaPrevia, findsNWidgets(49));
    });
  });
}

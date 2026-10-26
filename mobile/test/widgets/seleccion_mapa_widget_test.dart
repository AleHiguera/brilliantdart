import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widgets: selección de mapa', () {
    for (final (numero, mapa) in [
      (1, mapaUno),
      (2, mapaDos),
      (3, mapaTres),
      (4, mapaCuatro),
    ]) {
      testWidgets('El Mapa $numero abre su propio tablero', (tester) async {
        await tester.pumpWidget(const BrilliantApp());

        await tester.ensureVisible(find.byKey(Key('map-choice-$numero')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('map-choice-$numero')));
        await tester.pumpAndSettle();

        expect(find.text('Elige tu mapa'), findsNothing);
        expect(
          tester.widget<TableroPage>(find.byType(TableroPage)).mapa,
          same(mapa),
        );
      });
    }

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

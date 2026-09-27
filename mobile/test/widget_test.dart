import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Brilliant app shows the board title', (tester) async {
    await tester.pumpWidget(const BrilliantApp());

    expect(find.text('Tablero'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });
}

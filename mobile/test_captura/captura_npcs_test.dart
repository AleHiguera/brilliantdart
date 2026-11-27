// Captura de cerca de los personajitos del menú (no es parte de las pruebas).
// Uso: CAPTURAS=<carpeta> flutter test test_captura/captura_npcs_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:brilliant_mobile/npcs_menu.dart';
import 'package:brilliant_mobile/pintores_npc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> guardar(WidgetTester tester, GlobalKey clave, String nombre) =>
    tester.runAsync(() async {
      final limite =
          clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagen = await limite.toImage(pixelRatio: 4);
      final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
      File(
        '${Platform.environment['CAPTURAS']}/$nombre.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    });

void main() {
  testWidgets('npcs de cerca', (tester) async {
    final clave = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: clave,
            child: Container(
              width: 220,
              color: const Color(0xFF9ED67A),
              padding: const EdgeInsets.all(8),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomPaint(
                        size: tamanoNino,
                        painter: PintorNino(paso: 1, saludando: false),
                      ),
                      CustomPaint(
                        size: tamanoNino,
                        painter: PintorNino(paso: 0, saludando: true),
                      ),
                      CustomPaint(
                        size: tamanoPerro,
                        painter: PintorPerro(paso: -1, saludando: false),
                      ),
                      CustomPaint(
                        size: tamanoPerro,
                        painter: PintorPerro(paso: 0, saludando: true),
                      ),
                    ],
                  ),
                  SizedBox(width: 204, child: NpcsMenu()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Hasta que el niño se detiene a saludar (camina 5 s).
    for (var i = 0; i < 53; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await guardar(tester, clave, 'npcs_cerca');
    await tester.pumpWidget(const SizedBox());
  });
}

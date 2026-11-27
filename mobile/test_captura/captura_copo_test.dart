// Captura de cerca del copo de los números iniciales (no es parte de las
// pruebas). Uso: CAPTURAS=<carpeta> flutter test test_captura/captura_copo_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:brilliant_mobile/copo_progreso.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('copo de cerca', (tester) async {
    final clave = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: clave,
            child: Container(
              color: const Color(0xFFF4FAFF),
              padding: const EdgeInsets.all(8),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CopoProgresoIniciales(cantidad: 0),
                  SizedBox(width: 12),
                  CopoProgresoIniciales(cantidad: 3),
                  SizedBox(width: 12),
                  CopoProgresoIniciales(cantidad: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() async {
      final limite =
          clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagen = await limite.toImage(pixelRatio: 4);
      final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
      File(
        '${Platform.environment['CAPTURAS']}/copo_cerca.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    });
  });
}

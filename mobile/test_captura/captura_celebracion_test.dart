// Capturas de la animación del ELO al terminar (no es parte de las pruebas).
// Uso: CAPTURAS=<carpeta> flutter test test_captura/captura_celebracion_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:brilliant_mobile/celebracion_elo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _flutter = File(Platform.resolvedExecutable).parent.parent.parent.parent;
final _fuentes = '${_flutter.path}/artifacts/material_fonts';

Future<void> _cargarFuente(String familia, List<String> archivos) async {
  final cargador = FontLoader(familia);
  for (final archivo in archivos) {
    final bytes = File('$_fuentes/$archivo').readAsBytesSync();
    cargador.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await cargador.load();
}

Future<void> guardar(WidgetTester tester, GlobalKey clave, String nombre) =>
    tester.runAsync(() async {
      final limite =
          clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagen = await limite.toImage(pixelRatio: 3);
      final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
      File(
        '${Platform.environment['CAPTURAS']}/$nombre.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    });

Future<GlobalKey> mostrar(
  WidgetTester tester,
  ({int lugar, int antes, int cambio, int despues}) resultado,
) async {
  final clave = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto'),
      home: Material(
        child: Center(
          child: RepaintBoundary(
            key: clave,
            child: Container(
              width: 340,
              color: const Color(0xFFFFF8E8),
              padding: const EdgeInsets.fromLTRB(12, 70, 12, 12),
              child: CelebracionElo(resultado: resultado),
            ),
          ),
        ),
      ),
    ),
  );
  return clave;
}

Future<void> pasar(WidgetTester tester, int milisegundos) async {
  for (var t = 0; t < milisegundos; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    await _cargarFuente('Roboto', [
      'Roboto-Regular.ttf',
      'Roboto-Bold.ttf',
      'Roboto-Black.ttf',
    ]);
  });

  testWidgets('gana', (tester) async {
    final clave = await mostrar(tester, (
      lugar: 1,
      antes: 1000,
      cambio: 16,
      despues: 1016,
    ));
    await pasar(tester, 450);
    await guardar(tester, clave, 'elo_gana_medio');
    await pasar(tester, 3000);
    await guardar(tester, clave, 'elo_gana_fin');
  });

  testWidgets('pierde', (tester) async {
    final clave = await mostrar(tester, (
      lugar: 2,
      antes: 40,
      cambio: -8,
      despues: 32,
    ));
    await pasar(tester, 3000);
    await guardar(tester, clave, 'elo_pierde');
  });
}

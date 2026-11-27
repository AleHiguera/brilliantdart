// Captura del Salón de la Fama a PNG para revisar el diseño (no es parte de
// las pruebas). Uso: flutter test test_captura/captura_salon_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:brilliant_mobile/pantalla_salon_fama.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_salon_fama.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

Map<String, Object?> p(int lugar, String usuario, int elo) => {
  'lugar': lugar,
  'usuario': usuario,
  'elo': elo,
};

Future<void> capturar(
  WidgetTester tester,
  String nombre,
  Map<String, Object?> respuesta, {
  double alto = 1500,
}) async {
  tester.view.physicalSize = Size(390 * 2, alto * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final auth = ServicioAuth(
    servidor: 'https://s:8443',
    cliente: MockClient(
      (_) async => http.Response.bytes(
        utf8.encode(jsonEncode({'ok': true, 'mensaje': '.', ...respuesta})),
        200,
      ),
    ),
  )..sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 't');
  final clave = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: clave,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          fontFamily: 'Roboto',
        ),
        home: PantallaSalonFama(
          servicio: ServicioSalonFama(auth),
          usuario: 'ana',
        ),
      ),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.runAsync(() async {
    final limite =
        clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagen = await limite.toImage(pixelRatio: 2);
    final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
    File(
      '${Platform.environment['CAPTURAS']}/$nombre.png',
    ).writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await _cargarFuente('Roboto', [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
      'Roboto-Black.ttf',
    ]);
    await _cargarFuente('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  final nombres = [
    'valentina_gm',
    'el_crack99',
    'sofi.rdz',
    'tito_juega',
    'marianela',
    'pepe_strats',
    'lucas_m',
    'daniela_x',
    'rorro',
    'karla.b',
  ];

  testWidgets('fuera del top', (tester) async {
    await capturar(tester, 'salon_fuera', {
      'top': [
        for (final (i, n) in nombres.indexed)
          p(
            i + 1,
            n,
            [2450, 2380, 2290, 2210, 2150, 2100, 2050, 1980, 1950, 1920][i],
          ),
      ],
      'yo': p(66, 'ana', 1350),
      'jugadores': 80,
    });
  });

  testWidgets('dentro del top', (tester) async {
    await capturar(tester, 'salon_dentro', {
      'top': [
        p(1, 'ana', 2450),
        p(2, 'el_crack99', 2380),
        p(3, 'sofi.rdz', 2290),
        p(4, 'tito_juega', 2210),
      ],
      'yo': null,
      'jugadores': 4,
    }, alto: 1000);
  });
}

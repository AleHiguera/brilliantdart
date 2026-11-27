// Capturas de varias pantallas con la imagen de fondo, para revisar el diseño
// (no es parte de las pruebas). Uso:
//   CAPTURAS=<carpeta> flutter test test_captura/captura_fondo_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:brilliant_mobile/fondo_app.dart';
import 'package:brilliant_mobile/main.dart';
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

ServicioAuth auth({bool conSesion = true}) {
  final servicio = ServicioAuth(
    servidor: 'https://s:8443',
    cliente: MockClient((p) async {
      final datos = p.url.path == '/api/salon-fama'
          ? {
              'top': [
                for (final (i, n) in [
                  'valentina_gm',
                  'el_crack99',
                  'sofi.rdz',
                  'tito_juega',
                  'marianela',
                  'pepe_strats',
                ].indexed)
                  {'lugar': i + 1, 'usuario': n, 'elo': 2450 - i * 70},
              ],
              'yo': {'lugar': 66, 'usuario': 'ana', 'elo': 1350},
              'jugadores': 80,
            }
          : {'elo': 1350};
      return http.Response.bytes(
        utf8.encode(jsonEncode({'ok': true, 'mensaje': '.', ...datos})),
        200,
      );
    }),
  );
  if (conSesion) {
    servicio.sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 't');
  }
  return servicio;
}

Future<void> esperar(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    for (var j = 0; j < 12; j++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }
}

Future<void> guardar(WidgetTester tester, GlobalKey clave, String nombre) =>
    tester.runAsync(() async {
      final limite =
          clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final imagen = await limite.toImage(pixelRatio: 1.5);
      final png = await imagen.toByteData(format: ui.ImageByteFormat.png);
      File(
        '${Platform.environment['CAPTURAS']}/$nombre.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    });

Future<GlobalKey> mostrar(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(390 * 1.5, 844 * 1.5);
  tester.view.devicePixelRatio = 1.5;
  addTearDown(tester.view.reset);
  final clave = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key: clave, child: app));
  for (final imagen in [
    imagenFondo,
    'assets/imagenes/fondo_reino_helado.jpg',
  ]) {
    await tester.runAsync(
      () => precacheImage(
        AssetImage(imagen),
        tester.element(find.byType(RepaintBoundary).first),
      ),
    );
  }
  await esperar(tester);
  return clave;
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

  testWidgets('menu', (tester) async {
    final clave = await mostrar(tester, BrilliantApp(auth: auth()));
    await guardar(tester, clave, 'fondo_menu');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await esperar(tester);
    await guardar(tester, clave, 'fondo_menu_abajo');
  });

  testWidgets('login', (tester) async {
    final clave = await mostrar(
      tester,
      BrilliantApp(auth: auth(conSesion: false)),
    );
    await guardar(tester, clave, 'fondo_login');
  });

  testWidgets('tablero', (tester) async {
    final clave = await mostrar(tester, const BrilliantApp());
    await tester.tap(find.byKey(const Key('map-option-1')));
    await esperar(tester);
    await guardar(tester, clave, 'fondo_tablero');
  });

  testWidgets('salon', (tester) async {
    final servicio = auth();
    final clave = await mostrar(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          scaffoldBackgroundColor: Colors.transparent,
        ),
        builder: (context, pantalla) => FondoApp(child: pantalla!),
        home: PantallaSalonFama(
          servicio: ServicioSalonFama(servicio),
          usuario: 'ana',
        ),
      ),
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await esperar(tester);
    await guardar(tester, clave, 'fondo_salon');
  });
}

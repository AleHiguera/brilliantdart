import 'dart:convert';

import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Servidor falso: acepta solo a "ana" con el PIN 1234.
ServicioAuth authFalso({List<String>? peticiones}) {
  return ServicioAuth(
    servidor: 'https://servidor:8443',
    cliente: MockClient((peticion) async {
      peticiones?.add(peticion.url.path);
      if (peticion.url.path == '/api/logout') {
        return respuesta({'ok': true, 'mensaje': 'Sesión cerrada.'}, 200);
      }
      final datos = peticion.bodyFields;
      if (datos['usuario'] == 'ana' && datos['password'] == '1234') {
        return respuesta({
          'ok': true,
          'mensaje': 'Sesión iniciada.',
          'usuario': 'ana',
          'nombre': 'Ana',
          'token': 'abc',
        }, 200);
      }
      return respuesta({
        'ok': false,
        'mensaje': 'Usuario o contraseña incorrectos.',
      }, 401);
    }),
  );
}

/// JSON en UTF-8, como lo envía el servidor real (http.Response con texto
/// usaría latin1 y estropearía las tildes).
http.Response respuesta(Map<String, Object> datos, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

Future<void> entrar(WidgetTester tester, String usuario, String pin) async {
  await tester.enterText(find.byKey(const Key('login-usuario')), usuario);
  await tester.enterText(find.byKey(const Key('login-pin')), pin);
  await tester.tap(find.byKey(const Key('login-entrar')));
  await esperarServidor(tester);
}

/// La respuesta del servidor falso llega por un flujo asíncrono real, que el
/// reloj falso de las pruebas no hace avanzar por sí solo.
Future<void> esperarServidor(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  group('Widgets: inicio de sesión', () {
    testWidgets('Sin sesión no se puede elegir mapa', (tester) async {
      await tester.pumpWidget(BrilliantApp(auth: authFalso()));

      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(find.text('Elige tu mapa'), findsNothing);
    });

    testWidgets('Con usuario y PIN correctos se entra a elegir mapa', (
      tester,
    ) async {
      await tester.pumpWidget(BrilliantApp(auth: authFalso()));

      await entrar(tester, 'ana', '1234');

      expect(find.text('Elige tu mapa'), findsOneWidget);
      expect(find.byKey(const Key('logout-button')), findsOneWidget);
    });

    testWidgets('Con el PIN incorrecto se muestra el error del servidor', (
      tester,
    ) async {
      await tester.pumpWidget(BrilliantApp(auth: authFalso()));

      await entrar(tester, 'ana', '9999');

      expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
      expect(find.text('Elige tu mapa'), findsNothing);
    });

    testWidgets('El PIN debe tener 4 números antes de enviarse', (
      tester,
    ) async {
      final peticiones = <String>[];
      await tester.pumpWidget(
        BrilliantApp(auth: authFalso(peticiones: peticiones)),
      );

      await entrar(tester, 'ana', '12');

      expect(find.text('El PIN tiene exactamente 4 números.'), findsOneWidget);
      expect(peticiones, isEmpty);
    });

    testWidgets('Cerrar sesión avisa al servidor y vuelve al inicio', (
      tester,
    ) async {
      final peticiones = <String>[];
      final auth = authFalso(peticiones: peticiones);
      await tester.pumpWidget(BrilliantApp(auth: auth));
      await entrar(tester, 'ana', '1234');

      await tester.tap(find.byKey(const Key('logout-button')));
      await esperarServidor(tester);

      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(peticiones, ['/api/login', '/api/logout']);
      expect(auth.sesion, isNull);
    });
  });
}

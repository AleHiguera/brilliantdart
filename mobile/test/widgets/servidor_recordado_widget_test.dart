// Prueba de widgets: el inicio de sesión muestra el servidor con el que se
// entró la última vez, para no escribir la IP cada vez en el teléfono.

import 'dart:convert';

import 'package:brilliant_mobile/almacen_pestana.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servidor_recordado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Widgets: servidor recordado', () {
    late AlmacenPestana preferencias;
    late List<String> servidores;

    setUp(() {
      preferencias = AlmacenEnMemoria();
      servidores = [];
    });

    ServicioAuth auth() => ServicioAuth(
      preferencias: preferencias,
      cliente: MockClient((peticion) async {
        servidores.add(peticion.url.origin);
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'ok': true,
              'usuario': 'ana',
              'nombre': 'Ana',
              'token': 'abc',
            }),
          ),
          200,
        );
      }),
    );

    Future<void> entrar(WidgetTester tester, {String? servidor}) async {
      if (servidor != null) {
        await tester.tap(find.text('Servidor'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('login-servidor')),
          servidor,
        );
      }
      await tester.enterText(find.byKey(const Key('login-usuario')), 'ana');
      await tester.enterText(find.byKey(const Key('login-pin')), '1234');
      await tester.ensureVisible(find.byKey(const Key('login-entrar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('login-entrar')));
      // La respuesta llega por un flujo asíncrono real.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
    }

    testWidgets('Muestra el servidor recordado en el inicio de sesión', (
      tester,
    ) async {
      ServidorRecordado(preferencias).guardar('https://192.168.1.129:8443');

      await tester.pumpWidget(BrilliantApp(auth: auth()));

      expect(find.text('https://192.168.1.129:8443'), findsOneWidget);
    });

    testWidgets('Entra con el servidor recordado sin escribirlo', (
      tester,
    ) async {
      ServidorRecordado(preferencias).guardar('https://192.168.1.129:8443');
      await tester.pumpWidget(BrilliantApp(auth: auth()));

      await entrar(tester);

      expect(servidores, ['https://192.168.1.129:8443']);
    });

    testWidgets('Al entrar con otra dirección, la siguiente vez sale esa', (
      tester,
    ) async {
      await tester.pumpWidget(BrilliantApp(auth: auth()));
      await entrar(tester, servidor: 'https://10.0.0.7:8443');
      expect(servidores, ['https://10.0.0.7:8443']);

      // Se cierra la app y se vuelve a abrir.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(BrilliantApp(auth: auth()));

      expect(find.text('https://10.0.0.7:8443'), findsOneWidget);
    });
  });
}

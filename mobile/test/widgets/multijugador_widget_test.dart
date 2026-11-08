import 'dart:convert';

import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/sala_partida.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/vigilante_sala.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Servidor falso con una sola sala, para que las pruebas decidan qué ve el
/// jugador en cada consulta.
class ServidorFalso {
  final List<http.Request> peticiones = [];
  List<String> jugadores = ['ana'];
  String anfitrion = 'ana';
  int capacidad = 4;
  Object mapa = 3;
  bool comenzada = false;
  String? rechazoSala;
  String? rechazoInicio;
  int codigoEstado = 200;

  Map<String, Object> get _sala => {
    'ok': true,
    'mensaje': 'Sala.',
    'codigo': 'ABC234',
    'mapa': mapa,
    'capacidad': capacidad,
    'anfitrion': anfitrion,
    'jugadores': jugadores,
    'comenzada': comenzada,
  };

  Iterable<http.Request> de(String accion) =>
      peticiones.where((p) => p.url.path == '/api/partida/$accion');

  ServicioAuth auth() => ServicioAuth(
    servidor: 'https://servidor:8443',
    cliente: MockClient((peticion) async {
      peticiones.add(peticion);
      switch (peticion.url.path) {
        case '/api/login':
          return _json({
            'ok': true,
            'mensaje': 'Sesión iniciada.',
            'usuario': peticion.bodyFields['usuario']!,
            'nombre': 'Ana',
            'token': 'abc',
          }, 200);
        case '/api/partida/salir':
        case '/api/latido':
          return _json({'ok': true, 'mensaje': 'Listo.'}, 200);
        case '/api/partida/estado' when codigoEstado != 200:
          return _json({'ok': false, 'mensaje': 'Fallo.'}, codigoEstado);
        case '/api/partida/iniciar':
          final rechazo = rechazoInicio;
          if (rechazo != null) {
            return _json({'ok': false, 'mensaje': rechazo}, 409);
          }
          comenzada = true;
          return _json(_sala, 200);
      }
      final rechazo = rechazoSala;
      return rechazo != null
          ? _json({'ok': false, 'mensaje': rechazo}, 409)
          : _json(_sala, 200);
    }),
  );
}

http.Response _json(Map<String, Object> datos, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

/// La respuesta del servidor falso llega por un flujo asíncrono real, que el
/// reloj falso de las pruebas no hace avanzar por sí solo.
Future<void> esperarServidor(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> entrar(
  WidgetTester tester,
  ServidorFalso servidor,
  String usuario,
) async {
  await tester.pumpWidget(BrilliantApp(auth: servidor.auth()));
  await tester.enterText(find.byKey(const Key('login-usuario')), usuario);
  await tester.enterText(find.byKey(const Key('login-pin')), '1234');
  await tester.tap(find.byKey(const Key('login-entrar')));
  await esperarServidor(tester);
  await bajarHasta(tester, 'multijugador-unirse');
}

/// La lista del menú solo construye lo que está a la vista.
Future<void> bajarHasta(WidgetTester tester, String clave) async {
  await tester.scrollUntilVisible(
    find.byKey(Key(clave)),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> tocar(WidgetTester tester, String clave) async {
  await tester.ensureVisible(find.byKey(Key(clave)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key(clave)));
  await tester.pumpAndSettle();
}

Future<void> crearSala(WidgetTester tester, ServidorFalso servidor) async {
  await entrar(tester, servidor, 'ana');
  await tocar(tester, 'multijugador-crear');
  await tocar(tester, 'crear-mapa-3');
  await tocar(tester, 'crear-jugadores-4');
  await tester.tap(find.byKey(const Key('crear-enviar')));
  await esperarServidor(tester);
}

/// Llega a la pantalla de unirse y envía el código, como lo haría el jugador.
Future<void> unirseCon(
  WidgetTester tester,
  ServidorFalso servidor,
  String codigo,
) async {
  await entrar(tester, servidor, 'luis');
  await tocar(tester, 'multijugador-unirse');
  await tester.enterText(find.byKey(const Key('unirse-codigo')), codigo);
  await tester.tap(find.byKey(const Key('unirse-enviar')));
  await esperarServidor(tester);
}

Future<void> siguienteConsulta(WidgetTester tester) async {
  await tester.pump(VigilanteSala.intervalo);
  await esperarServidor(tester);
}

void main() {
  group('Widgets: multijugador', () {
    testWidgets('Sin sesión no aparece el apartado', (tester) async {
      await tester.pumpWidget(const BrilliantApp());
      await bajarHasta(tester, 'how-to-play');

      expect(find.byKey(const Key('multijugador')), findsNothing);
    });

    testWidgets('El menú ofrece crear y unirse', (tester) async {
      await entrar(tester, ServidorFalso(), 'ana');

      expect(find.byKey(const Key('multijugador-crear')), findsOneWidget);
      expect(find.byKey(const Key('multijugador-unirse')), findsOneWidget);
    });

    testWidgets('Solo se puede elegir de 2 a 6 jugadores', (tester) async {
      await entrar(tester, ServidorFalso(), 'ana');
      await tocar(tester, 'multijugador-crear');

      for (final cantidad in [2, 3, 4, 5, 6]) {
        expect(find.byKey(Key('crear-jugadores-$cantidad')), findsOneWidget);
      }
      expect(find.byKey(const Key('crear-jugadores-1')), findsNothing);
      expect(find.byKey(const Key('crear-jugadores-7')), findsNothing);
    });

    testWidgets('Crear envía el mapa y la cantidad elegidos', (tester) async {
      final servidor = ServidorFalso();

      await crearSala(tester, servidor);

      final peticion = servidor.de('crear').single;
      expect(peticion.bodyFields, {'mapa': '3', 'jugadores': '4'});
      expect(peticion.headers['Authorization'], 'Bearer abc');
    });

    testWidgets('La sala muestra código, mapa, anfitrión y espacios', (
      tester,
    ) async {
      await crearSala(tester, ServidorFalso());

      expect(find.text('ABC234'), findsOneWidget);
      expect(find.text('Mapa 3'), findsOneWidget);
      expect(find.text('@ana (tú)'), findsOneWidget);
      expect(find.text('Anfitrión'), findsOneWidget);
      expect(find.text('1 de 4 espacios ocupados'), findsOneWidget);
      expect(find.text('Espacio libre'), findsNWidgets(3));
    });

    testWidgets('Los jugadores que llegan aparecen en la sala', (tester) async {
      final servidor = ServidorFalso();
      await crearSala(tester, servidor);

      servidor.jugadores = ['ana', 'luis'];
      await siguienteConsulta(tester);

      expect(find.text('@luis'), findsOneWidget);
      expect(find.text('2 de 4 espacios ocupados'), findsOneWidget);
      expect(find.text('Espacio libre'), findsNWidgets(2));
    });

    testWidgets('Unirse con el código entra a la sala como invitado', (
      tester,
    ) async {
      final servidor = ServidorFalso()..jugadores = ['ana', 'luis'];
      await entrar(tester, servidor, 'luis');
      await tocar(tester, 'multijugador-unirse');

      await tester.enterText(find.byKey(const Key('unirse-codigo')), 'abc234');
      await tester.tap(find.byKey(const Key('unirse-enviar')));
      await esperarServidor(tester);

      expect(servidor.de('unirse').single.bodyFields, {'codigo': 'abc234'});
      expect(find.text('@luis (tú)'), findsOneWidget);
      expect(find.text('Salir de la sala'), findsOneWidget);
    });

    testWidgets('Un código incompleto no llega al servidor', (tester) async {
      final servidor = ServidorFalso();
      await entrar(tester, servidor, 'luis');
      await tocar(tester, 'multijugador-unirse');

      await tester.enterText(find.byKey(const Key('unirse-codigo')), 'ABC');
      await tester.tap(find.byKey(const Key('unirse-enviar')));
      await tester.pumpAndSettle();

      expect(find.text('El código tiene 6 caracteres.'), findsOneWidget);
      expect(servidor.de('unirse'), isEmpty);
    });

    testWidgets('Un código con símbolos no llega al servidor', (tester) async {
      final servidor = ServidorFalso();

      await unirseCon(tester, servidor, 'ABC-23');

      expect(
        find.text('El código solo lleva letras y números.'),
        findsOneWidget,
      );
      expect(servidor.de('unirse'), isEmpty);
    });

    // Los mismos mensajes con los que rechaza el servidor RegistroClientes.
    for (final rechazo in const [
      'No existe ninguna partida con ese código.',
      'La partida ya comenzó.',
      'La partida ya está llena.',
    ]) {
      testWidgets('El rechazo "$rechazo" se muestra y no deja entrar', (
        tester,
      ) async {
        await unirseCon(
          tester,
          ServidorFalso()..rechazoSala = rechazo,
          'ABC234',
        );

        expect(find.text(rechazo), findsOneWidget);
        expect(find.byType(SalaPartidaPage), findsNothing);
      });
    }

    testWidgets('Tras un rechazo se puede intentar con otro código', (
      tester,
    ) async {
      final servidor = ServidorFalso()
        ..jugadores = ['ana', 'luis']
        ..rechazoSala = 'No existe ninguna partida con ese código.';
      await unirseCon(tester, servidor, 'ZZZ999');

      servidor.rechazoSala = null;
      await tester.enterText(find.byKey(const Key('unirse-codigo')), 'ABC234');
      await tester.tap(find.byKey(const Key('unirse-enviar')));
      await esperarServidor(tester);

      expect(find.byType(SalaPartidaPage), findsOneWidget);
      expect(servidor.de('unirse'), hasLength(2));
    });

    testWidgets('El anfitrión a solas no puede iniciar la partida', (
      tester,
    ) async {
      final servidor = ServidorFalso();
      await crearSala(tester, servidor);
      await tester.ensureVisible(find.byKey(const Key('sala-iniciar')));

      final boton = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('sala-iniciar')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(boton.onPressed, isNull);
      expect(find.byKey(const Key('sala-falta-jugador')), findsOneWidget);
    });

    testWidgets('El anfitrión inicia la partida y el código desaparece', (
      tester,
    ) async {
      final servidor = ServidorFalso();
      await crearSala(tester, servidor);
      servidor.jugadores = ['ana', 'luis'];
      await siguienteConsulta(tester);

      await tocar(tester, 'sala-iniciar');
      await esperarServidor(tester);

      expect(servidor.de('iniciar').single.bodyFields, {'codigo': 'ABC234'});
      expect(find.byKey(const Key('sala-comenzada')), findsOneWidget);
      expect(find.byKey(const Key('sala-iniciar')), findsNothing);
      expect(find.text('ABC234'), findsNothing);
    });

    testWidgets('Si el servidor no deja iniciar se muestra el motivo', (
      tester,
    ) async {
      final servidor = ServidorFalso()
        ..jugadores = ['ana', 'luis']
        ..rechazoInicio = 'Se necesitan al menos 2 jugadores para empezar.';
      await crearSala(tester, servidor);

      await tocar(tester, 'sala-iniciar');
      await esperarServidor(tester);

      expect(
        find.text('Se necesitan al menos 2 jugadores para empezar.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('sala-comenzada')), findsNothing);
      expect(find.byKey(const Key('sala-iniciar')), findsOneWidget);
    });

    testWidgets('El invitado espera y luego ve que la partida comenzó', (
      tester,
    ) async {
      final servidor = ServidorFalso()..jugadores = ['ana', 'luis'];
      await unirseCon(tester, servidor, 'ABC234');

      expect(find.byKey(const Key('sala-esperando')), findsOneWidget);
      expect(find.byKey(const Key('sala-iniciar')), findsNothing);

      servidor.comenzada = true;
      await siguienteConsulta(tester);

      expect(find.byKey(const Key('sala-comenzada')), findsOneWidget);
      expect(find.byKey(const Key('sala-esperando')), findsNothing);
    });

    testWidgets('Tocar dos veces Unirse envía una sola petición', (
      tester,
    ) async {
      final servidor = ServidorFalso()..jugadores = ['ana', 'luis'];
      await entrar(tester, servidor, 'luis');
      await tocar(tester, 'multijugador-unirse');

      await tester.enterText(find.byKey(const Key('unirse-codigo')), 'ABC234');
      await tester.tap(find.byKey(const Key('unirse-enviar')));
      await tester.tap(find.byKey(const Key('unirse-enviar')));
      await esperarServidor(tester);

      expect(servidor.de('unirse'), hasLength(1));
    });

    testWidgets('El invitado también ve llegar a los demás', (tester) async {
      final servidor = ServidorFalso()..jugadores = ['ana', 'luis'];
      await unirseCon(tester, servidor, 'ABC234');

      servidor.jugadores = ['ana', 'luis', 'eva'];
      await siguienteConsulta(tester);

      expect(find.text('@eva'), findsOneWidget);
      expect(find.text('3 de 4 espacios ocupados'), findsOneWidget);
    });

    testWidgets('Una sala con un mapa desconocido avisa y no rompe la app', (
      tester,
    ) async {
      await unirseCon(tester, ServidorFalso()..mapa = 9, 'ABC234');

      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Esta partida usa un mapa que tu versión de la app no conoce.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SalaPartidaPage), findsNothing);
    });

    testWidgets('Una respuesta mal formada avisa y deja reintentar', (
      tester,
    ) async {
      await unirseCon(tester, ServidorFalso()..mapa = '3', 'ABC234');

      expect(tester.takeException(), isNull);
      expect(find.text('Respuesta inesperada del servidor.'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('El anfitrión confirma antes de cerrar la sala', (
      tester,
    ) async {
      final servidor = ServidorFalso();
      await crearSala(tester, servidor);

      await bajarHasta(tester, 'sala-salir');
      await tocar(tester, 'sala-salir');
      expect(servidor.de('salir'), isEmpty);

      await tester.tap(find.byKey(const Key('sala-cerrar-confirmar')));
      await esperarServidor(tester);

      expect(servidor.de('salir').single.bodyFields, {'codigo': 'ABC234'});
      expect(find.byType(SeleccionMapaPage), findsOneWidget);
    });

    testWidgets('Volver atrás también avisa al servidor', (tester) async {
      final servidor = ServidorFalso()
        ..anfitrion = 'ana'
        ..jugadores = ['ana', 'luis'];
      await entrar(tester, servidor, 'luis');
      await tocar(tester, 'multijugador-unirse');
      await tester.enterText(find.byKey(const Key('unirse-codigo')), 'ABC234');
      await tester.tap(find.byKey(const Key('unirse-enviar')));
      await esperarServidor(tester);

      await tester.tap(find.byType(BackButton));
      await esperarServidor(tester);

      expect(servidor.de('salir'), hasLength(1));
      expect(find.byType(SeleccionMapaPage), findsOneWidget);
    });

    testWidgets('Si la sala se cierra se avisa y se puede volver', (
      tester,
    ) async {
      final servidor = ServidorFalso();
      await crearSala(tester, servidor);

      servidor.rechazoSala = 'Esta partida ya no está disponible.';
      await siguienteConsulta(tester);

      expect(find.text('Esta partida ya no está disponible.'), findsOneWidget);
      expect(find.byKey(const Key('sala-codigo')), findsNothing);

      await tocar(tester, 'sala-salir');
      expect(find.byType(SeleccionMapaPage), findsOneWidget);
    });

    testWidgets('Un fallo pasajero no saca a nadie de la sala', (tester) async {
      final servidor = ServidorFalso()..codigoEstado = 500;
      await crearSala(tester, servidor);

      await siguienteConsulta(tester);
      expect(find.byKey(const Key('sala-perdida')), findsNothing);

      servidor
        ..codigoEstado = 200
        ..jugadores = ['ana', 'luis'];
      await siguienteConsulta(tester);
      expect(find.text('@luis'), findsOneWidget);
    });

    testWidgets('La sala completa cabe en un celular', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final servidor = ServidorFalso()
        ..capacidad = 6
        ..jugadores = [
          'ana',
          'un_usuario_con_nombre_muy_largo_de_verdad',
          'c',
          'd',
          'e',
          'f',
        ];

      await crearSala(tester, servidor);

      expect(find.text('6 de 6 espacios ocupados'), findsOneWidget);
    });
  });
}

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
  List<String> listos = [];
  bool comenzada = false;
  String? rechazoSala;
  String? rechazoListo;
  int codigoEstado = 200;

  /// Quien inició sesión; el servidor falso atiende a un solo jugador.
  String? usuario;

  Map<String, Object> get _sala => {
    'ok': true,
    'mensaje': 'Sala.',
    'codigo': 'ABC234',
    'mapa': mapa,
    'capacidad': capacidad,
    'anfitrion': anfitrion,
    'jugadores': jugadores,
    'listos': listos,
    'comenzada': comenzada,
  };

  /// Igual que el servidor real: empieza sola cuando todos (al menos 2) confirmaron.
  Map<String, Object> _marcar({required bool listo}) {
    listos = [
      for (final jugador in jugadores)
        if (jugador == usuario ? listo : listos.contains(jugador)) jugador,
    ];
    if (jugadores.length >= 2 && listos.length == jugadores.length) {
      comenzada = true;
    }
    return _sala;
  }

  Iterable<http.Request> de(String accion) =>
      peticiones.where((p) => p.url.path == '/api/partida/$accion');

  ServicioAuth auth() => ServicioAuth(
    servidor: 'https://servidor:8443',
    cliente: MockClient((peticion) async {
      peticiones.add(peticion);
      switch (peticion.url.path) {
        case '/api/login':
          usuario = peticion.bodyFields['usuario'];
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
        case '/api/partida/listo' || '/api/partida/no-listo':
          final rechazo = rechazoListo;
          if (rechazo != null) {
            return _json({'ok': false, 'mensaje': rechazo}, 409);
          }
          final listo = peticion.url.path.endsWith('/listo');
          return _json(_marcar(listo: listo), 200);
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

/// En la sala los botones quedan bajo la lista de jugadores, fuera de la vista.
Future<void> tocarEnSala(WidgetTester tester, String clave) async {
  await bajarHasta(tester, clave);
  await tocar(tester, clave);
  await esperarServidor(tester);
}

/// La etiqueta de estado que la sala muestra junto a [usuario].
Finder estadoDe(String usuario, String estado) => find.descendant(
  of: find.byKey(Key('estado-$usuario')),
  matching: find.text(estado),
);

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
      await bajarHasta(tester, 'sala-salir');
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

    testWidgets('Cada jugador muestra si ya está listo', (tester) async {
      final servidor = ServidorFalso()
        ..jugadores = ['ana', 'luis']
        ..listos = ['luis'];
      await crearSala(tester, servidor);

      expect(estadoDe('luis', 'Listo'), findsOneWidget);
      expect(estadoDe('ana', 'Esperando'), findsOneWidget);
      expect(find.text('Falta 1 jugador por confirmar.'), findsOneWidget);
    });

    testWidgets('Todos, no solo el anfitrión, tienen el botón de listo', (
      tester,
    ) async {
      await unirseCon(
        tester,
        ServidorFalso()..jugadores = ['ana', 'luis'],
        'ABC234',
      );
      await bajarHasta(tester, 'sala-listo');

      expect(find.text('Listo para iniciar'), findsOneWidget);
    });

    testWidgets('Confirmar avisa al servidor y se puede deshacer', (
      tester,
    ) async {
      final servidor = ServidorFalso()..jugadores = ['ana', 'luis', 'eva'];
      await crearSala(tester, servidor);

      await tocarEnSala(tester, 'sala-listo');
      expect(servidor.de('listo').single.bodyFields, {'codigo': 'ABC234'});
      expect(estadoDe('ana', 'Listo'), findsOneWidget);
      expect(find.text('Faltan 2 jugadores por confirmar.'), findsOneWidget);

      await tocarEnSala(tester, 'sala-no-listo');
      expect(servidor.de('no-listo'), hasLength(1));
      expect(estadoDe('ana', 'Esperando'), findsOneWidget);
      expect(find.byKey(const Key('sala-listo')), findsOneWidget);
    });

    testWidgets('Mientras falte alguien por confirmar no empieza', (
      tester,
    ) async {
      final servidor = ServidorFalso()
        ..jugadores = ['ana', 'luis', 'eva']
        ..listos = ['luis'];
      await crearSala(tester, servidor);

      await tocarEnSala(tester, 'sala-listo');

      expect(find.text('Falta 1 jugador por confirmar.'), findsOneWidget);
      expect(find.byType(SalaPartidaPage), findsOneWidget);
      expect(find.byType(TableroPage), findsNothing);
    });

    testWidgets('A solas se puede confirmar pero no empieza', (tester) async {
      final servidor = ServidorFalso();
      await crearSala(tester, servidor);

      await tocarEnSala(tester, 'sala-listo');

      expect(
        find.text('Hace falta al menos otro jugador para empezar.'),
        findsOneWidget,
      );
      expect(find.byType(TableroPage), findsNothing);
    });

    testWidgets('Cuando el último confirma pasa al tablero del mapa elegido', (
      tester,
    ) async {
      final servidor = ServidorFalso()
        ..jugadores = ['ana', 'luis']
        ..listos = ['luis'];
      await crearSala(tester, servidor);

      await tocarEnSala(tester, 'sala-listo');

      expect(find.byType(SalaPartidaPage), findsNothing);
      expect(
        tester.widget<TableroPage>(find.byType(TableroPage)).mapa.numero,
        3,
      );
    });

    testWidgets('Los demás también pasan al mismo tablero', (tester) async {
      final servidor = ServidorFalso()..jugadores = ['ana', 'luis'];
      await unirseCon(tester, servidor, 'ABC234');
      final consultasAntes = servidor.de('estado').length;

      servidor
        ..listos = ['ana', 'luis']
        ..comenzada = true;
      await siguienteConsulta(tester);

      expect(
        tester.widget<TableroPage>(find.byType(TableroPage)).mapa.numero,
        3,
      );

      // Ya en el tablero la sala deja de consultarse.
      final consultasAlEntrar = servidor.de('estado').length;
      await tester.pump(VigilanteSala.intervalo * 3);
      expect(consultasAlEntrar, consultasAntes + 1);
      expect(servidor.de('estado'), hasLength(consultasAlEntrar));
    });

    testWidgets(
      'Quien vuelve a una partida ya comenzada va directo al tablero',
      (tester) async {
        final servidor = ServidorFalso()
          ..jugadores = ['ana', 'luis']
          ..listos = ['ana', 'luis']
          ..comenzada = true;

        await unirseCon(tester, servidor, 'ABC234');

        expect(
          tester.widget<TableroPage>(find.byType(TableroPage)).mapa.numero,
          3,
        );
      },
    );

    testWidgets('Si el servidor rechaza la confirmación se muestra el motivo', (
      tester,
    ) async {
      final servidor = ServidorFalso()
        ..jugadores = ['ana', 'luis']
        ..rechazoListo = 'Esta partida ya no está disponible.';
      await crearSala(tester, servidor);

      await tocarEnSala(tester, 'sala-listo');

      expect(find.text('Esta partida ya no está disponible.'), findsOneWidget);
      expect(find.byKey(const Key('sala-listo')), findsOneWidget);
      expect(find.byType(TableroPage), findsNothing);
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
        ]
        // Las etiquetas de anfitrión y de listo también deben caber.
        ..listos = ['ana', 'un_usuario_con_nombre_muy_largo_de_verdad'];

      await crearSala(tester, servidor);

      expect(find.text('6 de 6 espacios ocupados'), findsOneWidget);
    });
  });
}

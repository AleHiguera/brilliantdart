import 'dart:convert';

import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/preparacion_multijugador.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:brilliant_mobile/vigilante_sala.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers.dart';

/// Servidor falso visto por «ana», en una partida que ya comenzó.
class ServidorFalso {
  final List<http.Request> peticiones = [];
  List<String> jugadores = ['ana', 'luis'];
  List<String> finalizados = [];
  List<int> miTablero = [];
  bool configurada = false;
  String anfitrion = 'ana';
  String? rechazoFinalizar;
  String? rechazoEstado;

  Map<String, Object> get sala => {
    'ok': true,
    'mensaje': 'Sala.',
    'codigo': 'ABC234',
    'mapa': 1,
    'capacidad': 6,
    'anfitrion': anfitrion,
    'jugadores': jugadores,
    'listos': jugadores,
    'comenzada': true,
    'finalizados': finalizados,
    'configurada': configurada,
    'miTablero': miTablero,
  };

  Iterable<http.Request> de(String accion) =>
      peticiones.where((p) => p.url.path == '/api/partida/$accion');

  /// Igual que el servidor real: el primer envío de cada jugador es el que vale.
  http.Response _finalizar(http.Request peticion) {
    final rechazo = rechazoFinalizar;
    if (rechazo != null) return _json({'ok': false, 'mensaje': rechazo}, 409);
    if (!finalizados.contains('ana')) {
      miTablero = peticion.bodyFields['numeros']!
          .split(',')
          .map(int.parse)
          .toList();
      finalizados = [...finalizados, 'ana'];
    }
    configurada = jugadores.every(finalizados.contains);
    return _json(sala, 200);
  }

  http.Response _responder(http.Request peticion) {
    peticiones.add(peticion);
    switch (peticion.url.path) {
      case '/api/partida/finalizar':
        return _finalizar(peticion);
      case '/api/partida/salir':
        return _json({'ok': true, 'mensaje': 'Saliste.'}, 200);
    }
    final rechazo = rechazoEstado;
    return rechazo != null
        ? _json({'ok': false, 'mensaje': rechazo}, 409)
        : _json(sala, 200);
  }

  PreparacionMultijugador preparacion() {
    final auth = ServicioAuth(
      servidor: 'https://servidor:8443',
      cliente: MockClient((peticion) async => _responder(peticion)),
    )..sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'abc');
    return PreparacionMultijugador(
      partidas: ServicioPartidas(auth),
      sala: SalaPartida.desdeJson(sala),
    );
  }
}

http.Response _json(Map<String, Object> datos, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

Future<void> esperarServidor(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// Abre el tablero sobre un menú, como queda al venir de la sala.
Future<void> abrirTablero(
  WidgetTester tester,
  ServidorFalso servidor, {
  Mapa mapa = mapaUno,
}) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: Text('Menú'))),
  );
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(
        MaterialPageRoute<void>(
          builder: (_) =>
              TableroPage(mapa: mapa, preparacion: servidor.preparacion()),
        ),
      );
  await tester.pumpAndSettle();
}

Future<void> colocar(WidgetTester tester, List<int> numeros) async {
  for (var i = 0; i < numeros.length; i++) {
    final (fila, columna) = mapaUno.celdasIniciales[i];
    await tester.tap(find.byKey(Key('initial-cell-$fila-$columna')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('initial-value-${numeros[i]}')));
    await tester.pumpAndSettle();
  }
}

Future<void> tocarFinalizado(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Finalizado'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Finalizado'));
  await esperarServidor(tester);
}

Future<void> siguienteConsulta(WidgetTester tester) async {
  await tester.pump(VigilanteSala.intervalo);
  await esperarServidor(tester);
}

Future<void> volverAtras(WidgetTester tester) async {
  await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
  await tester.pumpAndSettle();
}

Finder dados() => find.byKey(const Key('roll-dice-button'));

const List<int> orden = [1, 2, 3, 4, 5, 6];

void main() {
  group('Widgets: tablero individual en multijugador', () {
    testWidgets('Se ve Finalizado, no Comenzar, y sin dados', (tester) async {
      await abrirTablero(tester, ServidorFalso());

      expect(find.text('Finalizado'), findsOneWidget);
      expect(find.text('Comenzar'), findsNothing);
      expect(dados(), findsNothing);
    });

    testWidgets('Finalizado sigue desactivado con solo cinco números', (
      tester,
    ) async {
      final servidor = ServidorFalso();
      await abrirTablero(tester, servidor);

      await colocar(tester, orden.sublist(0, 5));
      await tester.ensureVisible(find.text('Finalizado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finalizado'), warnIfMissed: false);
      await esperarServidor(tester);

      expect(find.text('5/6'), findsOneWidget);
      expect(servidor.de('finalizar'), isEmpty);
    });

    testWidgets('Los números respetan la regla de zona del juego', (
      tester,
    ) async {
      // En el Mapa 4 la (1, 5) es de un naranja del 4 al 6.
      await abrirTablero(tester, ServidorFalso(), mapa: mapaCuatro);

      await tester.tap(find.byKey(const Key('initial-cell-1-5')));
      await tester.pumpAndSettle();

      bool sePuedeElegir(int numero) =>
          tester
              .widget<InkWell>(find.byKey(Key('initial-value-$numero')))
              .onTap !=
          null;
      expect([1, 2, 3].where(sePuedeElegir), isEmpty);
      expect([4, 5, 6].every(sePuedeElegir), isTrue);
    });

    testWidgets('Recupera un tablero que usa zonas con límites', (
      tester,
    ) async {
      final servidor = ServidorFalso()
        ..finalizados = ['ana']
        ..miTablero = [6, 2, 3, 4, 5, 1];

      await abrirTablero(tester, servidor, mapa: mapaCuatro);

      expect(textoEn('initial-cell-1-5', '6'), findsOneWidget);
      expect(find.byKey(const Key('tablero-esperando')), findsOneWidget);
    });

    testWidgets('Envía el orden que eligió el jugador', (tester) async {
      final servidor = ServidorFalso();
      await abrirTablero(tester, servidor);

      await colocar(tester, orden);
      await tocarFinalizado(tester);

      expect(servidor.de('finalizar').single.bodyFields, {
        'codigo': 'ABC234',
        'numeros': '1,2,3,4,5,6',
      });
    });

    testWidgets('Tras finalizar espera a los demás y no hay dados', (
      tester,
    ) async {
      await abrirTablero(tester, ServidorFalso());

      await colocar(tester, orden);
      await tocarFinalizado(tester);

      expect(find.byKey(const Key('tablero-esperando')), findsOneWidget);
      expect(find.text('Colocando sus números: @luis'), findsOneWidget);
      expect(dados(), findsNothing);
    });

    testWidgets('Tras finalizar ya no se pueden cambiar los números', (
      tester,
    ) async {
      await abrirTablero(tester, ServidorFalso());
      await colocar(tester, orden);
      await tocarFinalizado(tester);

      final (fila, columna) = mapaUno.celdasIniciales.first;
      await tester.tap(find.byKey(Key('initial-cell-$fila-$columna')));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('Si otro termina antes, igual se pueden colocar los números', (
      tester,
    ) async {
      final servidor = ServidorFalso();
      await abrirTablero(tester, servidor);

      servidor.finalizados = ['luis'];
      await siguienteConsulta(tester);

      expect(dados(), findsNothing);
      expect(find.text('Finalizado'), findsOneWidget);
      await colocar(tester, orden);
      expect(find.text('6/6'), findsOneWidget);
    });

    testWidgets('Los dados aparecen cuando terminó el último de los demás', (
      tester,
    ) async {
      final servidor = ServidorFalso();
      await abrirTablero(tester, servidor);
      await colocar(tester, orden);
      await tocarFinalizado(tester);

      servidor
        ..finalizados = ['ana', 'luis']
        ..configurada = true;
      await siguienteConsulta(tester);

      expect(dados(), findsOneWidget);
      expect(find.byKey(const Key('tablero-esperando')), findsNothing);
      expect(textoEn('initial-cell-1-3', '1'), findsOneWidget);
    });

    testWidgets('Quien finaliza al último pasa directo a los dados', (
      tester,
    ) async {
      final servidor = ServidorFalso()..finalizados = ['luis'];
      await abrirTablero(tester, servidor);

      await colocar(tester, orden);
      await tocarFinalizado(tester);

      expect(dados(), findsOneWidget);
    });

    testWidgets('Si se va quien faltaba, los dados ya no esperan', (
      tester,
    ) async {
      final servidor = ServidorFalso();
      await abrirTablero(tester, servidor);
      await colocar(tester, orden);
      await tocarFinalizado(tester);

      servidor
        ..jugadores = ['ana']
        ..configurada = true;
      await siguienteConsulta(tester);

      expect(dados(), findsOneWidget);
    });

    testWidgets(
      'Si falla el envío se muestra el motivo y se puede reintentar',
      (tester) async {
        final servidor = ServidorFalso()..rechazoFinalizar = 'Sin suerte.';
        await abrirTablero(tester, servidor);
        await colocar(tester, orden);

        await tocarFinalizado(tester);
        expect(find.text('Sin suerte.'), findsOneWidget);
        expect(find.byKey(const Key('tablero-esperando')), findsNothing);

        servidor.rechazoFinalizar = null;
        await tocarFinalizado(tester);
        expect(find.byKey(const Key('tablero-esperando')), findsOneWidget);
      },
    );

    testWidgets('Quien vuelve recupera los números que ya había finalizado', (
      tester,
    ) async {
      final servidor = ServidorFalso()
        ..finalizados = ['ana']
        ..miTablero = [6, 5, 4, 3, 2, 1];

      await abrirTablero(tester, servidor);

      for (var i = 0; i < 6; i++) {
        final (fila, columna) = mapaUno.celdasIniciales[i];
        expect(
          textoEn('initial-cell-$fila-$columna', '${servidor.miTablero[i]}'),
          findsOneWidget,
        );
      }
      expect(find.byKey(const Key('tablero-esperando')), findsOneWidget);
    });

    testWidgets('Quien vuelve con todos listos sigue con sus dados', (
      tester,
    ) async {
      final servidor = ServidorFalso()
        ..finalizados = ['ana', 'luis']
        ..miTablero = orden
        ..configurada = true;

      await abrirTablero(tester, servidor);

      expect(dados(), findsOneWidget);
    });

    testWidgets('Si la partida se cierra lo avisa y deja volver al menú', (
      tester,
    ) async {
      final servidor = ServidorFalso();
      await abrirTablero(tester, servidor);

      servidor.rechazoEstado = 'Esta partida ya no está disponible.';
      await siguienteConsulta(tester);

      expect(find.text('Esta partida ya no está disponible.'), findsOneWidget);
      expect(find.text('Finalizado'), findsNothing);

      await tester.tap(find.byKey(const Key('tablero-volver')));
      await tester.pumpAndSettle();
      expect(find.text('Menú'), findsOneWidget);
      expect(servidor.de('salir'), isEmpty);
    });

    testWidgets('Volver atrás pide confirmar; cancelar sigue en la partida', (
      tester,
    ) async {
      final servidor = ServidorFalso()..anfitrion = 'luis';
      await abrirTablero(tester, servidor);

      await volverAtras(tester);
      expect(
        find.text('Si sales, ya no podrás volver a esta partida.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(TableroPage), findsOneWidget);
      expect(servidor.de('salir'), isEmpty);
    });

    testWidgets('Confirmar la salida avisa al servidor', (tester) async {
      final servidor = ServidorFalso();
      await abrirTablero(tester, servidor);

      await volverAtras(tester);
      expect(
        find.text(
          'Eres el anfitrión: si sales, la partida se cierra para todos.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('tablero-salir-confirmar')));
      await esperarServidor(tester);

      expect(servidor.de('salir'), hasLength(1));
      expect(find.text('Menú'), findsOneWidget);
    });

    testWidgets('Sin multijugador sigue siendo Comenzar', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TableroPage()));

      expect(find.text('Comenzar'), findsOneWidget);
      expect(find.text('Finalizado'), findsNothing);
    });

    testWidgets('La espera cabe en un celular', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final servidor = ServidorFalso()
        ..finalizados = ['ana']
        ..miTablero = orden
        ..jugadores = [
          'ana',
          'un_usuario_con_nombre_muy_largo_de_verdad',
          'c',
          'd',
          'e',
          'f',
        ];

      await abrirTablero(tester, servidor);

      expect(find.byKey(const Key('tablero-pendientes')), findsOneWidget);
    });
  });
}

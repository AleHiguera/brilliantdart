import 'dart:convert';

import 'package:brilliant_mobile/inicio_sesion.dart';
import 'package:brilliant_mobile/latido_sesion.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/partida_compartida.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:brilliant_mobile/vigilante_sala.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';
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
  int ronda = 0;
  List<int> dadosRonda = [];
  List<String> jugaron = [];
  bool fallaTurno = false;
  Map<String, Map<String, int>> zonas = {};
  int meta = 26;
  bool terminada = false;
  List<String> ganadores = [];

  /// Mientras sea true ninguna petición llega: se cortó la red.
  bool sinRed = false;

  /// La sesión de la última partida que se abrió.
  late ServicioAuth auth;

  /// Lo que el servidor sacará en cada lanzamiento.
  List<List<int>> proximosDados = [
    [2, 6],
    [3, 4],
    [1, 5],
  ];

  /// El servidor lanza: una sola vez por ronda, para toda la partida.
  void lanzar() {
    configurada = true;
    dadosRonda = proximosDados[ronda];
    ronda++;
    jugaron = [];
  }

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
    'ronda': ronda,
    'dados': dadosRonda,
    'jugaron': jugaron,
    'zonas': zonas,
    'meta': meta,
    'terminada': terminada,
    'ganadores': ganadores,
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
    if (jugadores.every(finalizados.contains)) lanzar();
    return _json(sala, 200);
  }

  http.Response _terminarTurno(http.Request peticion) {
    if (fallaTurno) return _json({'ok': false, 'mensaje': 'Fallo.'}, 500);
    final zona = peticion.bodyFields['zona'];
    if (zona != null) {
      (zonas[zona] ??= {}).putIfAbsent('ana', () => ronda);
    }
    jugaron = [...jugaron, 'ana'];
    if (jugadores.every(jugaron.contains)) lanzar();
    return _json(sala, 200);
  }

  http.Response _responder(http.Request peticion) {
    if (sinRed) throw http.ClientException('Sin red');
    peticiones.add(peticion);
    switch (peticion.url.path) {
      case '/api/partida/finalizar':
        return _finalizar(peticion);
      case '/api/partida/turno':
        return _terminarTurno(peticion);
      case '/api/partida/salir':
        return _json({'ok': true, 'mensaje': 'Saliste.'}, 200);
    }
    final rechazo = rechazoEstado;
    return rechazo != null
        ? _json({'ok': false, 'mensaje': rechazo}, 409)
        : _json(sala, 200);
  }

  PartidaCompartida compartida() {
    auth = ServicioAuth(
      servidor: 'https://servidor:8443',
      cliente: MockClient((peticion) async => _responder(peticion)),
    )..sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'abc');
    return PartidaCompartida(
      partidas: ServicioPartidas(auth),
      sala: SalaPartida.desdeJson(sala),
    );
  }
}

http.Response _json(Map<String, Object> datos, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

/// Deja llegar la respuesta y, si trajo dados, termina su animación: mientras
/// giran la pantalla nunca se asienta.
Future<void> esperarServidor(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pumpAndSettle();
}

/// Abre el tablero sobre un menú, como queda al venir de la sala.
Future<void> abrirTablero(
  WidgetTester tester,
  ServidorFalso servidor, {
  Mapa mapa = mapaUno,
  Tablero? tablero,
  SonidoFalso? sonidoDados,
  SonidoFalso? sonidoVictoria,
}) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: Text('Menú'))),
  );
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(
        MaterialPageRoute<void>(
          builder: (_) => TableroPage(
            mapa: mapa,
            tablero: tablero,
            compartida: servidor.compartida(),
            sonidoDados: sonidoDados ?? SonidoFalso(),
            sonidoVictoria: sonidoVictoria ?? SonidoFalso(),
          ),
        ),
      );
  await esperarServidor(tester);
}

/// Como [abrirTablero], pero bajo el latido de la sesión, como en la app: así
/// una desconexión lleva al inicio de sesión con su aviso.
Future<void> abrirTableroConSesion(
  WidgetTester tester,
  ServidorFalso servidor,
) async {
  final compartida = servidor.compartida();
  await tester.pumpWidget(
    MaterialApp(
      home: LatidoSesion(
        auth: servidor.auth,
        alPerderSesion: (_) {},
        alDesconectarse: (context, desconexion) =>
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => InicioSesionPage(
                  auth: servidor.auth,
                  siguiente: (_) => const Text('Menú'),
                  aviso: desconexion.mensaje,
                ),
              ),
              (_) => false,
            ),
        child: const Scaffold(body: Text('Menú')),
      ),
    ),
  );
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(
        MaterialPageRoute<void>(
          builder: (_) => TableroPage(
            mapa: mapaUno,
            compartida: compartida,
            sonidoDados: SonidoFalso(),
            sonidoVictoria: SonidoFalso(),
          ),
        ),
      );
  await esperarServidor(tester);
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
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(VigilanteSala.intervalo);
  await esperarServidor(tester);
}

Finder celdaCandidata() => find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith('candidate-cell-'),
);

/// Usa [ancla] y coloca el otro número en la primera celda posible.
Future<void> mover(WidgetTester tester, int ancla) async {
  await tester.ensureVisible(find.byKey(Key('anchor-option-$ancla')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('anchor-option-$ancla')));
  await tester.pumpAndSettle();
  await tester.tap(celdaCandidata().first);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('confirm-move-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('confirm-move-button')));
  await esperarServidor(tester);
}

Future<void> pasar(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('pass-turn-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('pass-turn-button')));
  await esperarServidor(tester);
}

/// Partida con ambos tableros listos y ya lanzada la primera ronda.
ServidorFalso enRonda() => ServidorFalso()
  ..finalizados = ['ana', 'luis']
  ..miTablero = orden
  ..lanzar();

Future<void> volverAtras(WidgetTester tester) async {
  await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
  await tester.pumpAndSettle();
}

Finder dados() => find.byKey(const Key('turn-panel'));

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
        ..lanzar();
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
        ..lanzar();
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
      await abrirTablero(tester, enRonda());

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
      // Perder la conexión desde aquí ya no sería abandonar.
      expect(servidor.auth.partidaEnCurso, isNull);

      await tester.tap(find.byKey(const Key('tablero-volver')));
      await tester.pumpAndSettle();
      expect(find.text('Menú'), findsOneWidget);
      expect(servidor.de('salir'), isEmpty);
    });

    testWidgets('Volver atrás pide confirmar; cancelar sigue en la partida', (
      tester,
    ) async {
      final servidor = ServidorFalso();
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
      // Aquí sale quien creó la sala, y eso no cierra nada para los demás.
      expect(
        find.text('Si sales, ya no podrás volver a esta partida.'),
        findsOneWidget,
      );
      expect(find.textContaining('se cierra'), findsNothing);
      await tester.tap(find.byKey(const Key('tablero-salir-confirmar')));
      await esperarServidor(tester);

      expect(servidor.de('salir'), hasLength(1));
      expect(find.text('Menú'), findsOneWidget);
    });

    testWidgets('El sistema lanza los dados del servidor, sin botón', (
      tester,
    ) async {
      final sonido = SonidoFalso();
      await abrirTablero(tester, enRonda(), sonidoDados: sonido);

      expect(find.byKey(const Key('roll-dice-button')), findsNothing);
      expect(find.text('Dado 1: 2'), findsOneWidget);
      expect(find.text('Dado 2: 6'), findsOneWidget);
      expect(sonido.reproducciones, 1);
    });

    testWidgets('Los dados quedan en el historial del jugador', (tester) async {
      await abrirTablero(tester, enRonda());

      comprobarFilaHistorial(tester, 1, (2, 6));
    });

    testWidgets('Una consulta no vuelve a lanzar los dados', (tester) async {
      final sonido = SonidoFalso();
      await abrirTablero(tester, enRonda(), sonidoDados: sonido);

      await siguienteConsulta(tester);
      await siguienteConsulta(tester);

      expect(sonido.reproducciones, 1);
      expect(find.text('Dado 1: 2'), findsOneWidget);
    });

    testWidgets('Se juega con el resultado compartido y se avisa la ronda', (
      tester,
    ) async {
      final servidor = enRonda();
      await abrirTablero(tester, servidor);
      expect(find.byKey(const Key('anchor-option-2')), findsOneWidget);
      expect(find.byKey(const Key('anchor-option-6')), findsOneWidget);

      await mover(tester, 2);

      expect(servidor.de('turno').single.bodyFields, {
        'codigo': 'ABC234',
        'ronda': '1',
        'lleno': 'false',
      });
    });

    testWidgets('Tras mover espera a los demás, sin más dados', (tester) async {
      await abrirTablero(tester, enRonda());

      await mover(tester, 2);

      expect(dados(), findsNothing);
      expect(find.text('Dados de la ronda 1: 2 y 6'), findsOneWidget);
      expect(find.text('Falta por jugar: @luis'), findsOneWidget);
    });

    testWidgets('Pasar el turno también termina la ronda del jugador', (
      tester,
    ) async {
      final servidor = enRonda();
      await abrirTablero(tester, servidor);

      await pasar(tester);

      expect(servidor.de('turno'), hasLength(1));
      expect(find.byKey(const Key('ronda-esperando')), findsOneWidget);
    });

    testWidgets('La siguiente ronda llega cuando juegan los demás', (
      tester,
    ) async {
      final servidor = enRonda();
      await abrirTablero(tester, servidor);
      await mover(tester, 2);

      servidor.lanzar();
      await siguienteConsulta(tester);

      expect(find.text('Dado 1: 3'), findsOneWidget);
      expect(find.text('Dado 2: 4'), findsOneWidget);
      expect(find.byKey(const Key('ronda-esperando')), findsNothing);
      comprobarFilaHistorial(tester, 2, (3, 4));
    });

    testWidgets('Quien juega al último recibe de inmediato la siguiente', (
      tester,
    ) async {
      final servidor = enRonda()..jugaron = ['luis'];
      await abrirTablero(tester, servidor);

      await mover(tester, 2);

      expect(find.text('Dado 1: 3'), findsOneWidget);
      expect(find.byKey(const Key('ronda-esperando')), findsNothing);
    });

    testWidgets('Si el aviso de la ronda falla se repite solo', (tester) async {
      final servidor = enRonda()..fallaTurno = true;
      await abrirTablero(tester, servidor);

      await mover(tester, 2);
      expect(find.byKey(const Key('ronda-esperando')), findsOneWidget);

      servidor.fallaTurno = false;
      await siguienteConsulta(tester);

      expect(servidor.de('turno').length, greaterThan(1));
      expect(servidor.jugaron, ['ana']);

      // Una vez recibido ya no se vuelve a avisar.
      final avisos = servidor.de('turno').length;
      await siguienteConsulta(tester);
      expect(servidor.de('turno'), hasLength(avisos));
    });

    testWidgets('Mientras faltan otros no llega ningún lanzamiento', (
      tester,
    ) async {
      final sonido = SonidoFalso();
      await abrirTablero(tester, enRonda(), sonidoDados: sonido);
      await mover(tester, 2);

      for (var i = 0; i < 3; i++) {
        await siguienteConsulta(tester);
      }

      expect(find.byKey(const Key('ronda-esperando')), findsOneWidget);
      expect(find.text('Dados de la ronda 1: 2 y 6'), findsOneWidget);
      expect(sonido.reproducciones, 1);
    });

    testWidgets('Quien espera no tiene cómo lanzar los dados', (tester) async {
      final servidor = enRonda();
      await abrirTablero(tester, servidor);
      await mover(tester, 2);

      expect(find.byKey(const Key('roll-dice-button')), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(servidor.de('turno'), hasLength(1));
    });

    testWidgets('El procedimiento se repite ronda tras ronda', (tester) async {
      final servidor = enRonda();
      final sonido = SonidoFalso();
      await abrirTablero(tester, servidor, sonidoDados: sonido);

      await mover(tester, 2);
      servidor.lanzar();
      await siguienteConsulta(tester);

      await pasar(tester);
      expect(find.text('Dados de la ronda 2: 3 y 4'), findsOneWidget);
      servidor.lanzar();
      await siguienteConsulta(tester);

      expect(find.text('Dado 1: 1'), findsOneWidget);
      expect(find.text('Dado 2: 5'), findsOneWidget);
      await mover(tester, 1);

      expect(servidor.de('turno').map((p) => p.bodyFields['ronda']), [
        '1',
        '2',
        '3',
      ]);
      expect(sonido.reproducciones, 3);
      comprobarFilaHistorial(tester, 2, (3, 4), accion: 'Turno pasado');
    });

    testWidgets('Una respuesta atrasada no regresa a la ronda anterior', (
      tester,
    ) async {
      final servidor = enRonda();
      await abrirTablero(tester, servidor);
      await mover(tester, 2);
      servidor.lanzar();
      await siguienteConsulta(tester);

      servidor
        ..ronda = 1
        ..dadosRonda = [2, 6];
      await siguienteConsulta(tester);

      expect(find.text('Dado 1: 3'), findsOneWidget);
    });

    testWidgets('Si la partida se cierra durante la ronda lo avisa', (
      tester,
    ) async {
      final servidor = enRonda();
      await abrirTablero(tester, servidor);

      servidor.rechazoEstado = 'Esta partida ya no está disponible.';
      await siguienteConsulta(tester);

      expect(find.text('Esta partida ya no está disponible.'), findsOneWidget);
      expect(dados(), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('tablero-volver')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tablero-volver')));
      await tester.pumpAndSettle();
      expect(find.text('Menú'), findsOneWidget);
    });

    testWidgets('Salir durante la ronda pide confirmar y avisa al servidor', (
      tester,
    ) async {
      final servidor = enRonda();
      await abrirTablero(tester, servidor);

      await volverAtras(tester);
      expect(find.byKey(const Key('tablero-salir-confirmar')), findsOneWidget);
      await tester.tap(find.byKey(const Key('tablero-salir-confirmar')));
      await esperarServidor(tester);

      expect(servidor.de('salir'), hasLength(1));
      expect(find.text('Menú'), findsOneWidget);
    });

    group('Al llenar el tablero', () {
      Future<ServidorFalso> llenar(WidgetTester tester) async {
        final servidor = enRonda()
          ..proximosDados = [
            [1, 3],
          ];
        servidor
          ..ronda = 0
          ..lanzar();
        await abrirTablero(tester, servidor, tablero: tableroCasiLleno());
        await mover(tester, 1);
        return servidor;
      }

      testWidgets('Avisa que ya no jugará más, pero la partida sigue', (
        tester,
      ) async {
        final sonido = SonidoFalso();
        final servidor = enRonda()
          ..proximosDados = [
            [1, 3],
          ];
        servidor
          ..ronda = 0
          ..lanzar();
        await abrirTablero(
          tester,
          servidor,
          tablero: tableroCasiLleno(),
          sonidoVictoria: sonido,
        );
        await mover(tester, 1);

        expect(servidor.de('turno').single.bodyFields['lleno'], 'true');
        expect(find.byKey(const Key('tablero-lleno')), findsOneWidget);
        expect(find.byKey(const Key('game-over-dialog')), findsNothing);
        expect(find.byKey(const Key('ronda-esperando')), findsNothing);
        expect(sonido.reproducciones, 0);
      });

      testWidgets('Avisa cuál zona completó con ese movimiento', (
        tester,
      ) async {
        final servidor = await llenar(tester);
        final zona = mapaUno.crearTablero().regiones.firstWhere(
          (region) => region.contieneCoordenada(3, 6),
        );

        expect(servidor.de('turno').single.bodyFields['zona'], '${zona.id}');
      });

      testWidgets('Si el aviso falla, al repetirlo incluye la misma zona', (
        tester,
      ) async {
        final servidor = enRonda()
          ..proximosDados = [
            [1, 3],
          ]
          ..fallaTurno = true;
        servidor
          ..ronda = 0
          ..lanzar();
        await abrirTablero(tester, servidor, tablero: tableroCasiLleno());
        await mover(tester, 1);

        servidor.fallaTurno = false;
        await siguienteConsulta(tester);

        final avisos = servidor.de('turno').toList();
        expect(avisos.length, greaterThan(1));
        expect(
          avisos.map((aviso) => aviso.bodyFields['zona']).toSet(),
          hasLength(1),
        );
        expect(avisos.first.bodyFields['zona'], isNotNull);
      });

      testWidgets('Salir con el tablero lleno pide confirmar y avisa', (
        tester,
      ) async {
        final servidor = await llenar(tester);

        await volverAtras(tester);
        await tester.tap(find.byKey(const Key('tablero-salir-confirmar')));
        await esperarServidor(tester);

        expect(servidor.de('salir'), hasLength(1));
        expect(find.text('Menú'), findsOneWidget);
        expect(find.byType(TableroPage), findsNothing);
      });
    });

    group('Movimientos individuales', () {
      int colocados(Tablero tablero) =>
          tablero.celdas.where((celda) => celda.valor != null).length;

      /// Sale el mismo [dados] de siempre para quien abra este tablero.
      ServidorFalso conDados(List<int> dados) => ServidorFalso()
        ..finalizados = ['ana', 'luis']
        ..miTablero = orden
        ..proximosDados = [dados]
        ..lanzar();

      testWidgets('Con los mismos dados cada jugador decide distinto', (
        tester,
      ) async {
        final deAna = mapaUno.crearTablero();
        await abrirTablero(tester, enRonda(), tablero: deAna);
        await mover(tester, 2);

        final deLuis = mapaUno.crearTablero();
        await abrirTablero(tester, enRonda(), tablero: deLuis);
        await mover(tester, 6);

        // Con ancla 2 se coloca el 6, y con ancla 6 se coloca el 2.
        bool hayDos(Tablero tablero, int valor) =>
            tablero.celdas.where((celda) => celda.valor == valor).length == 2;
        expect(hayDos(deAna, 6), isTrue);
        expect(hayDos(deAna, 2), isFalse);
        expect(hayDos(deLuis, 2), isTrue);
        expect(hayDos(deLuis, 6), isFalse);
      });

      testWidgets('El movimiento solo cuenta al confirmarlo', (tester) async {
        final servidor = enRonda();
        final tablero = mapaUno.crearTablero();
        await abrirTablero(tester, servidor, tablero: tablero);

        await tester.tap(find.byKey(const Key('anchor-option-2')));
        await tester.pumpAndSettle();
        await tester.tap(celdaCandidata().first);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('movement-summary')), findsOneWidget);
        expect(colocados(tablero), 6);
        expect(servidor.de('turno'), isEmpty);
      });

      testWidgets('Una posición que no es válida no hace nada', (tester) async {
        final tablero = mapaUno.crearTablero();
        await abrirTablero(tester, enRonda(), tablero: tablero);
        await tester.tap(find.byKey(const Key('anchor-option-2')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('board-cell-1-1')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('movement-summary')), findsNothing);
        expect(colocados(tablero), 6);
      });

      testWidgets('Un movimiento válido queda registrado en el tablero', (
        tester,
      ) async {
        final tablero = mapaUno.crearTablero();
        await abrirTablero(tester, enRonda(), tablero: tablero);

        await mover(tester, 2);

        expect(colocados(tablero), 7);
      });

      testWidgets('La opción es Saltar turno, no Pasar turno', (tester) async {
        await abrirTablero(tester, enRonda());

        expect(find.text('Saltar turno'), findsOneWidget);
        expect(find.text('Pasar turno'), findsNothing);
      });

      testWidgets('Saltar no coloca nada, completa el turno y espera', (
        tester,
      ) async {
        final servidor = enRonda();
        final tablero = mapaUno.crearTablero();
        await abrirTablero(tester, servidor, tablero: tablero);

        await pasar(tester);

        expect(colocados(tablero), 6);
        expect(servidor.de('turno').single.bodyFields, {
          'codigo': 'ABC234',
          'ronda': '1',
          'lleno': 'false',
        });
        expect(find.text('Turno completado'), findsOneWidget);
        expect(find.text('Falta por jugar: @luis'), findsOneWidget);
        comprobarFilaHistorial(tester, 1, (2, 6), accion: 'Turno pasado');
      });

      testWidgets('Saltar no declara ninguna zona', (tester) async {
        final servidor = enRonda();
        await abrirTablero(tester, servidor, tablero: tableroCasiLleno());

        await pasar(tester);

        expect(
          servidor.de('turno').single.bodyFields.containsKey('zona'),
          isFalse,
        );
      });

      testWidgets('Un movimiento que no completa ninguna zona no la declara', (
        tester,
      ) async {
        final servidor = enRonda();
        await abrirTablero(tester, servidor);

        await mover(tester, 2);

        expect(
          servidor.de('turno').single.bodyFields.containsKey('zona'),
          isFalse,
        );
      });

      testWidgets('Saltar con una opción elegida la descarta', (tester) async {
        final tablero = mapaUno.crearTablero();
        await abrirTablero(tester, enRonda(), tablero: tablero);
        await tester.tap(find.byKey(const Key('anchor-option-2')));
        await tester.pumpAndSettle();

        await pasar(tester);

        expect(celdaCandidata(), findsNothing);
        expect(colocados(tablero), 6);
      });

      testWidgets('Quien no puede mover también puede saltar', (tester) async {
        final servidor = conDados([4, 6]);
        await abrirTablero(tester, servidor, tablero: tableroCasiLleno());

        expect(
          find.text('No se puede realizar ningún movimiento'),
          findsOneWidget,
        );
        expect(find.text('Saltar turno'), findsOneWidget);

        await pasar(tester);

        expect(servidor.de('turno'), hasLength(1));
        expect(find.byKey(const Key('ronda-esperando')), findsOneWidget);
      });

      testWidgets('Mientras espera ya no puede cambiar su decisión', (
        tester,
      ) async {
        final tablero = mapaUno.crearTablero();
        await abrirTablero(tester, enRonda(), tablero: tablero);
        await mover(tester, 2);

        expect(celdaCandidata(), findsNothing);
        expect(find.byKey(const Key('anchor-option-6')), findsNothing);
        expect(find.byKey(const Key('pass-turn-button')), findsNothing);
      });

      testWidgets('En una partida individual sigue siendo Pasar turno', (
        tester,
      ) async {
        await abrirTableroCasiLleno(tester, [(2, 6)]);
        await lanzarDados(tester);

        expect(find.text('Pasar turno'), findsOneWidget);
        expect(find.text('Saltar turno'), findsNothing);
      });
    });

    testWidgets('Si se va el anfitrión la partida sigue para los demás', (
      tester,
    ) async {
      final servidor = enRonda()
        ..anfitrion = 'luis'
        ..jugadores = ['ana', 'eva'];
      await abrirTablero(tester, servidor);
      await mover(tester, 2);

      servidor.lanzar();
      await siguienteConsulta(tester);

      expect(find.byKey(const Key('tablero-perdido')), findsNothing);
      expect(find.text('Dado 1: 3'), findsOneWidget);
    });

    group('Puntos en pantalla', () {
      /// La zona verde de la (4, 7), que es la que falta en tableroCasiLleno.
      final verde = mapaUno
          .crearTablero()
          .regiones
          .firstWhere((zona) => zona.contieneCoordenada(3, 6))
          .id;

      /// Tablero al que le falta un número; la zona ya la completaron [antes].
      Future<ServidorFalso> ultimaJugada(
        WidgetTester tester, {
        required Map<String, int> antes,
      }) async {
        final servidor = enRonda()
          ..proximosDados = [
            [1, 3],
            [1, 3],
          ]
          ..ronda = 0
          ..zonas = {'$verde': antes};
        servidor
          ..lanzar()
          ..lanzar();
        await abrirTablero(tester, servidor, tablero: tableroCasiLleno());
        await mover(tester, 1);
        return servidor;
      }

      testWidgets('Se ve la tabla de la partida, no la individual', (
        tester,
      ) async {
        await abrirTablero(tester, enRonda());

        expect(find.byKey(const Key('tabla-jugadores')), findsOneWidget);
        expect(find.byKey(const Key('tabla-zonas')), findsOneWidget);
        expect(find.byKey(const Key('score-table')), findsNothing);
      });

      testWidgets('También se ve mientras se colocan los números', (
        tester,
      ) async {
        await abrirTablero(tester, ServidorFalso());

        expect(find.byKey(const Key('tabla-jugadores')), findsOneWidget);
      });

      testWidgets('Una partida individual conserva su tabla', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: TableroPage()));

        expect(find.byKey(const Key('score-table')), findsOneWidget);
        expect(find.byKey(const Key('tabla-jugadores')), findsNothing);
      });

      testWidgets('Los puntos llegan del registro del servidor', (
        tester,
      ) async {
        final servidor = enRonda();
        await abrirTablero(tester, servidor);

        servidor.zonas = {
          '$verde': {'luis': 1},
        };
        await siguienteConsulta(tester);

        expect(
          find.descendant(
            of: find.byKey(const Key('puntos-luis')),
            matching: find.text('4 pts'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Con el tablero lleno se ven los puntos por lugar', (
        tester,
      ) async {
        await ultimaJugada(tester, antes: {'luis': 1});

        // El verde vale 4, 3 y 2: llegó segundo a la única zona registrada.
        expect(find.text('Tus puntos: 3'), findsOneWidget);
        expect(find.byKey(const Key('game-finished-panel')), findsNothing);
      });

      testWidgets('Los puntos propios se ven aunque el aviso no haya llegado', (
        tester,
      ) async {
        final servidor = enRonda()
          ..proximosDados = [
            [1, 3],
          ]
          ..ronda = 0
          ..fallaTurno = true;
        servidor.lanzar();
        await abrirTablero(tester, servidor, tablero: tableroCasiLleno());

        await mover(tester, 1);

        expect(servidor.zonas, isEmpty);
        expect(find.text('Tus puntos: 4'), findsOneWidget);
      });

      testWidgets('En un celular se juega con la tabla sin desbordes', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final servidor = enRonda()
          ..jugadores = [
            'ana',
            'un_usuario_con_nombre_muy_largo_de_verdad',
            'c',
            'd',
            'e',
            'f',
          ]
          ..zonas = {
            '$verde': {'c': 1, 'd': 1},
          };

        await abrirTablero(tester, servidor);

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('tabla-zonas')), findsOneWidget);
      });
    });

    group('Fin de la partida', () {
      /// La zona amarilla del Mapa 1, que vale 8, 6 y 4.
      final amarilla = mapaUno.crearTablero().regiones.first.id;

      /// Partida que el servidor da por terminada mientras ana espera.
      Future<ServidorFalso> terminar(
        WidgetTester tester, {
        required List<String> ganadores,
        required Map<String, int> amarillos,
        int meta = 26,
        SonidoFalso? sonido,
      }) async {
        final servidor = enRonda()..meta = meta;
        await abrirTablero(tester, servidor, sonidoVictoria: sonido);
        await mover(tester, 2);

        servidor
          ..zonas = {'$amarilla': amarillos}
          ..terminada = true
          ..ganadores = ganadores;
        await siguienteConsulta(tester);
        return servidor;
      }

      Finder enPuesto(String jugador, String texto) => find.descendant(
        of: find.byKey(Key('clasificacion-$jugador')),
        matching: find.text(texto),
      );

      testWidgets('La clasificación ordena a todos de mayor a menor', (
        tester,
      ) async {
        final servidor = enRonda()
          ..jugadores = ['ana', 'luis', 'eva', 'sol']
          ..meta = 8;
        await abrirTablero(tester, servidor);
        await mover(tester, 2);
        servidor
          ..zonas = {
            '$amarilla': {'luis': 1, 'eva': 2, 'ana': 3},
          }
          ..terminada = true
          ..ganadores = ['luis'];
        await siguienteConsulta(tester);

        final orden = ['luis', 'eva', 'ana', 'sol']
            .map(
              (jugador) => tester
                  .getTopLeft(find.byKey(Key('clasificacion-$jugador')))
                  .dy,
            )
            .toList();
        expect(orden, [...orden]..sort());
        expect(enPuesto('luis', '1.º'), findsOneWidget);
        expect(enPuesto('eva', '2.º'), findsOneWidget);
        expect(enPuesto('ana', '3.er'), findsOneWidget);
        expect(enPuesto('ana', '@ana (tú)'), findsOneWidget);
        expect(enPuesto('sol', '4.º'), findsOneWidget);
        expect(enPuesto('sol', '0 pts'), findsOneWidget);
        expect(find.text('Quedaste en 3.er lugar'), findsOneWidget);
      });

      testWidgets('Los empatados comparten el lugar y se nota el empate', (
        tester,
      ) async {
        final servidor = enRonda()
          ..jugadores = ['ana', 'luis', 'eva']
          ..meta = 8;
        await abrirTablero(tester, servidor);
        await mover(tester, 2);
        servidor
          ..zonas = {
            '$amarilla': {'luis': 1, 'eva': 2, 'ana': 2},
          }
          ..terminada = true
          ..ganadores = ['luis'];
        await siguienteConsulta(tester);

        expect(enPuesto('luis', '1.º'), findsOneWidget);
        expect(enPuesto('ana', '2.º (empate)'), findsOneWidget);
        expect(enPuesto('eva', '2.º (empate)'), findsOneWidget);
        expect(find.text('Quedaste en 2.º lugar'), findsOneWidget);
      });

      testWidgets('Quien salió sigue en la clasificación con sus puntos', (
        tester,
      ) async {
        final servidor = enRonda()..meta = 8;
        await abrirTablero(tester, servidor);
        await mover(tester, 2);
        servidor
          ..jugadores = ['ana']
          ..zonas = {
            '$amarilla': {'luis': 1},
          }
          ..terminada = true
          ..ganadores = ['luis'];
        await siguienteConsulta(tester);

        expect(enPuesto('luis', '@luis (salió)'), findsOneWidget);
        expect(enPuesto('luis', '8 pts'), findsOneWidget);
        expect(enPuesto('ana', '2.º'), findsOneWidget);
      });

      testWidgets('Durante la partida se ve la meta', (tester) async {
        await abrirTablero(tester, enRonda()..meta = 22);

        expect(find.text('Meta: 22 puntos'), findsOneWidget);
      });

      testWidgets('Quien gana lo ve y suena la victoria', (tester) async {
        final sonido = SonidoFalso();
        await terminar(
          tester,
          ganadores: ['ana'],
          amarillos: {'ana': 1},
          meta: 8,
          sonido: sonido,
        );

        expect(find.text('¡Ganaste!'), findsOneWidget);
        expect(find.text('Ganó @ana (tú) con 8 puntos'), findsOneWidget);
        expect(find.text('Se alcanzó la meta de 8 puntos.'), findsOneWidget);
        expect(sonido.reproducciones, 1);
      });

      testWidgets('Los demás ven quién ganó, sin sonido de victoria', (
        tester,
      ) async {
        final sonido = SonidoFalso();
        await terminar(
          tester,
          ganadores: ['luis'],
          amarillos: {'luis': 1, 'ana': 2},
          meta: 8,
          sonido: sonido,
        );

        expect(find.text('Quedaste en 2.º lugar'), findsOneWidget);
        expect(find.text('Ganó @luis con 8 puntos'), findsOneWidget);
        expect(find.text('Tus puntos: 6'), findsOneWidget);
        expect(sonido.reproducciones, 0);
      });

      testWidgets('Un empate en puntos se muestra como triunfo compartido', (
        tester,
      ) async {
        await terminar(
          tester,
          ganadores: ['ana', 'luis'],
          amarillos: {'ana': 1, 'luis': 1},
          meta: 8,
        );

        expect(find.text('¡Empataste en primer lugar!'), findsOneWidget);
        expect(
          find.text('Ganaron @ana (tú) y @luis con 8 puntos'),
          findsOneWidget,
        );
      });

      testWidgets('Si nadie llegó a la meta se explica el motivo', (
        tester,
      ) async {
        await terminar(tester, ganadores: ['luis'], amarillos: {'luis': 1});

        expect(
          find.text(
            'Nadie llegó a la meta de 26 puntos: todos llenaron su tablero.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('Terminada, ya no hay dados ni se espera la ronda', (
        tester,
      ) async {
        final servidor = await terminar(
          tester,
          ganadores: ['luis'],
          amarillos: {'luis': 1},
        );
        final consultas = servidor.de('estado').length;

        await siguienteConsulta(tester);

        expect(dados(), findsNothing);
        expect(find.byKey(const Key('ronda-esperando')), findsNothing);
        expect(servidor.de('estado'), hasLength(consultas));
      });

      testWidgets('Volver al menú no pide confirmar y avisa al servidor', (
        tester,
      ) async {
        final servidor = await terminar(
          tester,
          ganadores: ['luis'],
          amarillos: {'luis': 1},
        );

        await tester.ensureVisible(find.byKey(const Key('fin-volver')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('fin-volver')));
        await esperarServidor(tester);

        expect(find.byKey(const Key('tablero-salir-confirmar')), findsNothing);
        expect(servidor.de('salir'), hasLength(1));
        expect(find.text('Menú'), findsOneWidget);
      });

      testWidgets('Quien vuelve a una partida terminada ve el final', (
        tester,
      ) async {
        final servidor = enRonda()
          ..terminada = true
          ..ganadores = ['luis']
          ..zonas = {
            '$amarilla': {'luis': 1},
          };

        await abrirTablero(tester, servidor);

        expect(find.byKey(const Key('fin-compartido')), findsOneWidget);
        expect(dados(), findsNothing);
      });

      testWidgets('La pantalla final cabe en un celular', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await terminar(
          tester,
          ganadores: ['ana', 'un_usuario_con_nombre_muy_largo_de_verdad'],
          amarillos: {'ana': 1, 'un_usuario_con_nombre_muy_largo_de_verdad': 1},
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('fin-compartido')), findsOneWidget);
      });
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

  group('Widgets: desconexión durante la partida', () {
    Finder avisoDeAbandono() => find.descendant(
      of: find.byKey(const Key('login-aviso')),
      matching: find.textContaining('cuenta como abandono'),
    );

    testWidgets('Sin red unos segundos sale de la partida como abandono', (
      tester,
    ) async {
      final servidor = enRonda();
      await abrirTableroConSesion(tester, servidor);
      expect(dados(), findsOneWidget);

      servidor.sinRed = true;
      for (var i = 0; i < 3; i++) {
        await siguienteConsulta(tester);
      }

      expect(find.byType(TableroPage), findsNothing);
      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(avisoDeAbandono(), findsOneWidget);
      expect(servidor.auth.sesion, isNull);
    });

    testWidgets('Tampoco queda un error rojo de conexión', (tester) async {
      final servidor = enRonda();
      await abrirTableroConSesion(tester, servidor);

      servidor.sinRed = true;
      for (var i = 0; i < 3; i++) {
        await siguienteConsulta(tester);
      }

      expect(find.textContaining('No se pudo conectar'), findsNothing);
      expect(find.byKey(const Key('multijugador-error')), findsNothing);
      expect(find.byKey(const Key('login-error')), findsNothing);
    });

    testWidgets('Un tropiezo de la red no saca de la partida', (tester) async {
      final servidor = enRonda();
      await abrirTableroConSesion(tester, servidor);

      // Una consulta deja correr el reloj lo suficiente para fallar dos veces.
      servidor.sinRed = true;
      await siguienteConsulta(tester);
      expect(servidor.auth.conexion.fallosSeguidos, 2);
      servidor.sinRed = false;
      await siguienteConsulta(tester);

      expect(find.byType(TableroPage), findsOneWidget);
      expect(dados(), findsOneWidget);
      expect(servidor.auth.sesion, isNotNull);
    });

    testWidgets('También mientras se colocan los números iniciales', (
      tester,
    ) async {
      final servidor = ServidorFalso();
      await abrirTableroConSesion(tester, servidor);

      servidor.sinRed = true;
      for (var i = 0; i < 3; i++) {
        await siguienteConsulta(tester);
      }

      expect(avisoDeAbandono(), findsOneWidget);
    });

    testWidgets('Con la partida ya terminada no es abandono', (tester) async {
      final servidor = enRonda()
        ..terminada = true
        ..ganadores = ['luis'];
      await abrirTableroConSesion(tester, servidor);
      expect(find.byKey(const Key('fin-compartido')), findsOneWidget);

      servidor.sinRed = true;
      await tester.pump(LatidoSesion.intervalo);
      await esperarServidor(tester);
      for (var i = 0; i < 2; i++) {
        await tester.pump(LatidoSesion.reintento);
        await esperarServidor(tester);
      }

      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('login-aviso')),
          matching: find.textContaining('Te desconectaste del servidor.'),
        ),
        findsOneWidget,
      );
      expect(avisoDeAbandono(), findsNothing);
    });
  });
}

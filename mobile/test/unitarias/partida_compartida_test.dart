// Prueba unitaria (no de widgets): revisa cómo avanza una partida compartida
// (los tableros y las rondas de dados), sin dibujar el tablero.

import 'dart:async';
import 'dart:convert';

import 'package:brilliant_mobile/dados_compartidos.dart';
import 'package:brilliant_mobile/guardado_partida.dart';
import 'package:brilliant_mobile/novedades_zonas.dart';
import 'package:brilliant_mobile/partida_compartida.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const List<int> numeros = [3, 1, 2, 6, 5, 4];

SalaPartida sala({
  List<String> finalizados = const [],
  bool configurada = false,
  List<int> miTablero = const [],
  int ronda = 0,
  List<int> dados = const [],
  List<String> jugaron = const [],
}) => SalaPartida(
  codigo: 'ABC234',
  mapa: 1,
  capacidad: 2,
  anfitrion: 'ana',
  jugadores: const ['ana', 'luis'],
  listos: const ['ana', 'luis'],
  comenzada: true,
  finalizados: finalizados,
  configurada: configurada,
  miTablero: miTablero,
  ronda: ronda,
  dados: dados,
  jugaron: jugaron,
);

http.Response json(Map<String, Object> datos, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

http.Response respuesta({
  List<String> finalizados = const ['ana'],
  bool configurada = false,
  int ronda = 0,
  List<int> dados = const [],
  List<String> jugaron = const [],
}) => json({
  'ok': true,
  'mensaje': 'Sala.',
  'codigo': 'ABC234',
  'mapa': 1,
  'capacidad': 2,
  'anfitrion': 'ana',
  'jugadores': ['ana', 'luis'],
  'listos': ['ana', 'luis'],
  'comenzada': true,
  'finalizados': finalizados,
  'configurada': configurada,
  'miTablero': numeros,
  'ronda': ronda,
  'dados': dados,
  'jugaron': jugaron,
  'zonas': <String, Object>{},
  'meta': 0,
  'terminada': false,
  'ganadores': <String>[],
}, 200);

PartidaCompartida compartida(
  Future<http.Response> Function(http.Request) responder, {
  SalaPartida? inicial,
}) {
  final auth = ServicioAuth(
    servidor: 'https://servidor:8443',
    cliente: MockClient(responder),
  )..sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'abc');
  return PartidaCompartida(
    partidas: ServicioPartidas(auth),
    sala: inicial ?? sala(),
  );
}

void main() {
  group('Unitarias: rondas de dados compartidos', () {
    SalaPartida enRonda({List<String> jugaron = const []}) => sala(
      finalizados: ['ana', 'luis'],
      configurada: true,
      miTablero: numeros,
      ronda: 1,
      dados: [5, 2],
      jugaron: jugaron,
    );

    test('Sin lanzar aún no hay nada que jugar', () {
      final fase = compartida((_) async => respuesta());

      expect(fase.puedoJugarRonda, isFalse);
    });

    test('El resultado es el que lanzó el servidor', () {
      final fase = compartida((_) async => respuesta(), inicial: enRonda());

      expect(fase.puedoJugarRonda, isTrue);
      expect(fase.resultado, (5, 2));
    });

    test('Los dados compartidos muestran ese resultado y lo registran', () {
      final dados = DadosCompartidos(() => (5, 2));

      expect(dados.lanzar(), (5, 2));
      expect(dados.dado1.valor, 5);
      expect(dados.dado2.valor, 2);
      expect(dados.lanzar(), (5, 2));
      expect(dados.historial.lanzamientos, hasLength(2));
    });

    test('El registro incluye la zona recién completada, sin esperar', () {
      final fase = compartida(
        (_) => Completer<http.Response>().future,
        inicial: enRonda(),
      );

      fase.terminarTurno(tableroLleno: false, zonaCompletada: 3);

      expect(fase.rondasPorZona, {
        3: {'ana': 1},
      });
    });

    test('Sin zona completada el registro es el del servidor', () {
      final fase = compartida(
        (_) async => respuesta(),
        inicial: SalaPartida(
          codigo: 'ABC234',
          mapa: 1,
          capacidad: 2,
          anfitrion: 'ana',
          jugadores: const ['ana', 'luis'],
          listos: const ['ana', 'luis'],
          comenzada: true,
          finalizados: const ['ana', 'luis'],
          configurada: true,
          miTablero: numeros,
          ronda: 1,
          dados: const [5, 2],
          jugaron: const [],
          zonas: const {
            3: {'luis': 1},
          },
        ),
      );

      expect(fase.rondasPorZona, {
        3: {'luis': 1},
      });
    });

    test('La ronda que ya registró el servidor no se cambia', () {
      final fase = compartida(
        (_) => Completer<http.Response>().future,
        inicial: SalaPartida(
          codigo: 'ABC234',
          mapa: 1,
          capacidad: 2,
          anfitrion: 'ana',
          jugadores: const ['ana', 'luis'],
          listos: const ['ana', 'luis'],
          comenzada: true,
          finalizados: const ['ana', 'luis'],
          configurada: true,
          miTablero: numeros,
          ronda: 4,
          dados: const [5, 2],
          jugaron: const [],
          zonas: const {
            3: {'ana': 2},
          },
        ),
      );

      fase.terminarTurno(tableroLleno: false, zonaCompletada: 3);

      expect(fase.rondasPorZona[3], {'ana': 2});
    });

    test('Mientras puede jugar, su siguiente jugada es en esta ronda', () {
      final fase = compartida((_) async => respuesta(), inicial: enRonda());

      expect(fase.rondaDeMiSiguienteJugada, 1);
    });

    test('Si ya terminó su turno, su siguiente jugada es en la próxima', () {
      final fase = compartida(
        (_) => Completer<http.Response>().future,
        inicial: enRonda(),
      );

      fase.terminarTurno(tableroLleno: false);

      expect(fase.rondaDeMiSiguienteJugada, 2);
    });

    test('Quien ya jugó según el servidor no vuelve a jugar', () {
      final fase = compartida(
        (_) async => respuesta(),
        inicial: enRonda(jugaron: ['ana']),
      );

      expect(fase.puedoJugarRonda, isFalse);
    });

    test(
      'Terminar el turno cierra la ronda sin esperar la respuesta',
      () async {
        final pendiente = Completer<http.Response>();
        final fase = compartida((_) => pendiente.future, inicial: enRonda());

        fase.terminarTurno(tableroLleno: false);
        expect(fase.puedoJugarRonda, isFalse);

        pendiente.complete(
          respuesta(ronda: 1, dados: [5, 2], jugaron: ['ana']),
        );
        await pumpEventQueue();
        expect(fase.sala.jugaron, ['ana']);
      },
    );

    test(
      'Si el último era este jugador ya se puede jugar la siguiente',
      () async {
        final fase = compartida(
          (_) async => respuesta(ronda: 2, dados: [3, 4]),
          inicial: enRonda(jugaron: ['luis']),
        );

        fase.terminarTurno(tableroLleno: false);
        await pumpEventQueue();

        expect(fase.puedoJugarRonda, isTrue);
        expect(fase.resultado, (3, 4));
      },
    );

    test('Un aviso fallido no rompe nada', () async {
      final fase = compartida(
        (_) async => throw http.ClientException('Caído'),
        inicial: enRonda(),
      );

      fase.terminarTurno(tableroLleno: true);
      await pumpEventQueue();

      expect(fase.puedoJugarRonda, isFalse);
      expect(fase.perdida, isNull);
    });
  });

  group('Unitarias: preparación multijugador', () {
    test('Al principio se puede editar y nadie terminó', () {
      final fase = compartida((_) async => respuesta());

      expect(fase.puedeEditar, isTrue);
      expect(fase.yaFinalice, isFalse);
      expect(fase.todosTerminaron, isFalse);
    });

    test('Finalizar bloquea el tablero aunque falten otros', () async {
      final fase = compartida((_) async => respuesta());

      await fase.finalizar(numeros);

      expect(fase.yaFinalice, isTrue);
      expect(fase.puedeEditar, isFalse);
      expect(fase.todosTerminaron, isFalse);
      expect(fase.sala.tablerosPendientes, ['luis']);
    });

    test('Mientras se envía no se edita ni se envía otra vez', () async {
      final pendiente = Completer<http.Response>();
      var envios = 0;
      final fase = compartida((_) {
        envios++;
        return pendiente.future;
      });

      final primero = fase.finalizar(numeros);
      expect(fase.puedeEditar, isFalse);
      await fase.finalizar(numeros);
      pendiente.complete(respuesta());
      await primero;

      expect(envios, 1);
    });

    test('Un tablero ya finalizado no se vuelve a enviar', () async {
      var envios = 0;
      final fase = compartida((_) async {
        envios++;
        return respuesta();
      }, inicial: sala(finalizados: ['ana'], miTablero: numeros));

      await fase.finalizar(numeros);

      expect(envios, 0);
    });

    test('Si el envío falla se puede corregir y reintentar', () async {
      final fase = compartida(
        (_) async => json({'ok': false, 'mensaje': 'Sin suerte.'}, 409),
      );

      await fase.finalizar(numeros);

      expect(fase.error, 'Sin suerte.');
      expect(fase.perdida, isNull);
      expect(fase.puedeEditar, isTrue);
    });

    test('Avisa cuando el último termina', () async {
      final fase = compartida(
        (_) async => respuesta(finalizados: ['ana', 'luis'], configurada: true),
      );
      var avisos = 0;
      fase.addListener(() => avisos++);

      await fase.finalizar(numeros);

      expect(fase.todosTerminaron, isTrue);
      expect(avisos, greaterThan(0));
    });

    test('Salir avisa al servidor aunque falle la conexión', () async {
      final rutas = <String>[];
      final fase = compartida((peticion) async {
        rutas.add(peticion.url.path);
        throw http.ClientException('Caído');
      });

      await fase.salir();

      expect(rutas, ['/api/partida/salir']);
    });

    test('Una respuesta tardía no avisa si ya se cerró', () async {
      final pendiente = Completer<http.Response>();
      final fase = compartida((_) => pendiente.future);
      var avisos = 0;

      final envio = fase.finalizar(numeros);
      fase
        ..addListener(() => avisos++)
        ..dispose();
      pendiente.complete(respuesta());
      await envio;

      expect(avisos, 0);
    });
  });

  group('Unitarias: la sesión sabe si está en partida', () {
    http.Response terminada() {
      final datos =
          jsonDecode(utf8.decode(respuesta().bodyBytes))
              as Map<String, Object?>;
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            ...datos,
            'terminada': true,
            'ganadores': ['ana'],
          }),
        ),
        200,
      );
    }

    test('Al empezar a seguir la partida queda en curso', () {
      final fase = compartida((_) async => respuesta());
      addTearDown(fase.dispose);

      fase.iniciar();

      expect(fase.partidas.auth.partidaEnCurso, 'ABC234');
    });

    test('Antes de empezar a seguirla no hay partida en curso', () {
      final fase = compartida((_) async => respuesta());
      addTearDown(fase.dispose);

      expect(fase.partidas.auth.partidaEnCurso, isNull);
    });

    test('Al salir ya no está en partida', () async {
      final fase = compartida((_) async => respuesta())..iniciar();
      addTearDown(fase.dispose);

      await fase.salir();

      expect(fase.partidas.auth.partidaEnCurso, isNull);
    });

    test('Al cerrar la pantalla ya no está en partida', () {
      final fase = compartida((_) async => respuesta())..iniciar();

      fase.dispose();

      expect(fase.partidas.auth.partidaEnCurso, isNull);
    });

    test('Cuando la partida termina ya no está en partida', () async {
      final fase = compartida((_) async => terminada())..iniciar();
      addTearDown(fase.dispose);

      await fase.finalizar(numeros);

      expect(fase.terminada, isTrue);
      expect(fase.partidas.auth.partidaEnCurso, isNull);
    });

    test('Una partida que ya terminó no queda en curso', () async {
      final fase = compartida((_) async => terminada());
      await fase.finalizar(numeros);
      final otra = PartidaCompartida(partidas: fase.partidas, sala: fase.sala);
      addTearDown(fase.dispose);
      addTearDown(otra.dispose);

      otra.iniciar();

      expect(otra.partidas.auth.partidaEnCurso, isNull);
    });

    test('Cerrar una pantalla vieja no borra otra partida en curso', () {
      final fase = compartida((_) async => respuesta())..iniciar();
      fase.partidas.auth.partidaEnCurso = 'XYZ789';

      fase.dispose();

      expect(fase.partidas.auth.partidaEnCurso, 'XYZ789');
    });
  });

  group('Unitarias: recargar la página en plena partida', () {
    SalaPartida enRonda() => sala(
      finalizados: ['ana', 'luis'],
      configurada: true,
      miTablero: numeros,
      ronda: 1,
      dados: [5, 2],
    );

    PartidaCompartida enEspera() => compartida(
      (_) => Completer<http.Response>().future,
      inicial: enRonda(),
    );

    GuardadoPartida guardadoDe(PartidaCompartida fase) =>
        GuardadoPartida(fase.partidas.auth.almacen, 'ABC234');

    test('Al jugar el turno queda guardado en la pestaña', () {
      final fase = enEspera();
      addTearDown(fase.dispose);

      fase.terminarTurno(tableroLleno: false, zonaCompletada: 3);

      expect(guardadoDe(fase).leerTurno(), (
        ronda: 1,
        tableroLleno: false,
        zona: 3,
      ));
    });

    test('Tras recargar, el turno ya jugado no se vuelve a jugar', () {
      final fase = enEspera()
        ..terminarTurno(tableroLleno: false, zonaCompletada: 3);
      final recargada = PartidaCompartida(
        partidas: fase.partidas,
        sala: enRonda(),
      );
      addTearDown(fase.dispose);
      addTearDown(recargada.dispose);

      expect(recargada.puedoJugarRonda, isFalse);
      expect(recargada.rondasPorZona, {
        3: {'ana': 1},
      });
    });

    test('Lo guardado de otra partida no cuenta', () {
      final fase = enEspera();
      addTearDown(fase.dispose);
      GuardadoPartida(
        fase.partidas.auth.almacen,
        'OTRA11',
      ).guardarTurno((ronda: 1, tableroLleno: false, zona: 2));

      final otra = PartidaCompartida(partidas: fase.partidas, sala: enRonda());
      addTearDown(otra.dispose);

      expect(otra.puedoJugarRonda, isTrue);
    });

    test('Salir de la partida borra lo guardado', () async {
      final fase = compartida((_) async => respuesta(), inicial: enRonda())
        ..terminarTurno(tableroLleno: false);
      addTearDown(fase.dispose);

      await fase.salir();

      expect(guardadoDe(fase).leerTurno(), isNull);
    });

    test('Cerrar la pantalla también lo borra', () {
      final fase = enEspera()..terminarTurno(tableroLleno: false);

      fase.dispose();

      expect(guardadoDe(fase).leerTurno(), isNull);
    });
  });

  group('Unitarias: zonas que completan los demás', () {
    http.Response conZonas(Map<String, Object> zonas) {
      final datos =
          jsonDecode(utf8.decode(respuesta().bodyBytes))
              as Map<String, Object?>;
      return http.Response.bytes(
        utf8.encode(jsonEncode({...datos, 'zonas': zonas})),
        200,
      );
    }

    test('Avisa las zonas nuevas de otros jugadores', () async {
      final fase = compartida(
        (_) async => conZonas({
          '3': {'luis': 1},
        }),
      );
      addTearDown(fase.dispose);
      final avisos = <List<ZonaAjena>>[];
      fase.zonasAjenas.listen(avisos.add);

      await fase.finalizar(numeros);
      await Future<void>.delayed(Duration.zero);

      expect(avisos, [
        [(jugador: 'luis', zona: 3, ronda: 1)],
      ]);
    });

    test('Las zonas propias no se avisan', () async {
      final fase = compartida(
        (_) async => conZonas({
          '3': {'ana': 1},
        }),
      );
      addTearDown(fase.dispose);
      final avisos = <List<ZonaAjena>>[];
      fase.zonasAjenas.listen(avisos.add);

      await fase.finalizar(numeros);
      await Future<void>.delayed(Duration.zero);

      expect(avisos, isEmpty);
    });

    test('Sin zonas nuevas no avisa nada', () async {
      final fase = compartida((_) async => respuesta());
      addTearDown(fase.dispose);
      final avisos = <List<ZonaAjena>>[];
      fase.zonasAjenas.listen(avisos.add);

      await fase.finalizar(numeros);
      await Future<void>.delayed(Duration.zero);

      expect(avisos, isEmpty);
    });
  });

  group('Unitarias: avisos de zonas a media ronda', () {
    SalaPartida enRonda() => sala(
      finalizados: ['ana', 'luis'],
      configurada: true,
      miTablero: numeros,
      ronda: 1,
      dados: [5, 2],
    );

    http.Response conZonas(Map<String, Object> zonas, {List<String>? jugaron}) {
      final datos =
          jsonDecode(
                utf8.decode(
                  respuesta(
                    finalizados: ['ana', 'luis'],
                    configurada: true,
                    ronda: 1,
                    dados: [5, 2],
                    jugaron: jugaron ?? const [],
                  ).bodyBytes,
                ),
              )
              as Map<String, Object?>;
      return http.Response.bytes(
        utf8.encode(jsonEncode({...datos, 'zonas': zonas})),
        200,
      );
    }

    test('Lo de esta ronda no se avisa hasta que juegue', () async {
      final fase = compartida((peticion) async {
        return conZonas({
          '3': {'luis': 1},
        }, jugaron: peticion.url.path.endsWith('turno') ? ['ana'] : const []);
      }, inicial: enRonda())..iniciar();
      addTearDown(fase.dispose);
      final avisos = <List<ZonaAjena>>[];
      fase.zonasAjenas.listen(avisos.add);

      // Llega la consulta con la zona de luis, pero ana aún no mueve.
      await Future<void>.delayed(const Duration(milliseconds: 2300));
      expect(fase.sala.zonas, {
        3: {'luis': 1},
      });
      expect(avisos, isEmpty);

      fase.terminarTurno(tableroLleno: false);
      await Future<void>.delayed(Duration.zero);

      expect(avisos.expand((lista) => lista), [
        (jugador: 'luis', zona: 3, ronda: 1),
      ]);
    });

    test('Al jugar su turno, recibe el aviso que esperaba', () async {
      var respuestas = 0;
      final fase = compartida((peticion) async {
        respuestas++;
        return conZonas({
          '3': {'luis': 1},
        }, jugaron: peticion.url.path.endsWith('turno') ? ['ana'] : const []);
      }, inicial: enRonda());
      addTearDown(fase.dispose);
      final avisos = <List<ZonaAjena>>[];
      fase.zonasAjenas.listen(avisos.add);

      fase.terminarTurno(tableroLleno: false);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(respuestas, greaterThan(0));
      expect(avisos.expand((lista) => lista), [
        (jugador: 'luis', zona: 3, ronda: 1),
      ]);
    });

    test('Si empata esa zona en su turno, no recibe aviso', () async {
      final fase = compartida(
        (_) async => conZonas(
          {
            '3': {'luis': 1, 'ana': 1},
          },
          jugaron: ['ana'],
        ),
        inicial: enRonda(),
      );
      addTearDown(fase.dispose);
      final avisos = <List<ZonaAjena>>[];
      fase.zonasAjenas.listen(avisos.add);

      fase.terminarTurno(tableroLleno: false, zonaCompletada: 3);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(avisos, isEmpty);
    });
  });
}

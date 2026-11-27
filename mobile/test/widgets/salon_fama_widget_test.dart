// Prueba de widgets: el Salón de la Fama (podio, Top 10, «...» y mi puesto),
// cómo se actualiza y cómo se llega desde el menú.

import 'dart:convert';

import 'package:brilliant_mobile/avatar_jugador.dart';
import 'package:brilliant_mobile/datos_salon_fama.dart';
import 'package:brilliant_mobile/fila_salon_fama.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/pantalla_salon_fama.dart';
import 'package:brilliant_mobile/podio_salon_fama.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_salon_fama.dart';
import 'package:brilliant_mobile/texto_elo_salon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Un servidor de mentira: responde [respuesta] (que la prueba puede cambiar)
/// y cuenta cuántas veces se le pidió el Salón.
class ServidorSalon {
  Map<String, Object?> respuesta = top(10);
  int pedidos = 0;
  bool caido = false;

  late final ServicioAuth auth = ServicioAuth(
    servidor: 'https://servidor:8443',
    cliente: MockClient((p) async {
      if (p.url.path == '/api/salon-fama') pedidos++;
      if (caido) throw http.ClientException('Sin red');
      final datos = p.url.path == '/api/salon-fama'
          ? {'ok': true, 'mensaje': 'Salón de la Fama.', ...respuesta}
          : {'ok': true, 'mensaje': 'ELO.', 'elo': 0};
      return http.Response.bytes(utf8.encode(jsonEncode(datos)), 200);
    }),
  )..sesion = const Sesion(usuario: 'ana', nombre: 'Ana', token: 'abc');
}

Map<String, Object?> p(int lugar, String usuario, int elo) => {
  'lugar': lugar,
  'usuario': usuario,
  'elo': elo,
};

/// Un Top de [cantidad] jugadores j1..jN, de 2,450 ELO para abajo.
Map<String, Object?> top(
  int cantidad, {
  Map<String, Object?>? yo,
  int? jugadores,
}) => {
  'ok': true,
  'top': [for (var i = 1; i <= cantidad; i++) p(i, 'j$i', 2500 - i * 50)],
  'yo': yo,
  'jugadores': jugadores ?? cantidad,
};

Future<void> esperarServidor(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

Future<void> abrir(
  WidgetTester tester,
  ServidorSalon servidor, {
  Duration cadaCuanto = const Duration(seconds: 15),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: PantallaSalonFama(
        servicio: ServicioSalonFama(servidor.auth),
        usuario: 'ana',
        cadaCuanto: cadaCuanto,
      ),
    ),
  );
  await esperarServidor(tester);
}

Finder en(String clave, String texto) =>
    find.descendant(of: find.byKey(Key(clave)), matching: find.text(texto));

/// Lleva a la vista algo que esté más abajo en la lista.
Future<void> verAbajo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.descendant(
      of: find.byKey(const Key('salon-lista')),
      matching: find.byType(Scrollable),
    ),
  );
}

void main() {
  group('Widgets: Salón de la Fama, el Top 10', () {
    testWidgets('Se ve el título y cuántos jugadores hay', (tester) async {
      final servidor = ServidorSalon()..respuesta = top(10, jugadores: 80);
      await abrir(tester, servidor);

      expect(find.text('Salón de la Fama'), findsOneWidget);
      expect(find.text('80 jugadores en el ranking'), findsOneWidget);
    });

    testWidgets('Los tres primeros van en el podio', (tester) async {
      await abrir(tester, ServidorSalon());

      for (final j in ['j1', 'j2', 'j3']) {
        expect(
          find.descendant(
            of: find.byKey(const Key('podio')),
            matching: find.byKey(Key('podio-$j')),
          ),
          findsOneWidget,
        );
      }
      expect(find.byKey(const Key('salon-puesto-j1')), findsNothing);
    });

    testWidgets('Oro, plata y bronce para el 1.º, 2.º y 3.º', (tester) async {
      await abrir(tester, ServidorSalon());

      expect(find.byKey(const Key('medalla-oro-j1')), findsOneWidget);
      expect(find.byKey(const Key('medalla-plata-j2')), findsOneWidget);
      expect(find.byKey(const Key('medalla-bronce-j3')), findsOneWidget);
    });

    testWidgets('En el podio el 1.º va al centro y más alto', (tester) async {
      await abrir(tester, ServidorSalon());

      final x = {
        for (final j in ['j1', 'j2', 'j3'])
          j: tester.getCenter(find.byKey(Key('podio-$j'))).dx,
      };
      expect(x['j2']!, lessThan(x['j1']!));
      expect(x['j1']!, lessThan(x['j3']!));
      expect(
        tester.getTopLeft(find.byKey(const Key('medalla-oro-j1'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('medalla-plata-j2'))).dy,
        ),
      );
    });

    testWidgets('El podio dice usuario y ELO con comas', (tester) async {
      await abrir(tester, ServidorSalon());

      expect(en('podio-j1', '@j1'), findsOneWidget);
      expect(en('podio-j1', '2,450 ELO'), findsOneWidget);
      expect(en('podio-j3', '2,350 ELO'), findsOneWidget);
    });

    testWidgets('Del 4.º al 10.º van en filas con lugar, usuario y ELO', (
      tester,
    ) async {
      await abrir(tester, ServidorSalon());

      for (var i = 4; i <= 10; i++) {
        await verAbajo(tester, find.byKey(Key('salon-puesto-j$i')));
        expect(en('salon-puesto-j$i', '$i'), findsOneWidget);
        expect(en('salon-puesto-j$i', '@j$i'), findsOneWidget);
        expect(
          en('salon-puesto-j$i', '${eloConComas(2500 - i * 50)} ELO'),
          findsOneWidget,
        );
      }
    });

    testWidgets('Las filas van de mayor a menor ELO', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await abrir(tester, ServidorSalon());

      final alturas = [
        for (var i = 4; i <= 10; i++)
          tester.getTopLeft(find.byKey(Key('salon-puesto-j$i'))).dy,
      ];
      expect(alturas, orderedEquals([...alturas]..sort()));
    });
  });

  group('Widgets: Salón de la Fama, mi puesto', () {
    testWidgets('Fuera del Top 10: «...» y luego mi lugar, usuario y ELO', (
      tester,
    ) async {
      final servidor = ServidorSalon()
        ..respuesta = top(10, yo: p(66, 'ana', 1350), jugadores: 80);
      await abrir(tester, servidor);

      await verAbajo(tester, find.byKey(const Key('salon-yo')));
      expect(find.byKey(const Key('salon-separador')), findsOneWidget);
      expect(find.text('...'), findsOneWidget);
      expect(en('salon-yo', '66'), findsOneWidget);
      expect(en('salon-yo', '@ana (tú)'), findsOneWidget);
      expect(en('salon-yo', '1,350 ELO'), findsOneWidget);
    });

    testWidgets('Los «...» van después del 10.º y antes de mi puesto', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final servidor = ServidorSalon()
        ..respuesta = top(10, yo: p(66, 'ana', 1350));
      await abrir(tester, servidor);

      final diez = tester.getTopLeft(find.byKey(const Key('salon-puesto-j10')));
      final puntos = tester.getTopLeft(
        find.byKey(const Key('salon-separador')),
      );
      final yo = tester.getTopLeft(find.byKey(const Key('salon-yo')));
      expect(diez.dy, lessThan(puntos.dy));
      expect(puntos.dy, lessThan(yo.dy));
    });

    testWidgets('Dentro del Top: salgo en mi lugar, sin «...» ni repetirme', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [
            for (var i = 1; i <= 10; i++)
              p(i, i == 7 ? 'ana' : 'j$i', 2500 - i * 50),
          ],
          'yo': null,
        };
      await abrir(tester, servidor);

      expect(find.byKey(const Key('salon-separador')), findsNothing);
      expect(find.byKey(const Key('salon-yo')), findsNothing);
      expect(find.text('@ana (tú)'), findsOneWidget);
      expect(en('salon-puesto-ana', '@ana (tú)'), findsOneWidget);
    });

    testWidgets('En el podio, mi nombre dice (tú)', (tester) async {
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [p(1, 'ana', 90), p(2, 'luis', 50)],
          'yo': null,
        };
      await abrir(tester, servidor);

      expect(en('podio-ana', '@ana (tú)'), findsOneWidget);
      expect(find.byKey(const Key('salon-separador')), findsNothing);
    });

    testWidgets('Mi fila se resalta', (tester) async {
      final servidor = ServidorSalon()
        ..respuesta = top(10, yo: p(66, 'ana', 1350));
      await abrir(tester, servidor);
      await verAbajo(tester, find.byKey(const Key('salon-yo')));

      expect(
        tester.widget<FilaSalonFama>(find.byKey(const Key('salon-yo'))).soyYo,
        isTrue,
      );
      expect(
        tester
            .widget<FilaSalonFama>(find.byKey(const Key('salon-puesto-j5')))
            .soyYo,
        isFalse,
      );
    });
  });

  group('Widgets: Salón de la Fama, casos especiales', () {
    testWidgets('Con menos de tres jugadores, el podio tiene los que hay', (
      tester,
    ) async {
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [p(1, 'ana', 16), p(2, 'luis', 0)],
          'yo': null,
        };
      await abrir(tester, servidor);

      expect(find.byKey(const Key('podio-ana')), findsOneWidget);
      expect(find.byKey(const Key('podio-luis')), findsOneWidget);
      expect(find.byType(FilaSalonFama), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Con un solo jugador también se ve', (tester) async {
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [p(1, 'ana', 0)],
          'yo': null,
          'jugadores': 1,
        };
      await abrir(tester, servidor);

      expect(find.byKey(const Key('medalla-oro-ana')), findsOneWidget);
      expect(find.text('1 jugador en el ranking'), findsOneWidget);
    });

    testWidgets('Empatados comparten lugar y medalla', (tester) async {
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [p(1, 'ana', 16), p(1, 'luis', 16), p(2, 'eva', 0)],
          'yo': null,
        };
      await abrir(tester, servidor);

      expect(find.byKey(const Key('medalla-oro-ana')), findsOneWidget);
      expect(find.byKey(const Key('medalla-oro-luis')), findsOneWidget);
      expect(find.byKey(const Key('medalla-plata-eva')), findsOneWidget);
    });

    testWidgets('Quien empata con el 3.º fuera del podio conserva el bronce', (
      tester,
    ) async {
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [p(1, 'a', 9), p(2, 'b', 8), p(3, 'c', 7), p(3, 'd', 7)],
          'yo': null,
        };
      await abrir(tester, servidor);

      final fila = tester.widget<Container>(
        find
            .ancestor(
              of: find.byKey(const Key('salon-lugar-d')),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoracion = fila.decoration! as BoxDecoration;
      expect(decoracion.color, Medalla.bronce.claro);
    });

    testWidgets('Sin jugadores dice que todavía no hay nadie', (tester) async {
      final servidor = ServidorSalon()
        ..respuesta = {'top': <Object>[], 'yo': null, 'jugadores': 0};
      await abrir(tester, servidor);

      expect(find.byKey(const Key('salon-vacio')), findsOneWidget);
      expect(find.byType(PodioSalonFama), findsNothing);
    });

    testWidgets('En un celular angosto, con nombres largos, no se desborda', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [
            for (var i = 1; i <= 10; i++)
              p(i, 'un_nombre_de_usuario_muy_largo_$i', 1234567 - i),
          ],
          'yo': p(1066, 'ana_con_nombre_tambien_largo', 1350000),
        };
      await abrir(tester, servidor);
      await verAbajo(tester, find.byKey(const Key('salon-yo')));

      expect(tester.takeException(), isNull);
    });
  });

  group('Widgets: Salón de la Fama, cargar y actualizar', () {
    testWidgets('Mientras llega se ve que está cargando', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaSalonFama(
            servicio: ServicioSalonFama(ServidorSalon().auth),
            usuario: 'ana',
          ),
        ),
      );

      expect(find.byKey(const Key('salon-cargando')), findsOneWidget);
      await esperarServidor(tester);
      expect(find.byKey(const Key('salon-cargando')), findsNothing);
    });

    testWidgets('Sin conexión se ve el error y se puede reintentar', (
      tester,
    ) async {
      final servidor = ServidorSalon()..caido = true;
      await abrir(tester, servidor);

      expect(find.byKey(const Key('salon-error')), findsOneWidget);
      expect(find.byType(PodioSalonFama), findsNothing);

      servidor.caido = false;
      await tester.tap(find.byKey(const Key('salon-reintentar')));
      await esperarServidor(tester);

      expect(find.byKey(const Key('salon-error')), findsNothing);
      expect(find.byType(PodioSalonFama), findsOneWidget);
    });

    testWidgets('Se actualiza solo mientras está abierto', (tester) async {
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [p(1, 'luis', 20), p(2, 'ana', 10)],
          'yo': null,
        };
      await abrir(tester, servidor, cadaCuanto: const Duration(seconds: 5));
      expect(find.byKey(const Key('medalla-oro-luis')), findsOneWidget);

      // ana gana una partida y pasa al primer lugar.
      servidor.respuesta = {
        'top': [p(1, 'ana', 26), p(2, 'luis', 4)],
        'yo': null,
      };
      await tester.pump(const Duration(seconds: 5));
      await esperarServidor(tester);

      expect(find.byKey(const Key('medalla-oro-ana')), findsOneWidget);
      expect(en('podio-ana', '26 ELO'), findsOneWidget);
      expect(servidor.pedidos, 2);
    });

    testWidgets('Si falla una actualización, se sigue viendo el ranking', (
      tester,
    ) async {
      final servidor = ServidorSalon();
      await abrir(tester, servidor, cadaCuanto: const Duration(seconds: 5));

      servidor.caido = true;
      await tester.pump(const Duration(seconds: 5));
      await esperarServidor(tester);

      expect(find.byType(PodioSalonFama), findsOneWidget);
      expect(find.byKey(const Key('salon-error')), findsOneWidget);
    });

    testWidgets('Al cerrar la pantalla deja de pedir', (tester) async {
      final servidor = ServidorSalon();
      await abrir(tester, servidor, cadaCuanto: const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());

      await tester.pump(const Duration(seconds: 20));
      expect(servidor.pedidos, 1);
    });

    testWidgets('Deslizar hacia abajo lo actualiza', (tester) async {
      final servidor = ServidorSalon();
      await abrir(tester, servidor);

      await tester.fling(
        find.byKey(const Key('salon-lista')),
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await esperarServidor(tester);
      await tester.pump(const Duration(seconds: 1));

      expect(servidor.pedidos, 2);
    });
  });

  group('Widgets: Salón de la Fama, diseño', () {
    testWidgets('Cada fila lleva el avatar con las iniciales del jugador', (
      tester,
    ) async {
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [
            p(1, 'a', 9),
            p(2, 'b', 8),
            p(3, 'c', 7),
            p(4, 'tito_juega', 6),
          ],
          'yo': null,
        };
      await abrir(tester, servidor);

      expect(
        find.descendant(
          of: find.byKey(const Key('salon-puesto-tito_juega')),
          matching: find.byType(AvatarJugador),
        ),
        findsOneWidget,
      );
      expect(en('salon-puesto-tito_juega', 'TJ'), findsOneWidget);
    });

    testWidgets('En el podio cada uno tiene su avatar y su número', (
      tester,
    ) async {
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [p(1, 'valentina_gm', 9), p(2, 'el_crack99', 8)],
          'yo': null,
        };
      await abrir(tester, servidor);

      expect(en('podio-valentina_gm', 'VG'), findsOneWidget);
      expect(en('podio-el_crack99', 'EC'), findsOneWidget);
      // El lugar va en la medallita del avatar y grabado en el escalón.
      expect(en('podio-valentina_gm', '1'), findsNWidgets(2));
      expect(en('podio-el_crack99', '2'), findsNWidgets(2));
    });

    testWidgets('Sobre el 1.º hay un trofeo', (tester) async {
      await abrir(tester, ServidorSalon());

      expect(
        find.descendant(
          of: find.byKey(const Key('podio-j1')),
          matching: find.byIcon(Icons.emoji_events),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('podio-j2')),
          matching: find.byIcon(Icons.emoji_events),
        ),
        findsNothing,
      );
    });

    testWidgets('Fuera del Top, sobre mi fila dice TU POSICIÓN', (
      tester,
    ) async {
      final servidor = ServidorSalon()
        ..respuesta = top(10, yo: p(66, 'ana', 1350));
      await abrir(tester, servidor);
      await verAbajo(tester, find.byKey(const Key('salon-yo')));

      expect(find.text('TU POSICIÓN'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('salon-tu-posicion'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('salon-yo'))).dy),
      );
    });

    testWidgets('Dentro del Top no sale TU POSICIÓN', (tester) async {
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [p(1, 'luis', 9), p(2, 'ana', 5)],
          'yo': null,
        };
      await abrir(tester, servidor);

      expect(find.byKey(const Key('salon-tu-posicion')), findsNothing);
    });

    testWidgets('Mi fila va en dorado y las demás en blanco', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final servidor = ServidorSalon()
        ..respuesta = top(10, yo: p(66, 'ana', 1350));
      await abrir(tester, servidor);

      Color? fondo(String clave) =>
          ((tester.widget<Container>(
                    find
                        .descendant(
                          of: find.byKey(Key(clave)),
                          matching: find.byType(Container),
                        )
                        .first,
                  )).decoration
                  as BoxDecoration?)
              ?.color;
      expect(fondo('salon-yo'), colorFilaMia);
      expect(fondo('salon-puesto-j5'), Colors.white);
    });

    testWidgets('El ELO de cada fila va con el número y la palabra ELO', (
      tester,
    ) async {
      await abrir(tester, ServidorSalon());

      expect(
        find.descendant(
          of: find.byKey(const Key('salon-puesto-j4')),
          matching: find.byType(TextoEloSalon),
        ),
        findsOneWidget,
      );
      expect(en('salon-puesto-j4', '2,300 ELO'), findsOneWidget);
    });

    testWidgets('Arriba va el escenario oscuro con el título', (tester) async {
      await abrir(tester, ServidorSalon());

      final barra = tester.widget<AppBar>(find.byType(AppBar));
      expect(barra.backgroundColor, colorEscenario);
      expect(find.text('LOS 10 MEJORES POR ELO'), findsOneWidget);
    });

    testWidgets('Las filas terminan de aparecer del todo', (tester) async {
      await abrir(tester, ServidorSalon());
      await tester.pump(const Duration(seconds: 1));

      final opacidad = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(const Key('salon-puesto-j4')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacidad.opacity, 1);
    });

    testWidgets('Con el escenario y el podio, un celular angosto no se '
        'desborda', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final servidor = ServidorSalon()
        ..respuesta = {
          'top': [
            p(1, 'un_nombre_larguisimo_de_verdad', 1234567),
            p(2, 'otro_nombre_tambien_largo', 1234566),
            p(3, 'y_uno_mas_bien_largo_tambien', 1234565),
          ],
          'yo': null,
        };
      await abrir(tester, servidor);
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  });

  group('Widgets: Salón de la Fama en el menú', () {
    testWidgets('El menú tiene el apartado y abre el Salón', (tester) async {
      final servidor = ServidorSalon();
      await tester.pumpWidget(BrilliantApp(auth: servidor.auth));
      await esperarServidor(tester);

      final boton = find.byKey(const Key('menu-salon-fama'));
      await tester.scrollUntilVisible(
        boton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(en('salon-fama', 'Salón de la Fama'), findsOneWidget);

      await tester.tap(boton);
      // Mientras carga gira el indicador: no se espera a que todo pare.
      await tester.pump(const Duration(milliseconds: 500));
      await esperarServidor(tester);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PantallaSalonFama), findsOneWidget);
      expect(find.byKey(const Key('podio')), findsOneWidget);
      expect(servidor.pedidos, 1);
    });

    testWidgets('Sin sesión no aparece el Salón en el menú', (tester) async {
      await tester.pumpWidget(const BrilliantApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('salon-fama')), findsNothing);
    });
  });
}

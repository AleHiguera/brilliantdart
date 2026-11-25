import 'dart:convert';

import 'package:brilliant_mobile/almacen_pestana.dart';
import 'package:brilliant_mobile/latido_sesion.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Corta la red del servidor falso mientras [apagada] sea true.
class Red {
  bool apagada = false;
}

/// Servidor falso: acepta solo a "ana" con el PIN 1234.
ServicioAuth authFalso({
  List<String>? peticiones,
  int codigoLatido = 200,
  Red? red,
  AlmacenPestana? almacen,
}) {
  return ServicioAuth(
    servidor: 'https://servidor:8443',
    almacen: almacen,
    cliente: MockClient((peticion) async {
      if (red?.apagada ?? false) throw http.ClientException('Sin red');
      // El menú pide el ELO al abrirse; se prueba aparte.
      if (peticion.url.path == '/api/elo') {
        return respuesta({'ok': true, 'mensaje': 'ELO.', 'elo': 1000}, 200);
      }
      peticiones?.add(peticion.url.path);
      if (peticion.url.path == '/api/logout') {
        return respuesta({'ok': true, 'mensaje': 'Sesión cerrada.'}, 200);
      }
      if (peticion.url.path == '/api/latido') {
        return respuesta({
          'ok': codigoLatido == 200,
          'mensaje': 'Latido.',
        }, codigoLatido);
      }
      final datos = peticion.bodyFields;
      if (peticion.url.path == '/api/registro') {
        if (datos['usuario'] == 'ana') {
          return respuesta({
            'ok': false,
            'mensaje': 'El usuario "ana" ya está en uso, elige otro.',
          }, 409);
        }
        return respuesta({
          'ok': true,
          'mensaje': 'Cuenta creada correctamente.',
          'usuario': datos['usuario']!,
          'nombre': datos['nombre']!,
          'token': 'nuevo',
        }, 200);
      }
      if (datos['usuario'] == 'ana' && datos['password'] == '1234') {
        return respuesta({
          'ok': true,
          'mensaje': 'Sesión iniciada.',
          'usuario': 'ana',
          'nombre': 'Ana',
          'token': 'abc',
        }, 200);
      }
      if (datos['usuario'] == 'ocupado' && datos['password'] == '1234') {
        return respuesta({'ok': false, 'mensaje': mensajeOcupado}, 409);
      }
      return respuesta({
        'ok': false,
        'mensaje': datos['usuario'] == 'ana' || datos['usuario'] == 'ocupado'
            ? mensajePinIncorrecto
            : 'El usuario "${datos['usuario']}" no existe. Revisa cómo lo '
                  'escribiste o crea una cuenta.',
      }, 401);
    }),
  );
}

const String mensajePinIncorrecto =
    'El PIN es incorrecto. Revisa los 4 números e inténtalo de nuevo.';
const String mensajeOcupado =
    'El usuario "ocupado" ya está conectado en otro dispositivo. Cierra esa '
    'sesión para entrar aquí.';

/// El cuadro rojo de abajo de la pantalla (inicio de sesión o registro).
Finder cuadroError({String clave = 'login-error'}) => find.byKey(Key(clave));

/// Un texto dentro del cuadro de error.
Finder enCuadro(String texto, {String clave = 'login-error'}) =>
    find.descendant(
      of: cuadroError(clave: clave),
      matching: find.textContaining(texto),
    );

/// Si el campo tiene el borde rojo de error.
bool marcado(WidgetTester tester, String clave) =>
    tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(Key(clave)),
            matching: find.byType(TextField),
          ),
        )
        .decoration
        ?.errorText !=
    null;

/// JSON en UTF-8, como lo envía el servidor real (http.Response con texto
/// usaría latin1 y estropearía las tildes).
http.Response respuesta(Map<String, Object> datos, int codigo) =>
    http.Response.bytes(utf8.encode(jsonEncode(datos)), codigo);

Future<void> entrar(WidgetTester tester, String usuario, String pin) async {
  await tester.enterText(find.byKey(const Key('login-usuario')), usuario);
  await tester.enterText(find.byKey(const Key('login-pin')), pin);
  // Con un aviso arriba el botón puede quedar más abajo de la pantalla.
  await tester.ensureVisible(find.byKey(const Key('login-entrar')));
  await tester.pumpAndSettle();
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

      expect(enCuadro('Error'), findsOneWidget);
      expect(enCuadro(mensajePinIncorrecto), findsOneWidget);
      expect(find.text('Elige tu mapa'), findsNothing);
    });

    testWidgets('Si el usuario no existe se dice cuál', (tester) async {
      await tester.pumpWidget(BrilliantApp(auth: authFalso()));

      await entrar(tester, 'lucia', '1234');

      expect(
        enCuadro('El usuario "lucia" no existe. Revisa cómo lo escribiste'),
        findsOneWidget,
      );
      expect(find.text('Elige tu mapa'), findsNothing);
    });

    testWidgets('Si ya está conectado en otro lado se explica', (tester) async {
      await tester.pumpWidget(BrilliantApp(auth: authFalso()));

      await entrar(tester, 'ocupado', '1234');

      expect(enCuadro(mensajeOcupado), findsOneWidget);
    });

    testWidgets('El cuadro de error va abajo, justo antes de Entrar', (
      tester,
    ) async {
      await tester.pumpWidget(BrilliantApp(auth: authFalso()));

      await entrar(tester, 'ana', '9999');

      final cuadro = tester.getRect(cuadroError());
      expect(
        cuadro.top,
        greaterThan(tester.getRect(find.byKey(const Key('login-pin'))).bottom),
      );
      expect(
        cuadro.bottom,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(const Key('login-entrar'))).top,
        ),
      );
    });

    testWidgets('Sin usuario ni PIN se avisan los dos, abajo y sin enviar', (
      tester,
    ) async {
      final peticiones = <String>[];
      await tester.pumpWidget(
        BrilliantApp(auth: authFalso(peticiones: peticiones)),
      );

      await entrar(tester, '', '');

      expect(enCuadro('Escribe tu usuario.'), findsOneWidget);
      expect(
        enCuadro('El PIN debe tener exactamente 4 números.'),
        findsOneWidget,
      );
      // Debajo de los campos ya no sale texto: solo se marcan en rojo.
      expect(find.text('Escribe tu usuario.'), findsNothing);
      expect(marcado(tester, 'login-usuario'), isTrue);
      expect(marcado(tester, 'login-pin'), isTrue);
      expect(peticiones, isEmpty);
    });

    testWidgets('Al corregir y volver a intentar se quita la marca', (
      tester,
    ) async {
      await tester.pumpWidget(BrilliantApp(auth: authFalso()));
      await entrar(tester, '', '1234');
      expect(marcado(tester, 'login-usuario'), isTrue);

      await entrar(tester, 'ana', '9999');

      expect(marcado(tester, 'login-usuario'), isFalse);
      expect(enCuadro('Escribe tu usuario.'), findsNothing);
      expect(enCuadro(mensajePinIncorrecto), findsOneWidget);
    });

    testWidgets('El PIN debe tener 4 números antes de enviarse', (
      tester,
    ) async {
      final peticiones = <String>[];
      await tester.pumpWidget(
        BrilliantApp(auth: authFalso(peticiones: peticiones)),
      );

      await entrar(tester, 'ana', '12');

      expect(
        enCuadro('El PIN debe tener exactamente 4 números.'),
        findsOneWidget,
      );
      expect(marcado(tester, 'login-pin'), isTrue);
      expect(marcado(tester, 'login-usuario'), isFalse);
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
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('logout-confirm')));
      await esperarServidor(tester);

      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(peticiones, ['/api/login', '/api/logout']);
      expect(auth.sesion, isNull);
    });

    testWidgets('Cancelar el cierre de sesión mantiene la sesión', (
      tester,
    ) async {
      final auth = authFalso();
      await tester.pumpWidget(BrilliantApp(auth: auth));
      await entrar(tester, 'ana', '1234');

      await tester.tap(find.byKey(const Key('logout-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Elige tu mapa'), findsOneWidget);
      expect(auth.sesion, isNotNull);
    });

    testWidgets('Con la sesión abierta se envían latidos al servidor', (
      tester,
    ) async {
      final peticiones = <String>[];
      await tester.pumpWidget(
        BrilliantApp(auth: authFalso(peticiones: peticiones)),
      );
      await entrar(tester, 'ana', '1234');

      await tester.pump(LatidoSesion.intervalo);
      await esperarServidor(tester);

      expect(peticiones, ['/api/login', '/api/latido']);
      expect(find.text('Elige tu mapa'), findsOneWidget);
    });

    testWidgets('Si el servidor no responde al latido se sigue jugando', (
      tester,
    ) async {
      final auth = authFalso(codigoLatido: 503);
      await tester.pumpWidget(BrilliantApp(auth: auth));
      await entrar(tester, 'ana', '1234');

      await tester.pump(LatidoSesion.intervalo);
      await esperarServidor(tester);

      expect(find.text('Elige tu mapa'), findsOneWidget);
      expect(auth.sesion, isNotNull);
    });

    testWidgets('Si el servidor rechaza el latido se vuelve al inicio', (
      tester,
    ) async {
      final auth = authFalso(codigoLatido: 401);
      await tester.pumpWidget(BrilliantApp(auth: auth));
      await entrar(tester, 'ana', '1234');

      await tester.pump(LatidoSesion.intervalo);
      await esperarServidor(tester);

      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(
        find.text('Tu sesión ya no está activa, inicia sesión de nuevo.'),
        findsOneWidget,
      );
      expect(auth.sesion, isNull);
    });
  });

  group('Widgets: desconexión de la red', () {
    /// Entra con la sesión de «ana» y corta la red.
    Future<(ServicioAuth, Red, List<String>)> sinRed(
      WidgetTester tester,
    ) async {
      final red = Red();
      final peticiones = <String>[];
      final auth = authFalso(red: red, peticiones: peticiones);
      await tester.pumpWidget(BrilliantApp(auth: auth));
      await entrar(tester, 'ana', '1234');
      red.apagada = true;
      return (auth, red, peticiones);
    }

    Future<void> latido(WidgetTester tester, Duration espera) async {
      await tester.pump(espera);
      await esperarServidor(tester);
    }

    testWidgets('Sin red, a los pocos segundos vuelve al inicio con un aviso', (
      tester,
    ) async {
      final (auth, _, _) = await sinRed(tester);

      await latido(tester, LatidoSesion.intervalo);
      await latido(tester, LatidoSesion.reintento);
      expect(find.text('Elige tu mapa'), findsOneWidget);
      await latido(tester, LatidoSesion.reintento);

      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('login-aviso')),
          matching: find.textContaining('No hay conexión con el servidor.'),
        ),
        findsOneWidget,
      );
      expect(auth.sesion, isNull);
    });

    testWidgets('El aviso no es un error rojo', (tester) async {
      await sinRed(tester);

      await latido(tester, LatidoSesion.intervalo);
      await latido(tester, LatidoSesion.reintento);
      await latido(tester, LatidoSesion.reintento);

      expect(find.byKey(const Key('login-error')), findsNothing);
      final texto = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('login-aviso')),
          matching: find.byType(Text),
        ),
      );
      final rojo = Theme.of(
        tester.element(find.byKey(const Key('login-aviso'))),
      ).colorScheme.error;
      expect(texto.style?.color, isNot(rojo));
      expect(find.textContaining('No se pudo conectar'), findsNothing);
    });

    testWidgets('Tras un latido perdido se reintenta enseguida', (
      tester,
    ) async {
      final (_, red, peticiones) = await sinRed(tester);

      await latido(tester, LatidoSesion.intervalo);
      red.apagada = false;
      await latido(tester, LatidoSesion.reintento);

      expect(peticiones, ['/api/login', '/api/latido']);
    });

    testWidgets('Si la red vuelve a tiempo se sigue jugando', (tester) async {
      final (auth, red, _) = await sinRed(tester);

      await latido(tester, LatidoSesion.intervalo);
      await latido(tester, LatidoSesion.reintento);
      red.apagada = false;
      await latido(tester, LatidoSesion.reintento);
      red.apagada = true;
      await latido(tester, LatidoSesion.intervalo);
      await latido(tester, LatidoSesion.reintento);

      expect(find.text('Elige tu mapa'), findsOneWidget);
      expect(auth.sesion, isNotNull);
    });

    testWidgets('Al volver a entrar se cierra la sesión vieja y se entra', (
      tester,
    ) async {
      final (_, red, peticiones) = await sinRed(tester);
      await latido(tester, LatidoSesion.intervalo);
      await latido(tester, LatidoSesion.reintento);
      await latido(tester, LatidoSesion.reintento);

      red.apagada = false;
      await entrar(tester, 'ana', '1234');
      // Son dos peticiones seguidas: cerrar la vieja y entrar.
      await esperarServidor(tester);

      expect(find.text('Elige tu mapa'), findsOneWidget);
      expect(peticiones, ['/api/login', '/api/logout', '/api/login']);
      expect(find.byKey(const Key('login-aviso')), findsNothing);
    });

    testWidgets('Entrar sin red sí muestra el error de conexión', (
      tester,
    ) async {
      final red = Red()..apagada = true;
      await tester.pumpWidget(BrilliantApp(auth: authFalso(red: red)));

      await entrar(tester, 'ana', '1234');

      expect(find.byKey(const Key('login-error')), findsOneWidget);
      expect(find.text('Inicia sesión'), findsOneWidget);
    });
  });

  group('Widgets: recargar la página', () {
    testWidgets('Tras entrar, recargar no pide entrar de nuevo', (
      tester,
    ) async {
      final almacen = AlmacenEnMemoria();
      await tester.pumpWidget(BrilliantApp(auth: authFalso(almacen: almacen)));
      await entrar(tester, 'ana', '1234');

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(BrilliantApp(auth: authFalso(almacen: almacen)));
      await tester.pumpAndSettle();

      expect(find.text('Elige tu mapa'), findsOneWidget);
      expect(find.text('Inicia sesión'), findsNothing);
    });

    testWidgets('La sesión recuperada se comprueba enseguida', (tester) async {
      final almacen = AlmacenEnMemoria();
      authFalso(almacen: almacen).sesion = const Sesion(
        usuario: 'ana',
        nombre: 'Ana',
        token: 'abc',
      );
      final peticiones = <String>[];

      await tester.pumpWidget(
        BrilliantApp(
          auth: authFalso(almacen: almacen, peticiones: peticiones),
        ),
      );
      await tester.pump();
      await esperarServidor(tester);

      expect(peticiones, ['/api/latido']);
    });

    testWidgets('Si el servidor ya no la reconoce, vuelve al inicio', (
      tester,
    ) async {
      final almacen = AlmacenEnMemoria();
      authFalso(almacen: almacen).sesion = const Sesion(
        usuario: 'ana',
        nombre: 'Ana',
        token: 'abc',
      );

      await tester.pumpWidget(
        BrilliantApp(auth: authFalso(almacen: almacen, codigoLatido: 401)),
      );
      await tester.pump();
      await esperarServidor(tester);

      expect(find.text('Inicia sesión'), findsOneWidget);
      expect(
        find.text('Tu sesión ya no está activa, inicia sesión de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('Tras cerrar sesión, recargar pide entrar', (tester) async {
      final almacen = AlmacenEnMemoria();
      await tester.pumpWidget(BrilliantApp(auth: authFalso(almacen: almacen)));
      await entrar(tester, 'ana', '1234');
      await tester.tap(find.byKey(const Key('logout-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('logout-confirm')));
      await esperarServidor(tester);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(BrilliantApp(auth: authFalso(almacen: almacen)));
      await tester.pumpAndSettle();

      expect(find.text('Inicia sesión'), findsOneWidget);
    });
  });

  group('Widgets: registro', () {
    Future<void> abrirRegistro(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('login-crear-cuenta')));
      await tester.pumpAndSettle();
    }

    Future<void> rellenar(
      WidgetTester tester, {
      String usuario = 'luis',
      String nombre = 'Luis Pérez',
      String correo = 'luis@correo.com',
      String pin = '4321',
      String? confirmacion,
    }) async {
      await tester.enterText(
        find.byKey(const Key('registro-usuario')),
        usuario,
      );
      await tester.enterText(find.byKey(const Key('registro-nombre')), nombre);
      await tester.enterText(find.byKey(const Key('registro-correo')), correo);
      await tester.enterText(find.byKey(const Key('registro-pin')), pin);
      await tester.enterText(
        find.byKey(const Key('registro-confirmacion')),
        confirmacion ?? pin,
      );
      await tester.ensureVisible(find.byKey(const Key('registro-crear')));
      await tester.tap(find.byKey(const Key('registro-crear')));
      await esperarServidor(tester);
    }

    testWidgets('Crear una cuenta entra directo a elegir mapa', (tester) async {
      final auth = authFalso();
      await tester.pumpWidget(BrilliantApp(auth: auth));
      await abrirRegistro(tester);

      await rellenar(tester);

      expect(find.text('Elige tu mapa'), findsOneWidget);
      expect(find.text('Jugando como Luis Pérez (@luis)'), findsOneWidget);
      expect(auth.sesion?.token, 'nuevo');
    });

    testWidgets('Un usuario ocupado muestra el error del servidor', (
      tester,
    ) async {
      await tester.pumpWidget(BrilliantApp(auth: authFalso()));
      await abrirRegistro(tester);

      await rellenar(tester, usuario: 'ana');

      expect(
        find.text('El usuario "ana" ya está en uso, elige otro.'),
        findsOneWidget,
      );
      expect(find.text('Elige tu mapa'), findsNothing);
    });

    testWidgets('Los datos inválidos se avisan sin llamar al servidor', (
      tester,
    ) async {
      final peticiones = <String>[];
      await tester.pumpWidget(
        BrilliantApp(auth: authFalso(peticiones: peticiones)),
      );
      await abrirRegistro(tester);

      await rellenar(
        tester,
        usuario: '1ab',
        correo: 'sin-arroba',
        confirmacion: '0000',
      );

      const clave = 'registro-error';
      expect(enCuadro('Error', clave: clave), findsOneWidget);
      expect(
        enCuadro('El usuario debe empezar con una letra', clave: clave),
        findsOneWidget,
      );
      expect(
        enCuadro('El correo electrónico no es válido.', clave: clave),
        findsOneWidget,
      );
      expect(enCuadro('Los PIN no coinciden', clave: clave), findsOneWidget);
      // Solo se marcan los campos con problema.
      expect(marcado(tester, 'registro-usuario'), isTrue);
      expect(marcado(tester, 'registro-correo'), isTrue);
      expect(marcado(tester, 'registro-confirmacion'), isTrue);
      expect(marcado(tester, 'registro-nombre'), isFalse);
      expect(peticiones, isEmpty);
    });

    testWidgets('Un nombre sin letras se explica en el cuadro', (tester) async {
      await tester.pumpWidget(BrilliantApp(auth: authFalso()));
      await abrirRegistro(tester);

      await rellenar(tester, nombre: '1234');

      expect(
        enCuadro(
          'El nombre debe tener letras, no solo números o signos.',
          clave: 'registro-error',
        ),
        findsOneWidget,
      );
      expect(marcado(tester, 'registro-nombre'), isTrue);
    });
  });
}

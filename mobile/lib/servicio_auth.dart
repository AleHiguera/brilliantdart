import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:brilliant_mobile/control_conexion.dart';

/// Servidor de cuentas (proyecto RegistroClientes). Se puede cambiar al
/// compilar con `--dart-define=SERVIDOR=https://192.168.1.5:8443`.
const String _servidorConfigurado = String.fromEnvironment('SERVIDOR');
const int puertoServidorWeb = 8443;

/// Si no se configuró otro, se usa el mismo equipo desde el que se abrió la
/// app en el navegador, que normalmente es donde corre el servidor.
String servidorPorDefecto() {
  if (_servidorConfigurado.isNotEmpty) return _servidorConfigurado;
  final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
  return 'https://$host:$puertoServidorWeb';
}

class Sesion {
  const Sesion({
    required this.usuario,
    required this.nombre,
    required this.token,
  });

  final String usuario;
  final String nombre;
  final String token;
}

class ErrorAuth implements Exception {
  const ErrorAuth(this.mensaje, {this.codigo});

  final String mensaje;

  /// Código HTTP con el que el servidor rechazó la petición, si llegó a responder.
  final int? codigo;

  @override
  String toString() => mensaje;
}

/// La sesión se cerró sola porque se perdió la conexión con el servidor.
class Desconexion {
  const Desconexion({required this.abandonoPartida});

  /// Estaba jugando una partida, que el servidor cuenta como abandonada.
  final bool abandonoPartida;

  String get mensaje => abandonoPartida
      ? 'Te desconectaste del servidor y saliste de la partida: cuenta como '
            'abandono. Revisa tu conexión a internet e inicia sesión de nuevo.'
      : 'Te desconectaste del servidor. Revisa tu conexión a internet e '
            'inicia sesión de nuevo.';
}

/// Inicia y cierra sesión contra la API HTTPS del servidor de cuentas.
class ServicioAuth {
  ServicioAuth({
    String? servidor,
    http.Client? cliente,
    ControlConexion? conexion,
  }) : servidor = servidor ?? servidorPorDefecto(),
       _cliente = cliente ?? http.Client(),
       conexion = conexion ?? ControlConexion();

  static const Duration _tiempoMaximo = Duration(seconds: 10);

  /// Con la sesión abierta se espera menos: una respuesta que tarda tanto es
  /// una conexión perdida, y hay que notarlo pronto.
  static const Duration _tiempoMaximoConSesion = Duration(seconds: 5);

  String servidor;
  final http.Client _cliente;
  Sesion? sesion;

  /// Cuenta las peticiones de la sesión que no llegaron al servidor.
  final ControlConexion conexion;

  /// Cambia cuando la sesión se cierra por haber perdido la conexión.
  final ValueNotifier<Desconexion?> desconexion = ValueNotifier(null);

  /// Código de la partida que se está jugando con esta sesión, si hay una.
  String? partidaEnCurso;

  /// La sesión que se perdió sin conexión: el servidor aún la cree abierta.
  String? _tokenAbandonado;

  Future<Sesion> iniciarSesion(String usuario, String pin) async {
    await _cerrarSesionAbandonada();
    final respuesta = await _enviar(
      'login',
      cuerpo: {'usuario': usuario.trim(), 'password': pin},
    );
    return _abrirSesion(respuesta);
  }

  /// Crea la cuenta en el servidor y deja la sesión iniciada.
  Future<Sesion> registrar({
    required String usuario,
    required String nombre,
    required String correo,
    required String pin,
  }) async {
    await _cerrarSesionAbandonada();
    final respuesta = await _enviar(
      'registro',
      cuerpo: {
        'usuario': usuario.trim(),
        'nombre': nombre.trim(),
        'correo': correo.trim(),
        'password': pin,
      },
    );
    return _abrirSesion(respuesta);
  }

  /// Quien perdió la conexión y vuelve a entrar cierra antes su sesión vieja:
  /// si no, el servidor diría que el usuario ya está conectado, y así también
  /// sabe que dejó la partida en la que estaba.
  Future<void> _cerrarSesionAbandonada() async {
    final token = _tokenAbandonado;
    if (token == null) return;
    try {
      await _enviar('logout', cabeceras: {'Authorization': 'Bearer $token'});
      _tokenAbandonado = null;
    } on ErrorAuth {
      // Se vuelve a intentar en la siguiente entrada.
    }
  }

  Sesion _abrirSesion(Map<String, dynamic> respuesta) {
    conexion.reiniciar();
    desconexion.value = null;
    return sesion = Sesion(
      usuario: respuesta['usuario'] as String,
      nombre: respuesta['nombre'] as String,
      token: respuesta['token'] as String,
    );
  }

  /// Avisa al servidor de que la sesión sigue abierta. Devuelve false solo si
  /// el servidor dice que ya no vale; sin conexión se sigue intentando.
  Future<bool> mantenerSesion() async {
    final actual = sesion;
    if (actual == null) return true;
    try {
      await _enviar(
        'latido',
        cabeceras: {'Authorization': 'Bearer ${actual.token}'},
      );
      return true;
    } on ErrorAuth catch (e) {
      if (e.codigo != 401 || !identical(sesion, actual)) return true;
      sesion = null;
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    final actual = sesion;
    sesion = null;
    partidaEnCurso = null;
    if (actual == null) return;
    try {
      await _enviar(
        'logout',
        cabeceras: {'Authorization': 'Bearer ${actual.token}'},
      );
    } on ErrorAuth {
      // Aunque el servidor no responda, en la app la sesión ya queda cerrada.
    }
  }

  /// Hace una petición a la API a nombre de la sesión abierta.
  Future<Map<String, dynamic>> enviarConSesion(
    String accion,
    Map<String, String> cuerpo,
  ) {
    final actual = sesion;
    if (actual == null) {
      throw const ErrorAuth('Tu sesión ya no está activa.', codigo: 401);
    }
    return _enviar(
      accion,
      cuerpo: cuerpo,
      cabeceras: {'Authorization': 'Bearer ${actual.token}'},
    );
  }

  Future<Map<String, dynamic>> _enviar(
    String accion, {
    Map<String, String>? cuerpo,
    Map<String, String>? cabeceras,
  }) async {
    final Uri url;
    try {
      url = Uri.parse(servidor).resolve('/api/$accion');
    } on FormatException {
      throw const ErrorAuth('La dirección del servidor no es válida.');
    }

    final autorizacion = cabeceras?['Authorization'];
    final http.Response respuesta;
    try {
      respuesta = await _cliente
          .post(url, body: cuerpo, headers: cabeceras)
          .timeout(
            autorizacion == null ? _tiempoMaximo : _tiempoMaximoConSesion,
          );
    } on TimeoutException {
      throw _sinConexion(
        autorizacion,
        'El servidor $servidor no respondió a tiempo.',
      );
    } on http.ClientException {
      // En el navegador también llega aquí si aún no se aceptó el certificado
      // autofirmado del servidor.
      throw _sinConexion(
        autorizacion,
        'No se pudo conectar con $servidor. Comprueba que el servidor esté '
        'encendido. Si es la primera vez, abre $servidor en el navegador y '
        'acepta el certificado.',
      );
    }
    conexion.exito();

    final Map<String, dynamic> datos;
    try {
      datos =
          jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw const ErrorAuth('Respuesta inesperada del servidor.');
    }
    if (datos['ok'] != true) {
      throw ErrorAuth(
        datos['mensaje'] as String? ?? 'Error del servidor.',
        codigo: respuesta.statusCode,
      );
    }
    return datos;
  }
}

extension on ServicioAuth {
  /// La petición no llegó al servidor. Con la sesión abierta cuenta para saber
  /// si se perdió la conexión, y el mensaje ya no habla del certificado.
  ErrorAuth _sinConexion(String? autorizacion, String sinSesion) {
    final actual = sesion;
    if (actual == null || autorizacion != 'Bearer ${actual.token}') {
      return ErrorAuth(sinSesion);
    }
    if (conexion.fallo()) _desconectar(actual);
    return const ErrorAuth('Se perdió la conexión con el servidor.');
  }

  void _desconectar(Sesion actual) {
    _tokenAbandonado = actual.token;
    sesion = null;
    final abandono = partidaEnCurso != null;
    partidaEnCurso = null;
    conexion.reiniciar();
    desconexion.value = Desconexion(abandonoPartida: abandono);
  }
}

/// Hace llegar el [ServicioAuth] a todas las pantallas de la app.
class ProveedorAuth extends InheritedWidget {
  const ProveedorAuth({super.key, required this.auth, required super.child});

  final ServicioAuth auth;

  static ServicioAuth? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProveedorAuth>()?.auth;

  @override
  bool updateShouldNotify(ProveedorAuth oldWidget) => auth != oldWidget.auth;
}

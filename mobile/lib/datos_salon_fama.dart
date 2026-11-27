import 'package:brilliant_mobile/servicio_auth.dart';

/// Un puesto del Salón de la Fama: su lugar, el usuario y su ELO.
typedef PuestoSalon = ({int lugar, String usuario, int elo});

/// Lo que responde el servidor: los 10 mejores, el puesto de quien consulta
/// si quedó fuera de ellos (si está dentro no se repite) y cuántos jugadores
/// hay registrados.
class SalonFama {
  const SalonFama({required this.top, this.yo, required this.jugadores});

  final List<PuestoSalon> top;
  final PuestoSalon? yo;
  final int jugadores;

  /// Lee la respuesta del servidor. Un puesto que no se pueda leer se deja
  /// fuera; si no llega la lista, la respuesta no sirve.
  factory SalonFama.desdeJson(Map<String, dynamic> datos) {
    final top = datos['top'];
    if (top is! List) {
      throw const ErrorAuth('Respuesta inesperada del servidor.');
    }
    final puestos = [for (final valor in top) ?_puesto(valor)];
    return SalonFama(
      top: puestos,
      yo: _puesto(datos['yo']),
      jugadores: switch (datos['jugadores']) {
        final int jugadores => jugadores,
        _ => puestos.length,
      },
    );
  }

  static PuestoSalon? _puesto(Object? valor) => switch (valor) {
    {
      'lugar': final int lugar,
      'usuario': final String usuario,
      'elo': final int elo,
    }
        when lugar >= 1 =>
      (lugar: lugar, usuario: usuario, elo: elo),
    _ => null,
  };

  /// Mi puesto, esté dentro del Top o aparte; null si no aparezco.
  PuestoSalon? puestoDe(String? usuario) {
    if (usuario == null) return null;
    bool esMio(PuestoSalon puesto) =>
        puesto.usuario.toLowerCase() == usuario.toLowerCase();
    for (final puesto in top) {
      if (esMio(puesto)) return puesto;
    }
    return switch (yo) {
      final yo? when esMio(yo) => yo,
      _ => null,
    };
  }
}

/// El ELO con los miles separados por comas: 2450 → «2,450».
String eloConComas(int elo) {
  final digitos = elo.abs().toString();
  final grupos = <String>[];
  for (var fin = digitos.length; fin > 0; fin -= 3) {
    grupos.insert(0, digitos.substring(fin - 3 < 0 ? 0 : fin - 3, fin));
  }
  return '${elo < 0 ? '−' : ''}${grupos.join(',')}';
}

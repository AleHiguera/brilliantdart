import 'package:brilliant_mobile/datos_salon_fama.dart';
import 'package:brilliant_mobile/servicio_auth.dart';

/// Pide al servidor el Salón de la Fama de quien tiene la sesión.
class ServicioSalonFama {
  ServicioSalonFama(this.auth);

  final ServicioAuth auth;

  /// El ranking de ahora. De paso deja mi ELO al día en la sesión, para que el
  /// menú enseñe el mismo número que el Salón.
  Future<SalonFama> consultar() async {
    final salon = SalonFama.desdeJson(
      await auth.enviarConSesion('salon-fama', {}),
    );
    if (salon.puestoDe(auth.sesion?.usuario) case final mio?) {
      auth.elo.value = mio.elo;
    }
    return salon;
  }
}

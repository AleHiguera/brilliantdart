import 'package:brilliant_mobile/almacen_pestana.dart';

/// La dirección del servidor con la que se entró la última vez. En el
/// teléfono no hay página de la que tomarla, y la IP de la computadora que
/// hace de servidor puede cambiar: así solo se escribe cuando cambia.
class ServidorRecordado {
  ServidorRecordado(this._almacen);

  static const String clave = 'brilliant.servidor';

  final AlmacenPestana _almacen;

  String? leer() {
    final guardado = _almacen.leer(clave)?.trim();
    return guardado == null || guardado.isEmpty ? null : guardado;
  }

  void guardar(String servidor) => _almacen.guardar(clave, servidor.trim());
}

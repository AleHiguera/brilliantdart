import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:brilliant_mobile/almacen_archivo.dart';
import 'package:brilliant_mobile/almacen_pestana.dart';

/// Carpeta privada de la app en el teléfono, una vez preparada.
String? _carpeta;

/// Busca la carpeta de la app. Si no se puede (por ejemplo, en las pruebas),
/// lo duradero se queda en memoria.
Future<void> prepararAlmacen(String? carpeta) async {
  try {
    _carpeta = carpeta ?? (await getApplicationSupportDirectory()).path;
  } catch (_) {
    _carpeta = null;
  }
}

/// La sesión en el teléfono dura lo que la app abierta, como una pestaña.
AlmacenPestana crearAlmacen() => AlmacenEnMemoria();

AlmacenPestana crearAlmacenDuradero() {
  final carpeta = _carpeta;
  if (carpeta == null) return AlmacenEnMemoria();
  return AlmacenArchivo(
    File('$carpeta${Platform.pathSeparator}preferencias.json'),
  );
}

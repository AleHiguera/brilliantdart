import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/almacen_pestana.dart';

/// Guarda los textos en un archivo JSON del teléfono, así duran aunque se
/// cierre la app. Si el archivo no existe o está dañado, empieza vacío.
class AlmacenArchivo implements AlmacenPestana {
  AlmacenArchivo(this.archivo) : _valores = _cargar(archivo);

  final File archivo;
  final Map<String, String> _valores;

  static Map<String, String> _cargar(File archivo) {
    try {
      final datos = jsonDecode(archivo.readAsStringSync());
      if (datos is! Map) return {};
      return {
        for (final MapEntry(:key, :value) in datos.entries)
          if (key is String && value is String) key: value,
      };
    } catch (_) {
      return {};
    }
  }

  @override
  String? leer(String clave) => _valores[clave];

  @override
  void guardar(String clave, String valor) {
    _valores[clave] = valor;
    _escribir();
  }

  @override
  void borrar(String clave) {
    if (_valores.remove(clave) != null) _escribir();
  }

  void _escribir() {
    try {
      archivo.parent.createSync(recursive: true);
      archivo.writeAsStringSync(jsonEncode(_valores));
    } catch (_) {
      // Sin poder escribir, se recuerda solo mientras la app siga abierta.
    }
  }
}

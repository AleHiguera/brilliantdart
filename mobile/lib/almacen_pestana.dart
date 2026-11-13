import 'package:brilliant_mobile/almacen_pestana_nativo.dart'
    if (dart.library.js_interop) 'package:brilliant_mobile/almacen_pestana_web.dart'
    as plataforma;

/// Textos que sobreviven a recargar la página, pero solo en esta pestaña:
/// otra pestaña puede tener abierta otra cuenta. No sabe qué se guarda.
abstract interface class AlmacenPestana {
  /// En el navegador, el almacén de la pestaña; fuera de él, solo memoria.
  factory AlmacenPestana.deLaPestana() => plataforma.crearAlmacen();

  /// En el navegador, uno que dura aunque se cierre la pestaña y que comparten
  /// todas; en el teléfono, un archivo de la app. Para preferencias como el
  /// silencio o el servidor, no para la sesión.
  factory AlmacenPestana.duradero() => plataforma.crearAlmacenDuradero();

  /// Se llama una vez al abrir la app, antes de pedir el almacén duradero: en
  /// el teléfono busca la carpeta donde guardarlo. [carpeta] es para pruebas.
  static Future<void> preparar([String? carpeta]) =>
      plataforma.prepararAlmacen(carpeta);

  String? leer(String clave);
  void guardar(String clave, String valor);
  void borrar(String clave);
}

/// Se pierde al cerrar la app. Es el de las pruebas y el de fuera del navegador.
class AlmacenEnMemoria implements AlmacenPestana {
  final Map<String, String> _valores = {};

  /// Lo guardado, para revisarlo en las pruebas.
  Map<String, String> get valores => Map.unmodifiable(_valores);

  @override
  String? leer(String clave) => _valores[clave];

  @override
  void guardar(String clave, String valor) => _valores[clave] = valor;

  @override
  void borrar(String clave) => _valores.remove(clave);
}

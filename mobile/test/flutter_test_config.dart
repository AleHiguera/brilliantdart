// Se ejecuta antes de cada archivo de pruebas.

import 'dart:async';

import 'package:brilliant_mobile/npcs_menu.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Los personajitos del menú caminan sin parar: en las pruebas de las demás
  // pantallas se apagan para poder esperar a que todo quede quieto. Sus
  // propias pruebas los vuelven a encender.
  NpcsMenu.habilitados = false;
  await testMain();
}

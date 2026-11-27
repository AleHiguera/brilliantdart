// Se ejecuta antes de cada archivo de pruebas.

import 'dart:async';

import 'package:brilliant_mobile/decoraciones.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Los adornos animados (personajitos del menú, nieve) se mueven sin parar:
  // en las pruebas de las demás pantallas se apagan para poder esperar a que
  // todo quede quieto. Sus propias pruebas los vuelven a encender.
  Decoraciones.animadas = false;
  await testMain();
}

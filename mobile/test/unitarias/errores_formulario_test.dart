// Prueba unitaria: qué está mal en el inicio de sesión y en el registro, con
// un mensaje que dice el campo y el motivo.

import 'package:brilliant_mobile/errores_formulario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unitarias: errores del inicio de sesión', () {
    ErroresFormulario errores({
      String usuario = 'ana',
      String pin = '1234',
      String servidor = 'https://pc:8443',
    }) => erroresInicioSesion(usuario: usuario, pin: pin, servidor: servidor);

    test('Con todo bien no hay errores', () {
      expect(errores(), isEmpty);
    });

    test('Sin usuario se pide escribirlo', () {
      expect(errores(usuario: '   '), {'usuario': 'Escribe tu usuario.'});
    });

    test('El PIN debe tener 4 números', () {
      for (final pin in ['', '12', '12345', '12a4']) {
        expect(errores(pin: pin), {
          'pin': 'El PIN debe tener exactamente 4 números.',
        }, reason: pin);
      }
    });

    test('El servidor debe empezar con https://', () {
      expect(errores(servidor: 'http://pc:8443'), {
        'servidor': 'La dirección del servidor debe empezar con https://',
      });
    });

    test('Varios errores a la vez, en el orden de los campos', () {
      expect(errores(usuario: '', pin: '1', servidor: 'pc').keys, [
        'usuario',
        'pin',
        'servidor',
      ]);
    });
  });

  group('Unitarias: errores del registro', () {
    ErroresFormulario errores({
      String usuario = 'luis',
      String nombre = 'Luis Pérez',
      String correo = 'luis@correo.com',
      String pin = '4321',
      String? confirmacion,
    }) => erroresRegistro(
      usuario: usuario,
      nombre: nombre,
      correo: correo,
      pin: pin,
      confirmacion: confirmacion ?? pin,
    );

    test('Con todo bien no hay errores', () {
      expect(errores(), isEmpty);
    });

    test('El usuario debe empezar con una letra', () {
      expect(
        errores(usuario: '1luis')['usuario'],
        startsWith('El usuario debe empezar con una letra'),
      );
    });

    test('El nombre debe tener letras', () {
      expect(errores(nombre: '1234'), {
        'nombre': 'El nombre debe tener letras, no solo números o signos.',
      });
    });

    test('El nombre solo lleva un espacio entre palabras', () {
      expect(errores(nombre: 'Luis  Pérez'), {
        'nombre': 'El nombre solo puede llevar un espacio entre palabras.',
      });
    });

    test('El correo debe ser válido', () {
      expect(errores(correo: 'sin-arroba'), {
        'correo': 'El correo electrónico no es válido.',
      });
    });

    test('Los dos PIN deben coincidir', () {
      expect(errores(confirmacion: '0000'), {
        'confirmacion': 'Los PIN no coinciden: escribe el mismo PIN dos veces.',
      });
    });

    test('Cada mensaje dice de qué campo habla', () {
      final todos = errores(
        usuario: '1',
        nombre: '',
        correo: 'x',
        pin: '1',
        confirmacion: '2',
      );

      expect(todos.keys, [
        'usuario',
        'nombre',
        'correo',
        'pin',
        'confirmacion',
      ]);
      expect(todos['usuario'], contains('usuario'));
      expect(todos['nombre'], contains('nombre'));
      expect(todos['correo'], contains('correo'));
      expect(todos['pin'], contains('PIN'));
      expect(todos['confirmacion'], contains('PIN'));
    });
  });
}

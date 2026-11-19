import 'package:brilliant_mobile/registro.dart';

/// Lo que está mal en un formulario: campo → por qué, en el orden en que se
/// ven los campos. Vacío si se puede enviar.
typedef ErroresFormulario = Map<String, String>;

/// Antes de iniciar sesión: falta el usuario, el PIN no tiene 4 números o la
/// dirección del servidor no es segura.
ErroresFormulario erroresInicioSesion({
  required String usuario,
  required String pin,
  required String servidor,
}) => {
  if (usuario.trim().isEmpty) 'usuario': 'Escribe tu usuario.',
  'pin': ?validarPin(pin),
  if (!servidor.trim().startsWith('https://'))
    'servidor': 'La dirección del servidor debe empezar con https://',
};

/// Antes de crear la cuenta, con las mismas reglas que el servidor.
ErroresFormulario erroresRegistro({
  required String usuario,
  required String nombre,
  required String correo,
  required String pin,
  required String confirmacion,
}) => {
  'usuario': ?validarUsuario(usuario),
  'nombre': ?validarNombre(nombre),
  'correo': ?validarCorreo(correo),
  'pin': ?validarPin(pin),
  if (confirmacion != pin)
    'confirmacion': 'Los PIN no coinciden: escribe el mismo PIN dos veces.',
};

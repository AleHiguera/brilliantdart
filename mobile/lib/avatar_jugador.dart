import 'package:flutter/material.dart';

/// Las iniciales de un usuario para su avatar, en mayúsculas.
///
/// Si el usuario tiene partes separadas por «_», «.», «-» o espacios, se toma
/// la primera letra de las dos primeras («valentina_gm» → «VG»). Si es una
/// sola palabra, sus dos primeros caracteres («rorro» → «RO»). Sin nada que
/// usar, «?».
String inicialesDe(String usuario) {
  final partes = usuario
      .split(RegExp(r'[_.\-\s]+'))
      .where((parte) => parte.isNotEmpty)
      .toList();
  if (partes.isEmpty) return '?';
  final iniciales = partes.length == 1
      ? partes.first.substring(0, partes.first.length < 2 ? 1 : 2)
      : '${partes[0][0]}${partes[1][0]}';
  return iniciales.toUpperCase();
}

/// Los colores de los avatares: fuertes para que las letras blancas se lean.
const List<Color> coloresAvatar = [
  Color(0xFF5C6BC0),
  Color(0xFF00897B),
  Color(0xFFEF6C00),
  Color(0xFF8E24AA),
  Color(0xFF43A047),
  Color(0xFFD81B60),
  Color(0xFF1E88E5),
  Color(0xFF6D4C41),
];

/// El color del avatar de un usuario: siempre el mismo para el mismo usuario
/// (sin importar mayúsculas), en cualquier celular y cada vez que se abra.
Color colorDeUsuario(String usuario) {
  // FNV-1a de 32 bits: reparte bien los colores aunque los nombres se
  // parezcan, y da lo mismo en cualquier plataforma.
  var mezcla = 0x811c9dc5;
  for (final codigo in usuario.toLowerCase().codeUnits) {
    mezcla = ((mezcla ^ codigo) * 0x01000193) & 0xffffffff;
  }
  return coloresAvatar[mezcla % coloresAvatar.length];
}

/// Un círculo con las iniciales del usuario en su color.
class AvatarJugador extends StatelessWidget {
  const AvatarJugador({super.key, required this.usuario, this.tamano = 36});

  final String usuario;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final color = colorDeUsuario(usuario);
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.18)!, color],
        ),
      ),
      child: Text(
        inicialesDe(usuario),
        style: TextStyle(
          color: Colors.white,
          fontSize: tamano * 0.38,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

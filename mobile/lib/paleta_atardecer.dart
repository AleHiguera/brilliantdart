import 'package:flutter/material.dart';

/// Los colores de la app sobre el fondo de la casa del árbol: tonos cálidos de
/// atardecer (crema, durazno, salmón y terracota) en lugar de blanco y negro.
abstract final class PaletaAtardecer {
  /// Tarjetas: crema casi opaca, para que se lean bien pero sin el blanco duro.
  static const Color tarjeta = Color(0xEBFFF6EA);

  /// Lo más claro de una tarjeta destacada (arriba a la izquierda).
  static const Color cremaClaro = Color(0xF5FFFBF4);

  /// Lo más cálido de una tarjeta destacada (abajo a la derecha).
  static const Color durazno = Color(0xEBFFE9D4);

  /// Bordes suaves de las tarjetas.
  static const Color borde = Color(0xFFF0D2B4);

  /// Terracota: flechas y detalles que antes eran negros.
  static const Color terracota = Color(0xFFB4532A);

  /// Terracota más clara, para el brillo de los botones redondos.
  static const Color terracotaClara = Color(0xFFE07A4F);

  /// La sombra cálida bajo las tarjetas.
  static const Color sombra = Color(0x2EB4532A);

  /// La barra de arriba: del durazno al salmón, como el cielo del dibujo.
  static const LinearGradient barra = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xF2FFE4CC), Color(0xF2FFD2C4)],
  );

  /// La línea bajo la barra de arriba.
  static const Color lineaBarra = Color(0x80E0A27E);

  /// El degradado de una tarjeta destacada (como las de los mapas).
  static const LinearGradient tarjetaDestacada = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cremaClaro, durazno],
  );

  /// El brillo de los botones redondos de terracota.
  static const LinearGradient botonRedondo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [terracotaClara, terracota],
  );
}

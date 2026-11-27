import 'package:flutter/material.dart';
import 'package:brilliant_mobile/paleta_atardecer.dart';

/// La imagen de fondo de toda la app: la casa del árbol al atardecer.
const String imagenFondo = 'assets/imagenes/fondo_casa_arbol.jpg';

/// El fondo de las barras de arriba: el degradado de atardecer con una línea
/// suave debajo. Va en `flexibleSpace` con la barra transparente.
class FondoBarra extends StatelessWidget {
  const FondoBarra({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      key: Key('fondo-barra'),
      decoration: BoxDecoration(
        gradient: PaletaAtardecer.barra,
        border: Border(bottom: BorderSide(color: PaletaAtardecer.lineaBarra)),
      ),
    );
  }
}

/// El relleno de los campos de texto: blancos para leerse sobre el dibujo.
final Color rellenoCampo = Colors.white.withValues(alpha: 0.94);

/// Una pastilla blanca detrás de textos sueltos que van sobre el fondo.
BoxDecoration decoracionPastilla() => BoxDecoration(
  color: Colors.white.withValues(alpha: 0.88),
  borderRadius: BorderRadius.circular(20),
);

/// Un velo claro sobre la imagen para que los textos y tarjetas se lean bien
/// encima de ella sin tapar el dibujo. Más claro arriba, donde suele haber
/// texto, y más transparente abajo, donde se ve la colina.
const LinearGradient veloFondo = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x8CFFFFFF), Color(0x59FFFFFF)],
);

/// Pone la imagen de fondo detrás de [child], quieta aunque la pantalla se
/// desplace, cubriendo todo sin deformarse. Las pantallas encima deben tener
/// el fondo transparente para que se vea.
class FondoApp extends StatelessWidget {
  const FondoApp({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Image(
          key: Key('fondo-imagen'),
          image: AssetImage(imagenFondo),
          fit: BoxFit.cover,
          // La casa está a la derecha: en un celular vertical se centra en
          // ella en vez de cortarla.
          alignment: Alignment(0.35, 0),
          // Mientras carga, el color del cielo en lugar de blanco.
          frameBuilder: _conColorMientrasCarga,
        ),
        const DecoratedBox(
          key: Key('fondo-velo'),
          decoration: BoxDecoration(gradient: veloFondo),
        ),
        child,
      ],
    );
  }

  static Widget _conColorMientrasCarga(
    BuildContext context,
    Widget imagen,
    int? cuadro,
    bool yaEstaba,
  ) => ColoredBox(color: const Color(0xFFF7B98A), child: imagen);
}

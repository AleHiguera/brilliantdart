import 'package:flutter/material.dart';
import 'package:brilliant_mobile/paleta_atardecer.dart';
import 'package:brilliant_mobile/tema_mapa.dart';

/// La imagen de fondo de toda la app: la casa del árbol al atardecer.
const String imagenFondo = 'assets/imagenes/fondo_casa_arbol.jpg';

/// El fondo de las barras de arriba: el degradado de atardecer con una línea
/// suave debajo. Va en `flexibleSpace` con la barra transparente.
class FondoBarra extends StatelessWidget {
  const FondoBarra({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = TemaMapa.maybeOf(context);
    return DecoratedBox(
      key: const Key('fondo-barra'),
      decoration: BoxDecoration(
        gradient: tema?.barra ?? PaletaAtardecer.barra,
        border: Border(
          bottom: BorderSide(
            color: tema?.lineaBarra ?? PaletaAtardecer.lineaBarra,
          ),
        ),
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
  const FondoApp({
    super.key,
    required this.child,
    this.imagen = imagenFondo,
    this.velo = veloFondo,
    this.alineacion = const Alignment(0.35, 0),
    this.colorMientrasCarga = const Color(0xFFF7B98A),
  });

  /// Lo que se ve mientras carga la imagen (el color de su cielo).
  final Color colorMientrasCarga;

  final Widget child;

  /// La imagen; la casa del árbol si no se indica otra.
  final String imagen;
  final LinearGradient velo;

  /// Qué parte de la imagen queda a la vista en un celular vertical.
  final Alignment alineacion;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image(
          key: const Key('fondo-imagen'),
          image: AssetImage(imagen),
          fit: BoxFit.cover,
          // La casa está a la derecha: en un celular vertical se centra en
          // ella en vez de cortarla.
          alignment: alineacion,
          // Mientras carga, el color del cielo en lugar de blanco.
          frameBuilder: (context, imagen, cuadro, yaEstaba) =>
              ColoredBox(color: colorMientrasCarga, child: imagen),
        ),
        DecoratedBox(
          key: const Key('fondo-velo'),
          decoration: BoxDecoration(gradient: velo),
        ),
        child,
      ],
    );
  }
}

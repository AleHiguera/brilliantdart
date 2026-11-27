import 'package:flutter/material.dart';
import 'package:brilliant_mobile/fondo_app.dart';
import 'package:brilliant_mobile/nieve_cayendo.dart';
import 'package:brilliant_mobile/tema_mapa.dart';

/// Viste una pantalla de mapa con su temática: le pasa el tema a todo lo de
/// adentro (tarjetas, barra, copo de los números iniciales) y, si el mapa
/// tiene fondo propio, lo pone detrás con su nieve.
class PantallaConTema extends StatelessWidget {
  const PantallaConTema({super.key, required this.tema, required this.child});

  final TemaMapa tema;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final imagen = tema.imagenFondo;
    return AlcanceTemaMapa(
      tema: tema,
      child: imagen == null
          ? child
          : FondoApp(
              key: const Key('fondo-mapa'),
              imagen: imagen,
              velo: tema.veloFondo ?? veloFondo,
              alineacion: Alignment.center,
              colorMientrasCarga: tema.colorCielo,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (tema.nieve) const Positioned.fill(child: NieveCayendo()),
                  child,
                ],
              ),
            ),
    );
  }
}

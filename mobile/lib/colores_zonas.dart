import 'package:flutter/material.dart';
import 'package:brilliantdart/tipoo.dart';

const Map<TipoZona, Color> coloresZonas = {
  TipoZona.azul: Color(0xFF2196F3),
  TipoZona.rojo: Color(0xFFF44336),
  TipoZona.verde: Color(0xFF4CAF50),
  TipoZona.amarillo: Color(0xFFFFEB3B),
  TipoZona.morado: Color(0xFF9C27B0),
};

/// Fondo de las tarjetas, el mismo que las opciones de mapa.
const Color colorTarjeta = Color(0xFFF4F4F0);
const Color colorBordeTarjeta = Color(0xFFE2E2DC);

BoxDecoration decoracionTarjeta() => BoxDecoration(
      color: colorTarjeta,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: colorBordeTarjeta),
    );

/// Encabezado común de las tarjetas: icono, título y algo a la derecha.
class EncabezadoTarjeta extends StatelessWidget {
  const EncabezadoTarjeta({
    super.key,
    required this.icono,
    required this.titulo,
    this.extremo,
  });

  final IconData icono;
  final String titulo;
  final Widget? extremo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 16, color: Colors.black87),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            titulo,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        if (extremo != null) ...[
          const SizedBox(width: 6),
          extremo!,
        ],
      ],
    );
  }
}

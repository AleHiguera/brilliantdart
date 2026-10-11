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

/// Botón negro principal (Comenzar, Lanzar dados, Confirmar...).
ButtonStyle estiloBotonPrincipal() => FilledButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      disabledBackgroundColor: colorBordeTarjeta,
      disabledForegroundColor: Colors.black38,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );

ButtonStyle estiloBotonElevadoPrincipal() => ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      disabledBackgroundColor: colorBordeTarjeta,
      disabledForegroundColor: Colors.black38,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    );

/// Aviso corto con icono, para pistas y advertencias durante el turno.
class AvisoJuego extends StatelessWidget {
  const AvisoJuego({
    super.key,
    required this.icono,
    required this.texto,
    this.advertencia = false,
  });

  final IconData icono;
  final String texto;
  final bool advertencia;

  @override
  Widget build(BuildContext context) {
    final color = advertencia ? const Color(0xFFB3261E) : Colors.black87;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: advertencia ? const Color(0xFFFDE3E1) : colorTarjeta,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: advertencia ? const Color(0xFFF5B7B1) : colorBordeTarjeta,
        ),
      ),
      child: Row(
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:brilliant_mobile/datos_salon_fama.dart';
import 'package:brilliant_mobile/fila_salon_fama.dart';
import 'package:brilliant_mobile/fondo_app.dart';
import 'package:brilliant_mobile/podio_salon_fama.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_salon_fama.dart';

/// Color del escenario oscuro de arriba (la barra y la cabecera).
const Color colorEscenario = Color(0xFF1E1A14);

/// El Salón de la Fama: el ranking global por ELO. Arriba, un escenario oscuro
/// con el podio de los tres primeros; debajo, del 4.º al 10.º y, si quedé
/// fuera del Top 10, «...» y mi puesto. Se vuelve a pedir solo cada
/// [cadaCuanto] mientras está abierto, y también al deslizar hacia abajo.
class PantallaSalonFama extends StatefulWidget {
  const PantallaSalonFama({
    super.key,
    required this.servicio,
    required this.usuario,
    this.cadaCuanto = const Duration(seconds: 15),
  });

  final ServicioSalonFama servicio;
  final String? usuario;
  final Duration cadaCuanto;

  @override
  State<PantallaSalonFama> createState() => _PantallaSalonFamaState();
}

class _PantallaSalonFamaState extends State<PantallaSalonFama> {
  SalonFama? _salon;
  String? _error;
  Timer? _reloj;
  bool _pidiendo = false;

  @override
  void initState() {
    super.initState();
    _cargar();
    _reloj = Timer.periodic(widget.cadaCuanto, (_) => _cargar());
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (_pidiendo) return;
    _pidiendo = true;
    try {
      final salon = await widget.servicio.consultar();
      if (!mounted) return;
      setState(() {
        _salon = salon;
        _error = null;
      });
    } on ErrorAuth catch (error) {
      // Si ya se veía el ranking se deja a la vista; se reintenta solo.
      if (!mounted) return;
      setState(() => _error = error.mensaje);
    } finally {
      _pidiendo = false;
    }
  }

  bool _esMio(PuestoSalon puesto) =>
      puesto.usuario.toLowerCase() == widget.usuario?.toLowerCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Salón de la Fama',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: colorEscenario,
        foregroundColor: Colors.white,
        surfaceTintColor: colorEscenario,
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        color: Medalla.oro.texto,
        child: ListView(
          key: const Key('salon-lista'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _Escenario(
              jugadores: _salon?.jugadores,
              podio: switch (_salon) {
                final salon? when salon.top.isNotEmpty => PodioSalonFama(
                  puestos: salon.top,
                  usuario: widget.usuario,
                ),
                _ => null,
              },
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _debajoDelPodio(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _debajoDelPodio() {
    final salon = _salon;
    if (salon == null) {
      return [
        const SizedBox(height: 24),
        if (_error case final error?)
          _Aviso(mensaje: error, onReintentar: _cargar)
        else
          const Center(
            child: CircularProgressIndicator(key: Key('salon-cargando')),
          ),
      ];
    }
    final resto = salon.top.skip(3).toList();
    return [
      if (_error case final error?) ...[
        const SizedBox(height: 12),
        _Aviso(mensaje: error, onReintentar: _cargar),
      ],
      if (salon.top.isEmpty)
        const Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Todavía no hay jugadores en el ranking.',
            key: Key('salon-vacio'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      const SizedBox(height: 6),
      for (final (indice, puesto) in resto.indexed)
        _Entrada(
          indice: indice,
          child: FilaSalonFama(
            key: Key('salon-puesto-${puesto.usuario}'),
            puesto: puesto,
            soyYo: _esMio(puesto),
          ),
        ),
      if (salon.yo case final yo?) ...[
        const SeparadorSalonFama(),
        const EtiquetaMiPosicion(),
        _Entrada(
          indice: resto.length,
          child: FilaSalonFama(
            key: const Key('salon-yo'),
            puesto: yo,
            soyYo: true,
          ),
        ),
      ],
      const SizedBox(height: 20),
      Center(
        child: Container(
          key: const Key('salon-nota'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: decoracionPastilla(),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.autorenew, size: 14, color: Colors.black54),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Se actualiza solo. Desliza hacia abajo para actualizar ahora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}

/// La parte oscura de arriba: el título, cuántos jugadores hay y el podio.
class _Escenario extends StatelessWidget {
  const _Escenario({required this.jugadores, required this.podio});

  final int? jugadores;
  final Widget? podio;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colorEscenario, Color(0xFF3A2E14)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              const Text(
                'LOS 10 MEJORES POR ELO',
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 12,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              if (jugadores case final jugadores?)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    jugadores == 1
                        ? '1 jugador en el ranking'
                        : '$jugadores jugadores en el ranking',
                    key: const Key('salon-jugadores'),
                    style: const TextStyle(
                      color: Color(0xFFF3E3B0),
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(height: podio == null ? 20 : 12),
              if (podio != null) ...[
                podio!,
                // La base sobre la que se paran los escalones.
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        Medalla.oro.fuerte.withValues(alpha: 0.15),
                        Medalla.oro.fuerte.withValues(alpha: 0.6),
                        Medalla.oro.fuerte.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Hace aparecer cada fila deslizándose un poco, una tras otra.
class _Entrada extends StatelessWidget {
  const _Entrada({required this.indice, required this.child});

  final int indice;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + indice * 45),
      curve: Curves.easeOutCubic,
      builder: (context, valor, hijo) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, (1 - valor) * 14),
          child: hijo,
        ),
      ),
      child: child,
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final Future<void> Function() onReintentar;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('salon-error'),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2B8B5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB3261E)),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje, style: const TextStyle(fontSize: 13))),
          TextButton(
            key: const Key('salon-reintentar'),
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

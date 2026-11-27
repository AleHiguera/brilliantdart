import 'package:flutter/material.dart';
import 'package:brilliant_mobile/colores_zonas.dart' as estilo;
import 'package:brilliant_mobile/pantalla_salon_fama.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_salon_fama.dart';

/// Apartado del menú principal que lleva al Salón de la Fama.
class SeccionSalonFama extends StatelessWidget {
  const SeccionSalonFama({super.key, required this.auth});

  final ServicioAuth auth;

  void _abrir(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PantallaSalonFama(
          servicio: ServicioSalonFama(auth),
          usuario: auth.sesion?.usuario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('salon-fama'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: estilo.decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const estilo.EncabezadoTarjeta(
            icono: Icons.emoji_events_outlined,
            titulo: 'Salón de la Fama',
          ),
          const SizedBox(height: 6),
          const Text(
            'Los 10 jugadores con más ELO y tu lugar en el ranking.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('menu-salon-fama'),
            icon: const Icon(Icons.leaderboard_outlined),
            label: const Text('Ver el Salón de la Fama'),
            onPressed: () => _abrir(context),
          ),
        ],
      ),
    );
  }
}

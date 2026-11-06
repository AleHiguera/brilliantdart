import 'package:flutter/material.dart';
import 'package:brilliant_mobile/colores_zonas.dart' as estilo;
import 'package:brilliant_mobile/crear_partida.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:brilliant_mobile/unirse_partida.dart';

/// Apartado del menú principal con las dos formas de empezar una partida
/// multijugador.
class SeccionMultijugador extends StatelessWidget {
  const SeccionMultijugador({super.key, required this.auth});

  final ServicioAuth auth;

  void _abrir(BuildContext context, Widget pagina) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina));
  }

  @override
  Widget build(BuildContext context) {
    final partidas = ServicioPartidas(auth);

    return Container(
      key: const Key('multijugador'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: estilo.decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const estilo.EncabezadoTarjeta(
            icono: Icons.groups_outlined,
            titulo: 'Multijugador',
          ),
          const SizedBox(height: 6),
          const Text(
            'Juega de 2 a 6 personas con el mismo mapa y los mismos dados.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('multijugador-crear'),
            icon: const Icon(Icons.add),
            label: const Text('Crear partida'),
            onPressed: () =>
                _abrir(context, CrearPartidaPage(partidas: partidas)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('multijugador-unirse'),
            icon: const Icon(Icons.login),
            label: const Text('Unirse a una partida'),
            onPressed: () =>
                _abrir(context, UnirsePartidaPage(partidas: partidas)),
          ),
        ],
      ),
    );
  }
}

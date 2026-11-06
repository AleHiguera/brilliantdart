import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliant_mobile/colores_zonas.dart' as estilo;
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:brilliant_mobile/vista_mapa.dart';

class TarjetaCodigo extends StatelessWidget {
  const TarjetaCodigo({super.key, required this.codigo});

  final String codigo;

  Future<void> _copiar(BuildContext context) async {
    final mensajes = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: codigo));
    mensajes.showSnackBar(const SnackBar(content: Text('Código copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: estilo.decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const estilo.EncabezadoTarjeta(
            icono: Icons.key_outlined,
            titulo: 'Código de acceso',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  codigo,
                  key: const Key('sala-codigo'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
              IconButton(
                key: const Key('sala-copiar'),
                tooltip: 'Copiar código',
                icon: const Icon(Icons.copy),
                onPressed: () => _copiar(context),
              ),
            ],
          ),
          const Text(
            'Compártelo con los demás jugadores.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class TarjetaMapa extends StatelessWidget {
  const TarjetaMapa({super.key, required this.mapa});

  final Mapa mapa;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: estilo.decoracionTarjeta(),
      child: Row(
        children: [
          SizedBox(width: 56, height: 56, child: VistaPreviaMapa(mapa: mapa)),
          const SizedBox(width: 12),
          Text(
            'Mapa ${mapa.numero}',
            key: const Key('sala-mapa'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class TarjetaJugadores extends StatelessWidget {
  const TarjetaJugadores({
    super.key,
    required this.sala,
    required this.usuario,
  });

  final SalaPartida sala;
  final String? usuario;

  @override
  Widget build(BuildContext context) {
    final ocupados = sala.jugadores.length;

    return Container(
      key: const Key('sala-jugadores'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: estilo.decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const estilo.EncabezadoTarjeta(
            icono: Icons.groups_outlined,
            titulo: 'Jugadores',
          ),
          const SizedBox(height: 4),
          Text(
            '$ocupados de ${sala.capacidad} espacios ocupados',
            key: const Key('sala-ocupados'),
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          for (final jugador in sala.jugadores)
            _FilaJugador(
              key: Key('sala-jugador-$jugador'),
              usuario: jugador,
              esAnfitrion: jugador == sala.anfitrion,
              soyYo: jugador == usuario,
            ),
          for (var i = ocupados; i < sala.capacidad; i++)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: Colors.black38),
                  SizedBox(width: 10),
                  Text(
                    'Espacio libre',
                    style: TextStyle(color: Colors.black45),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaJugador extends StatelessWidget {
  const _FilaJugador({
    super.key,
    required this.usuario,
    required this.esAnfitrion,
    required this.soyYo,
  });

  final String usuario;
  final bool esAnfitrion;
  final bool soyYo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.person, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              soyYo ? '@$usuario (tú)' : '@$usuario',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (esAnfitrion)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F4E3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Anfitrión',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E6B23),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

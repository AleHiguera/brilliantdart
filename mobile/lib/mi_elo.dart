import 'package:flutter/material.dart';
import 'package:brilliant_mobile/etiqueta_elo.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';

/// Tu ELO en el menú. Al aparecer lo pide al servidor, y cambia solo cuando
/// termina una partida. Mientras no se sabe, no se enseña nada.
class MiElo extends StatefulWidget {
  const MiElo({super.key, required this.auth});

  final ServicioAuth auth;

  @override
  State<MiElo> createState() => _MiEloState();
}

class _MiEloState extends State<MiElo> {
  @override
  void initState() {
    super.initState();
    ServicioPartidas(widget.auth).actualizarMiElo();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: widget.auth.elo,
      builder: (context, elo, _) => elo == null
          ? const SizedBox.shrink()
          : EtiquetaElo(key: const Key('mi-elo'), elo: elo, tamanoLetra: 12),
    );
  }
}

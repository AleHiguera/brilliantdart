import 'package:flutter/material.dart';
import 'package:brilliantdart/catalogo_mapas.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliant_mobile/colores_zonas.dart' as estilo;
import 'package:brilliant_mobile/formulario_partida.dart';
import 'package:brilliant_mobile/sala_partida.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/servicio_partidas.dart';
import 'package:brilliant_mobile/vista_mapa.dart';

/// Elige el mapa y la cantidad de jugadores; al crearla se entra a su sala
/// como anfitrión.
class CrearPartidaPage extends StatefulWidget {
  const CrearPartidaPage({super.key, required this.partidas});

  final ServicioPartidas partidas;

  @override
  State<CrearPartidaPage> createState() => _CrearPartidaPageState();
}

class _CrearPartidaPageState extends State<CrearPartidaPage> {
  Mapa _mapa = mapaUno;
  int _jugadores = ServicioPartidas.minimoJugadores;
  bool _enviando = false;
  String? _error;

  Future<void> _crear() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final sala = await widget.partidas.crear(
        mapa: _mapa.numero,
        jugadores: _jugadores,
      );
      if (!mounted) return;
      SalaPartidaPage.abrir(context, widget.partidas, sala);
    } on ErrorAuth catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: barraPartida('Crear partida'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text('Mapa', style: titulo),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final mapa in mapasDisponibles) ...[
                      if (mapa != mapasDisponibles.first)
                        const SizedBox(width: 8),
                      Expanded(
                        child: _EleccionMapa(
                          mapa: mapa,
                          elegido: mapa == _mapa,
                          onTap: _enviando
                              ? null
                              : () => setState(() => _mapa = mapa),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Text('Cantidad de jugadores', style: titulo),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (
                      var cantidad = ServicioPartidas.minimoJugadores;
                      cantidad <= ServicioPartidas.maximoJugadores;
                      cantidad++
                    )
                      ChoiceChip(
                        key: Key('crear-jugadores-$cantidad'),
                        label: Text('$cantidad'),
                        selected: cantidad == _jugadores,
                        onSelected: _enviando
                            ? null
                            : (_) => setState(() => _jugadores = cantidad),
                      ),
                  ],
                ),
                if (_error != null) ErrorPartida(_error!),
                const SizedBox(height: 24),
                BotonEnviarPartida(
                  key: const Key('crear-enviar'),
                  texto: 'Crear partida',
                  enviando: _enviando,
                  onPressed: _crear,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EleccionMapa extends StatelessWidget {
  const _EleccionMapa({
    required this.mapa,
    required this.elegido,
    required this.onTap,
  });

  final Mapa mapa;
  final bool elegido;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      label: 'Mapa ${mapa.numero}',
      child: InkWell(
        key: Key('crear-mapa-${mapa.numero}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: elegido ? Colors.black : estilo.colorBordeTarjeta,
              width: elegido ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: IgnorePointer(child: VistaPreviaMapa(mapa: mapa)),
              ),
              const SizedBox(height: 4),
              Text(
                'Mapa ${mapa.numero}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: elegido ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

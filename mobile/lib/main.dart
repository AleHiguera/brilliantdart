import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/dados.dart';
import 'package:brilliantdart/leyenda_reglas.dart';
import 'package:brilliantdart/mapa.dart';
import 'package:brilliantdart/mapa_cuatro.dart';
import 'package:brilliantdart/mapa_dos.dart';
import 'package:brilliantdart/mapa_tres.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/nombres_zonas.dart';
import 'package:brilliantdart/puntuacion_multijugador.dart';
import 'package:brilliantdart/registro_zonas.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/almacen_pestana.dart';
import 'package:brilliant_mobile/colores_zonas.dart' as estilo;
import 'package:brilliant_mobile/dados_compartidos.dart';
import 'package:brilliant_mobile/historial_dados_view.dart';
import 'package:brilliant_mobile/inicio_sesion.dart';
import 'package:brilliant_mobile/latido_sesion.dart';
import 'package:brilliant_mobile/novedades_zonas.dart';
import 'package:brilliant_mobile/panel_fin_compartido.dart';
import 'package:brilliant_mobile/panel_lanzamiento_dados.dart';
import 'package:brilliant_mobile/panel_reglas.dart';
import 'package:brilliant_mobile/panel_registro_zonas.dart';
import 'package:brilliant_mobile/panel_tablero_compartido.dart';
import 'package:brilliant_mobile/paneles_juego.dart';
import 'package:brilliant_mobile/partida_compartida.dart';
import 'package:brilliant_mobile/reanudar_partida.dart';
import 'package:brilliant_mobile/seccion_multijugador.dart';
import 'package:brilliant_mobile/servicio_auth.dart';
import 'package:brilliant_mobile/sonidos.dart';
import 'package:brilliant_mobile/tabla_puntos_partida.dart';
import 'package:brilliant_mobile/tabla_puntuacion.dart';
import 'package:brilliant_mobile/vista_mapa.dart';

void main() {
  runApp(
    BrilliantApp(auth: ServicioAuth(almacen: AlmacenPestana.deLaPestana())),
  );
}

class BrilliantApp extends StatelessWidget {
  const BrilliantApp({super.key, this.auth});

  /// Con [auth] hay que iniciar sesión en el servidor antes de jugar; sin él
  /// (como en las pruebas) se entra directo a elegir el mapa.
  final ServicioAuth? auth;

  @override
  Widget build(BuildContext context) {
    final auth = this.auth;
    final app = MaterialApp(
      title: 'Brilliant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: switch (auth) {
        null => const SeleccionMapaPage(),
        // Se recargó la página con la sesión abierta: se sigue donde iba.
        ServicioAuth(sesion: _?) => _mapasConSesion(
          auth,
          primerLatido: Duration.zero,
        ),
        _ => InicioSesionPage(
          auth: auth,
          siguiente: (_) => _mapasConSesion(auth),
        ),
      },
    );
    return auth == null ? app : ProveedorAuth(auth: auth, child: app);
  }
}

Widget _mapasConSesion(
  ServicioAuth auth, {
  Duration primerLatido = LatidoSesion.intervalo,
}) => LatidoSesion(
  auth: auth,
  primerLatido: primerLatido,
  alPerderSesion: (context) => _volverAlInicio(
    Navigator.of(context),
    auth,
    aviso: 'Tu sesión ya no está activa, inicia sesión de nuevo.',
  ),
  alDesconectarse: (context, desconexion) =>
      _volverAlInicio(Navigator.of(context), auth, aviso: desconexion.mensaje),
  child: ReanudarPartida(auth: auth, child: const SeleccionMapaPage()),
);

void _volverAlInicio(
  NavigatorState navegador,
  ServicioAuth auth, {
  String? aviso,
}) {
  navegador.pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => InicioSesionPage(
        auth: auth,
        siguiente: (_) => _mapasConSesion(auth),
        aviso: aviso,
      ),
    ),
    (_) => false,
  );
}

class SeleccionMapaPage extends StatelessWidget {
  const SeleccionMapaPage({super.key});

  void _abrirMapa(BuildContext context, Mapa mapa) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TableroPage(mapa: mapa)));
  }

  Future<void> _cerrarSesion(BuildContext context, ServicioAuth auth) async {
    final navegador = Navigator.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: Text(
          '¿Quieres cerrar la sesión de ${auth.sesion?.nombre ?? 'tu cuenta'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('logout-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    await auth.cerrarSesion();
    _volverAlInicio(navegador, auth);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ProveedorAuth.maybeOf(context);
    final sesion = auth?.sesion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brilliant'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (auth != null && sesion != null)
            TextButton.icon(
              key: const Key('logout-button'),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              icon: const Icon(Icons.logout),
              label: const Text('Salir'),
              onPressed: () => _cerrarSesion(context, auth),
            ),
        ],
        bottom: auth != null && sesion != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Jugando como ${sesion.nombre} (@${sesion.usuario})',
                    key: const Key('sesion-actual'),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                const _Aparecer(indice: 0, child: _CabeceraSeleccion()),
                const SizedBox(height: 20),
                _Aparecer(
                  indice: 1,
                  child: _OpcionMapa(
                    key: const Key('map-option-1'),
                    numero: 1,
                    mapa: mapaUno,
                    onTap: () => _abrirMapa(context, mapaUno),
                  ),
                ),
                const SizedBox(height: 12),
                _Aparecer(
                  indice: 2,
                  child: _OpcionMapa(
                    key: const Key('map-option-2'),
                    numero: 2,
                    mapa: mapaDos,
                    onTap: () => _abrirMapa(context, mapaDos),
                  ),
                ),
                const SizedBox(height: 12),
                _Aparecer(
                  indice: 3,
                  child: _OpcionMapa(
                    key: const Key('map-option-3'),
                    numero: 3,
                    mapa: mapaTres,
                    onTap: () => _abrirMapa(context, mapaTres),
                  ),
                ),
                const SizedBox(height: 12),
                _Aparecer(
                  indice: 4,
                  child: _OpcionMapa(
                    key: const Key('map-option-4'),
                    numero: 4,
                    mapa: mapaCuatro,
                    onTap: () => _abrirMapa(context, mapaCuatro),
                  ),
                ),
                if (auth != null) ...[
                  const SizedBox(height: 24),
                  _Aparecer(indice: 5, child: SeccionMultijugador(auth: auth)),
                ],
                const SizedBox(height: 24),
                const _Aparecer(indice: 6, child: _ComoSeJuega()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hace aparecer cada bloque deslizándose un poco, uno tras otro.
class _Aparecer extends StatelessWidget {
  const _Aparecer({required this.indice, required this.child});

  final int indice;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + indice * 110),
      curve: Curves.easeOutCubic,
      builder: (context, avance, hijo) => Opacity(
        opacity: avance,
        child: Transform.translate(
          offset: Offset(0, (1 - avance) * 18),
          child: hijo,
        ),
      ),
      child: child,
    );
  }
}

class _CabeceraSeleccion extends StatelessWidget {
  const _CabeceraSeleccion();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final color in estilo.coloresZonas.values)
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black26, width: 0.5),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Elige tu mapa',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecciona un mapa para preparar la partida.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _OpcionMapa extends StatelessWidget {
  const _OpcionMapa({super.key, required this.numero, this.mapa, this.onTap});

  final int numero;

  /// El mapa que abre esta opción; sin mapa, la opción está bloqueada.
  final Mapa? mapa;
  final VoidCallback? onTap;

  bool get disponible => mapa != null;

  @override
  Widget build(BuildContext context) {
    final foreground = disponible ? Colors.black : Colors.black45;

    return Semantics(
      button: disponible,
      enabled: disponible,
      label: disponible
          ? 'Mapa $numero, disponible'
          : 'Mapa $numero, bloqueado',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: disponible ? Colors.black : estilo.colorBordeTarjeta,
            width: disponible ? 1.5 : 1,
          ),
          boxShadow: disponible
              ? const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: disponible ? Colors.white : const Color(0xFFF2F2EF),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: Key('map-choice-$numero'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: disponible
                        ? VistaPreviaMapa(mapa: mapa!)
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4E4E0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.lock_outline,
                              size: 28,
                              color: Colors.black45,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mapa $numero',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: disponible
                                ? const Color(0xFFE2F4E3)
                                : estilo.colorBordeTarjeta,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            disponible ? 'Disponible' : 'Próximamente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: disponible
                                  ? const Color(0xFF1E6B23)
                                  : Colors.black54,
                            ),
                          ),
                        ),
                        if (!disponible) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Muy pronto podrás jugarlo.',
                            style: TextStyle(fontSize: 12, color: foreground),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: disponible ? Colors.black : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      disponible ? Icons.arrow_forward : Icons.lock_outline,
                      color: disponible ? Colors.white : foreground,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComoSeJuega extends StatelessWidget {
  const _ComoSeJuega();

  static const List<(IconData, String)> _pasos = [
    (Icons.grid_on, 'Coloca los números del 1 al 6 en las celdas iniciales.'),
    (
      Icons.casino_outlined,
      'Lanza los dados: uno es el ancla y el otro se coloca a su lado.',
    ),
    (
      Icons.emoji_events_outlined,
      'Completa zonas respetando su regla para sumar puntos.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('how-to-play'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: estilo.decoracionTarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const estilo.EncabezadoTarjeta(
            icono: Icons.lightbulb_outline,
            titulo: 'Cómo se juega',
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _pasos.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_pasos[i].$1, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        _pasos[i].$2,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class TableroPage extends StatefulWidget {
  const TableroPage({
    super.key,
    this.dados,
    this.tablero,
    this.sonidoVictoria,
    this.sonidoDados,
    this.sonidoAplausos,
    this.sonidoTristeza,
    this.mapa = mapaUno,
    this.compartida,
  });

  /// El mapa que se juega; el Mapa 1 si no se indica otro.
  final Mapa mapa;

  /// Solo en multijugador: los dados los lanza el servidor para toda la partida
  /// y empiezan cuando todos terminan su tablero. La pantalla se queda con él y
  /// lo libera al cerrarse.
  final PartidaCompartida? compartida;
  final Dados? dados;
  final Tablero? tablero;
  final Sonido? sonidoVictoria;
  final Sonido? sonidoDados;

  /// Suena cuando el jugador completa una zona.
  final Sonido? sonidoAplausos;

  /// Suena cuando otro jugador completa una zona antes que este.
  final Sonido? sonidoTristeza;

  static const int tamano = 7;

  static const Map<TipoZona, Color> coloresZonas = estilo.coloresZonas;

  static Color colorEn(int fila, int columna, {Mapa mapa = mapaUno}) =>
      coloresZonas[mapa.tipoEn(fila, columna)]!;

  @override
  State<TableroPage> createState() => _TableroPageState();
}

class _TableroPageState extends State<TableroPage> {
  late final Dados _dados =
      widget.dados ??
      switch (widget.compartida) {
        final compartida? => DadosCompartidos(() => compartida.resultado),
        null => Dados(),
      };
  late final Tablero _tablero = widget.tablero ?? widget.mapa.crearTablero();
  late final Sonido _sonidoVictoria =
      widget.sonidoVictoria ?? SonidoAsset(Sonido.victoria);
  late final Sonido _sonidoDados =
      widget.sonidoDados ?? SonidoAsset(Sonido.dados);
  late final Sonido _sonidoAplausos =
      widget.sonidoAplausos ?? SonidoAsset(Sonido.aplausos);
  late final Sonido _sonidoTristeza =
      widget.sonidoTristeza ?? SonidoAsset(Sonido.tristeza);
  late final NombresZonas _nombresZonas = NombresZonas(widget.mapa);
  StreamSubscription<List<ZonaAjena>>? _zonasAjenas;
  late final BlocValoresIniciales _bloc = BlocValoresIniciales(
    _tablero,
    celdasIniciales: widget.mapa.celdasIniciales,
  );
  late final ValidadorAnclas _validadorAnclas = ValidadorAnclas(_tablero);

  /// Las reglas del mapa no cambian durante la partida: se calculan una vez.
  late final List<ReglaVisible> _reglas = LeyendaReglas(widget.mapa).reglas;
  OpcionAncla? _opcionAnclaSeleccionada;
  MovimientoAncla? _movimientoSeleccionado;
  int? _numeroLanzamientoPendiente;
  int _rondaDados = 0;

  /// Ya se celebró el fin de la partida compartida; evita repetir el sonido.
  bool _finAnunciado = false;

  bool get _partidaFinalizada => _bloc.jugando && _tablero.estaLleno;

  /// Los puntos que ve el jugador: en multijugador dependen de su lugar en cada
  /// zona; en una partida individual, de las zonas que completó.
  int get _misPuntos {
    final compartida = widget.compartida;
    if (compartida == null) return _tablero.puntuacionTotal;
    return PuntuacionMultijugador(
          widget.mapa,
          compartida.rondasPorZona,
        ).puntos[compartida.usuario] ??
        0;
  }

  Widget _tablaDePuntos() {
    final compartida = widget.compartida;
    if (compartida == null) return TablaPuntuacion(tablero: _tablero);
    return TablaPuntosPartida(
      puntuacion: PuntuacionMultijugador(widget.mapa, compartida.rondasPorZona),
      jugadores: compartida.sala.jugadores,
      usuario: compartida.usuario,
      ronda: compartida.rondaDeMiSiguienteJugada,
      meta: compartida.sala.meta,
    );
  }

  bool get _puedeEditarIniciales =>
      !_bloc.jugando && (widget.compartida?.puedeEditar ?? true);

  @override
  void initState() {
    super.initState();
    final compartida = widget.compartida;
    if (compartida != null) {
      // Tras recargar la página vuelven los números que ya se habían puesto.
      if (widget.tablero == null) compartida.guardado.restaurarCeldas(_tablero);
      _sincronizarConCompartida();
      _zonasAjenas = compartida.zonasAjenas.listen(_avisarZonasAjenas);
      compartida
        ..addListener(_alCambiarCompartida)
        ..iniciar();
    }
  }

  /// Otros llenaron zonas: se avisa a este jugador quién y cuál, y suena
  /// triste. Quien la llenó solo oye su festejo. Con la partida ya terminada
  /// manda la pantalla final.
  void _avisarZonasAjenas(List<ZonaAjena> nuevas) {
    final compartida = widget.compartida;
    if (!mounted || compartida == null || compartida.terminada) return;
    final mensajes = [
      for (final nueva in nuevas)
        '@${nueva.jugador} llenó ${_nombresZonas.de(nueva.zona)}',
    ];
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('aviso-zona-ajena'),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              const Icon(Icons.flag, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(mensajes.join('\n'))),
            ],
          ),
        ),
      );
    _sonidoTristeza.reproducir();
  }

  /// Solo en multijugador: quién llenó cada zona y qué lugar ganó.
  Widget? _registroDeZonas({required double maxAltura}) {
    final compartida = widget.compartida;
    if (compartida == null) return null;
    return PanelRegistroZonas(
      entradas: RegistroZonas(
        PuntuacionMultijugador(widget.mapa, compartida.rondasPorZona),
      ).entradas,
      nombres: _nombresZonas,
      usuario: compartida.usuario,
      maxAltura: maxAltura,
    );
  }

  void _alCambiarCompartida() {
    if (mounted) setState(_sincronizarConCompartida);
  }

  /// El servidor manda sobre lo ya finalizado: así quien vuelve recupera sus
  /// números. Cuando todos terminaron, se pasa a lanzar los dados.
  void _sincronizarConCompartida() {
    final compartida = widget.compartida!;
    if (compartida.perdida != null || compartida.terminada) {
      _opcionAnclaSeleccionada = null;
      _movimientoSeleccionado = null;
    }
    if (compartida.terminada && !_finAnunciado) {
      _finAnunciado = true;
      if (compartida.gane) _sonidoVictoria.reproducir();
    }
    if (_bloc.jugando) return;
    final guardados = compartida.sala.miTablero;
    if (guardados.isNotEmpty &&
        !listEquals(guardados, _bloc.obtenerValoresIniciales())) {
      for (final (fila, columna) in widget.mapa.celdasIniciales) {
        _bloc.colocarValorInicial(fila, columna, null);
      }
      for (var i = 0; i < guardados.length; i++) {
        final (fila, columna) = widget.mapa.celdasIniciales[i];
        _bloc.colocarValorInicial(fila, columna, guardados[i]);
      }
    }
    if (compartida.todosTerminaron && _bloc.puedeIniciar) {
      _bloc.iniciarPartida();
    }
  }

  /// Irse sin avisar dejaría a los demás esperando, así que se avisa al salir.
  Future<void> _salirDePartida() async {
    final compartida = widget.compartida!;
    final navegador = Navigator.of(context);
    if (compartida.perdida == null) {
      // Terminada la partida, ya nadie espera a este jugador.
      if (!compartida.terminada) {
        final confirmado = await confirmarSalidaDePartida(context);
        if (!confirmado) return;
      }
      await compartida.salir();
    }
    navegador.pop();
  }

  List<MovimientoAncla> get _movimientosDisponibles {
    final opcion = _opcionAnclaSeleccionada;
    if (opcion == null || !_validadorAnclas.puedeSerAncla(opcion.ancla)) {
      return const [];
    }

    return _validadorAnclas.obtenerMovimientosPosibles(opcion);
  }

  Set<int> get _valoresIniciales => {
    for (final (fila, columna) in widget.mapa.celdasIniciales)
      ?_tablero.obtenerCelda(fila - 1, columna - 1).valor,
  };

  int get _turnoActual =>
      _dados.historial.lanzamientos.length +
      (_numeroLanzamientoPendiente == null ? 1 : 0);

  Widget _seccionInferior(List<MovimientoAncla> movimientosDisponibles) {
    final enComun = widget.compartida;
    if (enComun != null && enComun.terminada) {
      return KeyedSubtree(
        key: const ValueKey('fase-final'),
        child: PanelFinCompartido(
          ganadores: enComun.sala.ganadores,
          usuario: enComun.usuario,
          puntos: PuntuacionMultijugador(
            widget.mapa,
            enComun.rondasPorZona,
          ).puntos,
          jugadores: enComun.sala.jugadores,
          meta: enComun.sala.meta,
          porAbandono: enComun.sala.porAbandono,
          onVolver: _salirDePartida,
        ),
      );
    }

    if (_partidaFinalizada && enComun != null) {
      return KeyedSubtree(
        key: const ValueKey('fase-tablero-lleno'),
        child: PanelTableroLleno(puntos: _misPuntos),
      );
    }

    if (_partidaFinalizada) {
      return KeyedSubtree(
        key: const ValueKey('fase-fin'),
        child: PanelFinPartida(
          puntos: _misPuntos,
          maximo: _tablero.puntuacionMaxima,
          onNuevaPartida: _jugarNuevaPartida,
        ),
      );
    }

    final compartida = widget.compartida;
    final perdida = compartida?.perdida;
    if (_bloc.jugando && perdida != null) {
      return KeyedSubtree(
        key: const ValueKey('fase-perdida'),
        child: AvisoPartidaPerdida(motivo: perdida, onVolver: _salirDePartida),
      );
    }

    if (!_bloc.jugando) {
      return KeyedSubtree(
        key: const ValueKey('fase-preparacion'),
        child: compartida == null
            ? PanelPreparacion(
                valoresColocados: _valoresIniciales,
                puedeIniciar: _bloc.puedeIniciar,
                onComenzar: _comenzarPartida,
              )
            : PanelTableroCompartido(
                compartida: compartida,
                valoresColocados: _valoresIniciales,
                tableroCompleto: _bloc.puedeIniciar,
                onFinalizar: () =>
                    compartida.finalizar(_bloc.obtenerValoresIniciales()),
                onVolver: _salirDePartida,
              ),
      );
    }

    if (compartida != null && !compartida.puedoJugarRonda) {
      return KeyedSubtree(
        key: const ValueKey('fase-espera-ronda'),
        child: PanelEsperaRonda(sala: compartida.sala),
      );
    }

    final opcion = _opcionAnclaSeleccionada;
    final movimiento = _movimientoSeleccionado;
    final Widget? aviso = opcion == null
        ? null
        : movimientosDisponibles.isEmpty
        ? const estilo.AvisoJuego(
            key: ValueKey('aviso-sin-posiciones'),
            icono: Icons.do_not_disturb_alt,
            texto: 'No hay posiciones válidas para esta opción.',
            advertencia: true,
          )
        : movimiento == null
        ? const estilo.AvisoJuego(
            key: ValueKey('aviso-tocar-celda'),
            icono: Icons.touch_app_outlined,
            texto: 'Toca una posición resaltada del tablero.',
          )
        : null;

    return KeyedSubtree(
      key: const ValueKey('fase-juego'),
      child: Container(
        key: const Key('turn-panel'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: estilo.decoracionTarjeta(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabeceraTurno(turno: _turnoActual),
            const SizedBox(height: 8),
            PanelLanzamientoDados(
              key: ValueKey('dice-panel-$_rondaDados'),
              dados: _dados,
              validadorAnclas: _validadorAnclas,
              onOpcionAnclaChanged: _seleccionarOpcionAncla,
              onPasarTurno: _pasarTurno,
              onHistorialActualizado: _actualizarHistorial,
              partidaFinalizada: _partidaFinalizada,
              sonidoDados: _sonidoDados,
              lanzamientoAutomatico: compartida != null,
              textoPasarTurno: compartida == null
                  ? 'Pasar turno'
                  : 'Saltar turno',
            ),
            if (aviso != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: aviso),
            if (opcion != null && movimiento != null)
              ResumenMovimiento(
                opcion: opcion,
                movimiento: movimiento,
                onConfirmar: _confirmarMovimiento,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarSelector(int fila, int columna) async {
    final valor = await showDialog<int>(
      context: context,
      builder: (context) => SelectorValorInicial(
        valorActual: _tablero.obtenerCelda(fila - 1, columna - 1).valor,
        valoresColocados: _valoresIniciales,
        permitidos: _bloc.valoresPermitidos(fila, columna),
      ),
    );

    if (valor != null && mounted && _puedeEditarIniciales) {
      setState(() {
        _bloc.colocarValorInicial(fila, columna, valor == 0 ? null : valor);
      });
    }
  }

  void _comenzarPartida() {
    setState(_bloc.iniciarPartida);
  }

  void _seleccionarOpcionAncla(OpcionAncla? opcion) {
    setState(() {
      _opcionAnclaSeleccionada = opcion;
      _movimientoSeleccionado = null;
    });
  }

  void _pasarTurno() {
    setState(() {
      _opcionAnclaSeleccionada = null;
      _movimientoSeleccionado = null;
      _numeroLanzamientoPendiente = null;
      _rondaDados++;
    });
    widget.compartida?.terminarTurno(tableroLleno: false);
  }

  void _actualizarHistorial() {
    setState(() {
      _numeroLanzamientoPendiente =
          _dados.historial.lanzamientos.last.numeroLanzamiento;
    });
  }

  void _seleccionarDestino(MovimientoAncla movimiento) {
    setState(() => _movimientoSeleccionado = movimiento);
  }

  void _confirmarMovimiento() {
    final opcion = _opcionAnclaSeleccionada;
    final movimiento = _movimientoSeleccionado;
    if (_partidaFinalizada ||
        opcion == null ||
        movimiento == null ||
        _numeroLanzamientoPendiente == null ||
        !_validadorAnclas.puedeSerAncla(opcion.ancla) ||
        !_tablero.puedeColocarDato(
          movimiento.destino.x,
          movimiento.destino.y,
          opcion.numeroAColocar,
        )) {
      setState(() => _movimientoSeleccionado = null);
      return;
    }

    _dados.historial.registrarAccion(
      _numeroLanzamientoPendiente!,
      '${opcion.ancla} ancla → coloca ${opcion.numeroAColocar}',
    );
    _tablero.colocarDato(
      movimiento.destino.x,
      movimiento.destino.y,
      opcion.numeroAColocar,
    );
    setState(() {
      _opcionAnclaSeleccionada = null;
      _movimientoSeleccionado = null;
      _numeroLanzamientoPendiente = null;
      _rondaDados++;
    });
    final zonaCompletada = _tablero.zonaCompletadaEn(
      movimiento.destino.x,
      movimiento.destino.y,
    );
    widget.compartida?.guardado.guardarCeldas(_tablero);
    widget.compartida?.terminarTurno(
      tableroLleno: _tablero.estaLleno,
      zonaCompletada: zonaCompletada,
    );

    // En multijugador llenar el tablero no termina la partida: el final lo
    // anuncia el servidor para todos a la vez.
    if (_partidaFinalizada && widget.compartida == null) {
      _sonidoVictoria.reproducir();
      _mostrarFinDePartida();
    } else if (zonaCompletada != null) {
      // Al ganar la partida ya suena la victoria: los aplausos van en las
      // demás zonas.
      _sonidoAplausos.reproducir();
    }
  }

  Future<void> _mostrarFinDePartida() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('game-over-dialog'),
        title: const Text('Fin de la partida'),
        content: Text('Has puntuado $_misPuntos puntos'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Aceptar'),
          ),
          FilledButton(
            key: const Key('new-game-dialog-button'),
            onPressed: _jugarNuevaPartida,
            child: const Text('Jugar nueva partida'),
          ),
        ],
      ),
    );
  }

  Future<void> _jugarNuevaPartida() async {
    final compartida = widget.compartida;
    if (compartida != null) {
      // Se vuelve al menú que ya estaba abierto, con la sesión iniciada.
      final navegador = Navigator.of(context);
      if (compartida.perdida == null) {
        final confirmado = await confirmarSalidaDePartida(context);
        if (!confirmado) return;
        await compartida.salir();
      }
      navegador.popUntil((ruta) => ruta.isFirst);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SeleccionMapaPage()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    widget.compartida
      ?..removeListener(_alCambiarCompartida)
      ..dispose();
    _zonasAjenas?.cancel();
    _sonidoVictoria.dispose();
    _sonidoDados.dispose();
    _sonidoAplausos.dispose();
    _sonidoTristeza.dispose();
    super.dispose();
  }

  Widget _construirTablero(List<MovimientoAncla> movimientosDisponibles) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: TableroPage.tamano,
            ),
            itemCount: TableroPage.tamano * TableroPage.tamano,
            itemBuilder: (context, index) {
              final filaIndice = index ~/ TableroPage.tamano;
              final columnaIndice = index % TableroPage.tamano;
              final fila = filaIndice + 1;
              final columna = columnaIndice + 1;
              final posicionInicial = widget.mapa.celdasIniciales.indexOf((
                fila,
                columna,
              ));
              final esInicial = posicionInicial >= 0;
              final celda = _tablero.obtenerCelda(filaIndice, columnaIndice);
              final valor = celda.valor;
              MovimientoAncla? movimientoDestino;
              for (final movimiento in movimientosDisponibles) {
                if (identical(movimiento.destino, celda)) {
                  movimientoDestino = movimiento;
                  break;
                }
              }
              final esDestinoPosible = movimientoDestino != null;
              final esDestinoSeleccionado = identical(
                _movimientoSeleccionado?.destino,
                celda,
              );
              final color = TableroPage.colorEn(
                filaIndice,
                columnaIndice,
                mapa: widget.mapa,
              );

              return Material(
                color: color,
                child: InkWell(
                  key: esInicial
                      ? Key('initial-cell-$fila-$columna')
                      : esDestinoPosible
                      ? Key('candidate-cell-$fila-$columna')
                      : Key('board-cell-$fila-$columna'),
                  onTap: _puedeEditarIniciales && esInicial
                      ? () => _mostrarSelector(fila, columna)
                      : _bloc.jugando && esDestinoPosible
                      ? () => _seleccionarDestino(movimientoDestino!)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.fromBorderSide(
                        BorderSide(
                          color: esDestinoSeleccionado
                              ? Colors.black
                              : esDestinoPosible || esInicial
                              ? Colors.white
                              : Colors.black,
                          width: esDestinoSeleccionado
                              ? 3
                              : esDestinoPosible || esInicial
                              ? 2
                              : 1,
                        ),
                      ),
                    ),
                    child: valor != null
                        ? Center(
                            child: Text(
                              valor.toString(),
                              style: TextStyle(
                                color: color.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : esDestinoPosible
                        ? Center(
                            child: esDestinoSeleccionado
                                ? Text(
                                    _opcionAnclaSeleccionada!.numeroAColocar
                                        .toString(),
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.white,
                                  ),
                          )
                        : esInicial
                        ? const Center(
                            child: Text(
                              '+',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movimientosDisponibles = _movimientosDisponibles;
    final mostrarHistorialLateral = MediaQuery.sizeOf(context).width >= 700;
    final pantalla = Scaffold(
      appBar: AppBar(
        title: const Text('Tablero'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        notificationPredicate: (_) => false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, limites) {
            final fase = AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              layoutBuilder: (actual, anteriores) => Stack(
                alignment: Alignment.topCenter,
                children: [...anteriores, ?actual],
              ),
              child: _seccionInferior(movimientosDisponibles),
            );
            final tablero = _construirTablero(movimientosDisponibles);

            if (mostrarHistorialLateral) {
              return Row(
                children: [
                  Expanded(child: tablero),
                  SizedBox(
                    width: 320,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          fase,
                          const SizedBox(height: 10),
                          PanelReglas(reglas: _reglas),
                          const SizedBox(height: 10),
                          _tablaDePuntos(),
                          if (_registroDeZonas(maxAltura: 260)
                              case final registro?) ...[
                            const SizedBox(height: 10),
                            registro,
                          ],
                          const SizedBox(height: 10),
                          HistorialDadosView(
                            historial: _dados.historial,
                            maxAlturaFilas: 300,
                            abiertoAlInicio: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Expanded(child: tablero),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: limites.maxHeight * 0.5,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        fase,
                        // Desde que se ponen los números iniciales.
                        const SizedBox(height: 10),
                        PanelReglas(reglas: _reglas),
                        if (_bloc.jugando) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Las zonas completadas van bajo el historial:
                              // a la vista, junto a los puntos, y ocupando el
                              // lugar que deja el historial cerrado.
                              Expanded(
                                flex: 5,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    HistorialDadosView(
                                      historial: _dados.historial,
                                      maxAlturaFilas: 120,
                                      abiertoAlInicio: false,
                                    ),
                                    if (_registroDeZonas(maxAltura: 300)
                                        case final registro?) ...[
                                      const SizedBox(height: 10),
                                      registro,
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(flex: 7, child: _tablaDePuntos()),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    if (widget.compartida == null) return pantalla;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _salirDePartida();
      },
      child: pantalla,
    );
  }
}

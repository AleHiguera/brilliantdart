import 'package:flutter/material.dart';
import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/dados.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/colores_zonas.dart' as estilo;
import 'package:brilliant_mobile/historial_dados_view.dart';
import 'package:brilliant_mobile/panel_lanzamiento_dados.dart';
import 'package:brilliant_mobile/paneles_juego.dart';
import 'package:brilliant_mobile/sonidos.dart';
import 'package:brilliant_mobile/tabla_puntuacion.dart';

void main() {
  runApp(const BrilliantApp());
}

class BrilliantApp extends StatelessWidget {
  const BrilliantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brilliant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SeleccionMapaPage(),
    );
  }
}

class SeleccionMapaPage extends StatelessWidget {
  const SeleccionMapaPage({super.key});

  void _abrirMapa(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const TableroPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brilliant'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                    disponible: true,
                    onTap: () => _abrirMapa(context),
                  ),
                ),
                const SizedBox(height: 12),
                const _Aparecer(
                  indice: 2,
                  child: _OpcionMapa(numero: 2, disponible: false),
                ),
                const SizedBox(height: 12),
                const _Aparecer(
                  indice: 3,
                  child: _OpcionMapa(numero: 3, disponible: false),
                ),
                const SizedBox(height: 24),
                const _Aparecer(indice: 4, child: _ComoSeJuega()),
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
  const _OpcionMapa({
    super.key,
    required this.numero,
    required this.disponible,
    this.onTap,
  });

  final int numero;
  final bool disponible;
  final VoidCallback? onTap;

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
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                  ),
                              itemCount: 49,
                              itemBuilder: (context, index) => DecoratedBox(
                                key: Key('map-preview-cell-$index'),
                                decoration: BoxDecoration(
                                  color: TableroPage.colorEn(
                                    index ~/ 7,
                                    index % 7,
                                  ),
                                  border: Border.all(
                                    color: Colors.black12,
                                    width: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          )
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
  });

  final Dados? dados;
  final Tablero? tablero;
  final Sonido? sonidoVictoria;
  final Sonido? sonidoDados;

  static const int tamano = 7;

  static const Map<TipoZona, Color> coloresZonas = estilo.coloresZonas;

  static Color colorEn(int fila, int columna) =>
      coloresZonas[mapaUno.tiposPorCelda[fila][columna]]!;

  @override
  State<TableroPage> createState() => _TableroPageState();
}

class _TableroPageState extends State<TableroPage> {
  late final Dados _dados = widget.dados ?? Dados();
  late final Tablero _tablero = widget.tablero ?? mapaUno.crearTablero();
  late final Sonido _sonidoVictoria =
      widget.sonidoVictoria ?? SonidoAsset(Sonido.victoria);
  late final Sonido _sonidoDados =
      widget.sonidoDados ?? SonidoAsset(Sonido.dados);
  late final BlocValoresIniciales _bloc = BlocValoresIniciales(
    _tablero,
    celdasIniciales: mapaUno.celdasIniciales,
  );
  late final ValidadorAnclas _validadorAnclas = ValidadorAnclas(_tablero);
  OpcionAncla? _opcionAnclaSeleccionada;
  MovimientoAncla? _movimientoSeleccionado;
  int? _numeroLanzamientoPendiente;
  int _rondaDados = 0;

  bool get _partidaFinalizada => _bloc.jugando && _tablero.estaLleno;

  List<MovimientoAncla> get _movimientosDisponibles {
    final opcion = _opcionAnclaSeleccionada;
    if (opcion == null || !_validadorAnclas.puedeSerAncla(opcion.ancla)) {
      return const [];
    }

    return _validadorAnclas.obtenerMovimientosPosibles(opcion);
  }

  Set<int> get _valoresIniciales => {
    for (final (fila, columna) in mapaUno.celdasIniciales)
      ?_tablero.obtenerCelda(fila - 1, columna - 1).valor,
  };

  int get _turnoActual =>
      _dados.historial.lanzamientos.length +
      (_numeroLanzamientoPendiente == null ? 1 : 0);

  Widget _seccionInferior(List<MovimientoAncla> movimientosDisponibles) {
    if (_partidaFinalizada) {
      return KeyedSubtree(
        key: const ValueKey('fase-fin'),
        child: PanelFinPartida(
          puntos: _tablero.puntuacionTotal,
          onNuevaPartida: _jugarNuevaPartida,
        ),
      );
    }

    if (!_bloc.jugando) {
      return KeyedSubtree(
        key: const ValueKey('fase-preparacion'),
        child: PanelPreparacion(
          valoresColocados: _valoresIniciales,
          puedeIniciar: _bloc.puedeIniciar,
          onComenzar: _comenzarPartida,
        ),
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
      ),
    );

    if (valor != null && mounted) {
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

    if (_partidaFinalizada) {
      _sonidoVictoria.reproducir();
      _mostrarFinDePartida();
    }
  }

  Future<void> _mostrarFinDePartida() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('game-over-dialog'),
        title: const Text('Fin de la partida'),
        content: Text('Has puntuado ${_tablero.puntuacionTotal} puntos'),
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

  void _jugarNuevaPartida() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SeleccionMapaPage()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _sonidoVictoria.dispose();
    _sonidoDados.dispose();
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
              final posicionInicial = mapaUno.celdasIniciales.indexOf((
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
              final color = TableroPage.colorEn(filaIndice, columnaIndice);

              return Material(
                color: color,
                child: InkWell(
                  key: esInicial
                      ? Key('initial-cell-$fila-$columna')
                      : esDestinoPosible
                      ? Key('candidate-cell-$fila-$columna')
                      : Key('board-cell-$fila-$columna'),
                  onTap: !_bloc.jugando && esInicial
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
    return Scaffold(
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
                          TablaPuntuacion(tablero: _tablero),
                          const SizedBox(height: 10),
                          HistorialDadosView(
                            historial: _dados.historial,
                            maxAlturaFilas: 300,
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
                        if (_bloc.jugando) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: HistorialDadosView(
                                  historial: _dados.historial,
                                  maxAlturaFilas: 120,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 7,
                                child: TablaPuntuacion(tablero: _tablero),
                              ),
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
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/dados.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/historial_dados_view.dart';
import 'package:brilliant_mobile/panel_lanzamiento_dados.dart';
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TableroPage()),
    );
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text(
              'Elige tu mapa',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selecciona un mapa para preparar la partida.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _OpcionMapa(
              key: const Key('map-option-1'),
              numero: 1,
              disponible: true,
              onTap: () => _abrirMapa(context),
            ),
            const SizedBox(height: 12),
            const _OpcionMapa(numero: 2, disponible: false),
            const SizedBox(height: 12),
            const _OpcionMapa(numero: 3, disponible: false),
          ],
        ),
      ),
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
    final foreground = disponible ? Colors.black : Colors.black54;

    return Semantics(
      button: disponible,
      enabled: disponible,
      label: disponible ? 'Mapa $numero, disponible' : 'Mapa $numero, bloqueado',
      child: Material(
        color: disponible ? const Color(0xFFF4F4F0) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          key: Key('map-choice-$numero'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (disponible)
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                        ),
                        itemCount: 49,
                        itemBuilder: (context, index) => DecoratedBox(
                          decoration: BoxDecoration(
                            color: TableroPage.colorEn(index ~/ 7, index % 7),
                            border: Border.all(color: Colors.black12, width: 0.3),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4E4E4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.lock_outline, size: 28),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mapa $numero',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        disponible ? 'Disponible' : 'Próximamente',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: foreground,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  disponible ? Icons.arrow_forward : Icons.lock_outline,
                  color: foreground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TableroPage extends StatefulWidget {
  const TableroPage({super.key, this.dados});

  final Dados? dados;

  static const int tamano = 7;

  static const Map<TipoZona, Color> coloresZonas = {
    TipoZona.azul: Color(0xFF2196F3),
    TipoZona.rojo: Color(0xFFF44336),
    TipoZona.verde: Color(0xFF4CAF50),
    TipoZona.amarillo: Color(0xFFFFEB3B),
    TipoZona.morado: Color(0xFF9C27B0),
  };

  static Color colorEn(int fila, int columna) =>
      coloresZonas[MapaUno.tiposPorCelda[fila][columna]]!;

  @override
  State<TableroPage> createState() => _TableroPageState();
}

class _TableroPageState extends State<TableroPage> {
  late final Dados _dados = widget.dados ?? Dados();
  final Tablero _tablero = MapaUno.crearTablero();
  late final BlocValoresIniciales _bloc = BlocValoresIniciales(_tablero);
  late final ValidadorAnclas _validadorAnclas = ValidadorAnclas(_tablero);
  OpcionAncla? _opcionAnclaSeleccionada;
  MovimientoAncla? _movimientoSeleccionado;
  int? _numeroLanzamientoPendiente;
  int _rondaDados = 0;

  List<MovimientoAncla> get _movimientosDisponibles {
    final opcion = _opcionAnclaSeleccionada;
    if (opcion == null || !_validadorAnclas.puedeSerAncla(opcion.ancla)) {
      return const [];
    }

    return _validadorAnclas.obtenerMovimientosPosibles(opcion);
  }

  int get _cantidadColocada => BlocValoresIniciales.celdasIniciales
      .where((celda) =>
          _tablero.obtenerCelda(celda.$1 - 1, celda.$2 - 1).valor != null)
      .length;

  Future<void> _mostrarSelector(int fila, int columna) async {
    final valor = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          for (var numero = 1; numero <= 6; numero++)
            SimpleDialogOption(
              key: Key('initial-value-$numero'),
              onPressed: () => Navigator.pop(context, numero),
              child: Text('$numero'),
            ),
          SimpleDialogOption(
            key: const Key('clear-initial-value'),
            onPressed: () => Navigator.pop(context, 0),
            child: const Text('Vaciar celda'),
          ),
        ],
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
    if (opcion == null ||
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: TableroPage.tamano,
                      ),
                      itemCount: TableroPage.tamano * TableroPage.tamano,
                      itemBuilder: (context, index) {
                        final filaIndice = index ~/ TableroPage.tamano;
                        final columnaIndice = index % TableroPage.tamano;
                        final fila = filaIndice + 1;
                        final columna = columnaIndice + 1;
                        final posicionInicial =
                            BlocValoresIniciales.celdasIniciales.indexOf(
                          (fila, columna),
                        );
                        final esInicial = posicionInicial >= 0;
                        final celda =
                            _tablero.obtenerCelda(filaIndice, columnaIndice);
                        final valor = celda.valor;
                        MovimientoAncla? movimientoDestino;
                        for (final movimiento in movimientosDisponibles) {
                          if (identical(movimiento.destino, celda)) {
                            movimientoDestino = movimiento;
                            break;
                          }
                        }
                        final esDestinoPosible = movimientoDestino != null;
                        final esDestinoSeleccionado =
                            identical(_movimientoSeleccionado?.destino, celda);
                        final color =
                            TableroPage.colorEn(filaIndice, columnaIndice);

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
                                    ? () =>
                                        _seleccionarDestino(movimientoDestino!)
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
                                                  _opcionAnclaSeleccionada!
                                                      .numeroAColocar
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
                      ),
                    ),
                  if (mostrarHistorialLateral)
                    SizedBox(
                      width: 292,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TablaPuntuacion(tablero: _tablero),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      'Historial de dados',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    HistorialDadosView(
                                      historial: _dados.historial,
                                      maxAlturaFilas: 300,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_bloc.jugando && !mostrarHistorialLateral)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historial de dados',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          HistorialDadosView(
                            historial: _dados.historial,
                            maxAlturaFilas: 120,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 7,
                      child: TablaPuntuacion(tablero: _tablero),
                    ),
                  ],
                ),
              ),
            if (_bloc.jugando)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Lanza los dados para continuar',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PanelLanzamientoDados(
                      key: ValueKey('dice-panel-$_rondaDados'),
                      dados: _dados,
                      validadorAnclas: _validadorAnclas,
                      onOpcionAnclaChanged: _seleccionarOpcionAncla,
                      onPasarTurno: _pasarTurno,
                      onHistorialActualizado: _actualizarHistorial,
                    ),
                    if (_opcionAnclaSeleccionada != null &&
                        movimientosDisponibles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('No hay posiciones válidas para esta opción.'),
                      ),
                    if (_opcionAnclaSeleccionada != null &&
                        movimientosDisponibles.isNotEmpty &&
                        _movimientoSeleccionado == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Toca una posición resaltada del tablero.'),
                      ),
                    if (_movimientoSeleccionado != null)
                      _ResumenMovimiento(
                        opcion: _opcionAnclaSeleccionada!,
                        movimiento: _movimientoSeleccionado!,
                        onConfirmar: _confirmarMovimiento,
                      ),
                  ],
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Coloca los 6 números iniciales para comenzar',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ProgresoIniciales(
                        cantidad: _cantidadColocada,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _bloc.puedeIniciar ? _comenzarPartida : null,
                      child: const Text('Comenzar'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgresoIniciales extends StatelessWidget {
  const _ProgresoIniciales({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('initial-progress'),
      label: '$cantidad de 6 números iniciales colocados',
      child: Row(
        children: [
          CustomPaint(
            size: const Size.square(44),
            painter: _RuedaProgresoPainter(cantidad),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Números iniciales',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '$cantidad/6',
                key: const Key('initial-progress-count'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RuedaProgresoPainter extends CustomPainter {
  _RuedaProgresoPainter(this.cantidad);

  final int cantidad;

  static const List<Color> _colores = [
    Color(0xFFFFEB3B),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFF44336),
    Color(0xFFFF9800),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = math.min(size.width, size.height) / 2 - 1;
    final limites = Rect.fromCircle(center: centro, radius: radio);
    final separador = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var indice = 0; indice < 6; indice++) {
      final inicio = -math.pi / 2 + indice * math.pi / 3;
      final sector = Path()
        ..moveTo(centro.dx, centro.dy)
        ..arcTo(limites, inicio, math.pi / 3, false)
        ..close();
      final relleno = Paint()
        ..color = indice < cantidad
            ? _colores[indice]
            : const Color(0xFFE6E6E6);
      canvas.drawPath(sector, relleno);
      canvas.drawPath(sector, separador);
    }

    canvas.drawCircle(
      centro,
      radio,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_RuedaProgresoPainter oldDelegate) =>
      cantidad != oldDelegate.cantidad;
}

class _ResumenMovimiento extends StatelessWidget {
  const _ResumenMovimiento({
    required this.opcion,
    required this.movimiento,
    required this.onConfirmar,
  });

  final OpcionAncla opcion;
  final MovimientoAncla movimiento;
  final VoidCallback onConfirmar;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('movement-summary'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFD0D0D0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ancla: ${opcion.ancla} en (${movimiento.ancla.x + 1}, ${movimiento.ancla.y + 1})',
          ),
          Text('Número a colocar: ${opcion.numeroAColocar}'),
          Text(
            'Posición: (${movimiento.destino.x + 1}, ${movimiento.destino.y + 1})',
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.center,
            child: FilledButton.icon(
              key: const Key('confirm-move-button'),
              onPressed: onConfirmar,
              icon: const Icon(Icons.check),
              label: const Text('Confirmar movimiento'),
            ),
          ),
        ],
      ),
    );
  }
}

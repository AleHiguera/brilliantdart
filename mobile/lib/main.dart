import 'package:flutter/material.dart';
import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/dados.dart';
import 'package:brilliantdart/mapa_uno.dart';
import 'package:brilliantdart/tablero.dart';
import 'package:brilliantdart/tipoo.dart';
import 'package:brilliantdart/validador_anclas.dart';
import 'package:brilliant_mobile/panel_lanzamiento_dados.dart';

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
        title: Text('Celda ($fila, $columna)'),
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
      _rondaDados++;
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
        !_validadorAnclas.puedeSerAncla(opcion.ancla) ||
        !_tablero.puedeColocarDato(
          movimiento.destino.x,
          movimiento.destino.y,
          opcion.numeroAColocar,
        )) {
      setState(() => _movimientoSeleccionado = null);
      return;
    }

    _tablero.colocarDato(
      movimiento.destino.x,
      movimiento.destino.y,
      opcion.numeroAColocar,
    );
    setState(() {
      _opcionAnclaSeleccionada = null;
      _movimientoSeleccionado = null;
      _rondaDados++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final movimientosDisponibles = _movimientosDisponibles;
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
                      child: Text(
                        'Números: $_cantidadColocada/6',
                        style: Theme.of(context).textTheme.titleMedium,
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
          SizedBox(
            width: double.infinity,
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

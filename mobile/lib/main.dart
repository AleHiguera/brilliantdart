import 'package:flutter/material.dart';
import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/tablero.dart';
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
                            color: TableroPage.mapaColores[index ~/ 7][index % 7],
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
  const TableroPage({super.key});

  static const int tamano = 7;

  static const List<List<Color>> mapaColores = [
    [Color(0xFFFFEB3B), Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFF9C27B0), Color(0xFF9C27B0), Color(0xFFFFEB3B)],
    [Color(0xFF4CAF50), Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFF9C27B0), Color(0xFF4CAF50)],
    [Color(0xFF4CAF50), Color(0xFFF44336), Color(0xFFF44336), Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFF4CAF50), Color(0xFF4CAF50)],
    [Color(0xFF4CAF50), Color(0xFFF44336), Color(0xFF9C27B0), Color(0xFFFFEB3B), Color(0xFF4CAF50), Color(0xFF4CAF50), Color(0xFF4CAF50)],
    [Color(0xFF4CAF50), Color(0xFFF44336), Color(0xFF9C27B0), Color(0xFF9C27B0), Color(0xFFF44336), Color(0xFFF44336), Color(0xFF2196F3)],
    [Color(0xFFF44336), Color(0xFFF44336), Color(0xFF9C27B0), Color(0xFFF44336), Color(0xFFF44336), Color(0xFF2196F3), Color(0xFF2196F3)],
    [Color(0xFFFFEB3B), Color(0xFF9C27B0), Color(0xFF9C27B0), Color(0xFFF44336), Color(0xFFF44336), Color(0xFF2196F3), Color(0xFFFFEB3B)],
  ];

  @override
  State<TableroPage> createState() => _TableroPageState();
}

class _TableroPageState extends State<TableroPage> {
  final Tablero _tablero = Tablero();
  late final BlocValoresIniciales _bloc = BlocValoresIniciales(_tablero);

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partida iniciada')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        final valor = esInicial
                            ? _tablero.obtenerCelda(
                                filaIndice,
                                columnaIndice,
                              ).valor
                            : null;
                        final color =
                            TableroPage.mapaColores[filaIndice][columnaIndice];

                        return Material(
                          color: color,
                          child: InkWell(
                            key: esInicial
                                ? Key('initial-cell-$fila-$columna')
                                : null,
                            onTap: esInicial && !_bloc.jugando
                                ? () => _mostrarSelector(fila, columna)
                                : null,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.fromBorderSide(
                                  BorderSide(
                                    color: esInicial
                                        ? Colors.white
                                        : Colors.black,
                                    width: esInicial ? 2 : 1,
                                  ),
                                ),
                              ),
                              child: esInicial
                                  ? Center(
                                      child: Text(
                                        valor?.toString() ?? '+',
                                        style: TextStyle(
                                          color: valor == null
                                              ? Colors.black87
                                              : color.computeLuminance() > 0.5
                                                  ? Colors.black
                                                  : Colors.white,
                                          fontSize: valor == null ? 20 : 24,
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
                    const PanelLanzamientoDados(),
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

import 'package:flutter/material.dart';
import 'package:brilliantdart/bloc_valores_iniciales.dart';
import 'package:brilliantdart/tablero.dart';

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
      home: const TableroPage(),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Números: $_cantidadColocada/6',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        _bloc.puedeIniciar && !_bloc.jugando
                            ? _comenzarPartida
                            : null,
                    child: Text(_bloc.jugando ? 'En partida' : 'Comenzar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

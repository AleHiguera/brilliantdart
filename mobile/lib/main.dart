import 'package:flutter/material.dart';

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

class TableroPage extends StatelessWidget {
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: tamano,
                ),
                itemCount: tamano * tamano,
                itemBuilder: (context, index) {
                  final row = index ~/ tamano;
                  final col = index % tamano;
                  final color = mapaColores[row][col];

                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.fromBorderSide(
                        const BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

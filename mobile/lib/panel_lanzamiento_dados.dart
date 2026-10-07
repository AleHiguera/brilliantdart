import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:brilliantdart/dados.dart';

class PanelLanzamientoDados extends StatefulWidget {
  const PanelLanzamientoDados({super.key});

  @override
  State<PanelLanzamientoDados> createState() => _PanelLanzamientoDadosState();
}

class _PanelLanzamientoDadosState extends State<PanelLanzamientoDados>
    with SingleTickerProviderStateMixin {
  final Dados _dados = Dados();
  final Random _aleatorioAnimacion = Random();
  late final AnimationController _animacion;
  Timer? _temporizador;
  int? _resultadoDado1;
  int? _resultadoDado2;
  int _caraDado1 = 1;
  int _caraDado2 = 1;
  bool _estaLanzando = false;

  @override
  void initState() {
    super.initState();
    _animacion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _animacion.dispose();
    super.dispose();
  }

  Future<void> _lanzarDados() async {
    if (_estaLanzando) return;

    setState(() => _estaLanzando = true);
    _animacion.repeat();
    _temporizador = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted) return;
      setState(() {
        _caraDado1 = _aleatorioAnimacion.nextInt(6) + 1;
        _caraDado2 = _aleatorioAnimacion.nextInt(6) + 1;
      });
    });

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    _temporizador?.cancel();
    final (resultadoDado1, resultadoDado2) = _dados.lanzar();
    _animacion.stop();
    _animacion.value = 0;

    if (!mounted) return;
    setState(() {
      _resultadoDado1 = resultadoDado1;
      _resultadoDado2 = resultadoDado2;
      _caraDado1 = resultadoDado1;
      _caraDado2 = resultadoDado2;
      _estaLanzando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final valorDado1 = _estaLanzando ? _caraDado1 : _resultadoDado1;
    final valorDado2 = _estaLanzando ? _caraDado2 : _resultadoDado2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _DadoAnimado(
                nombre: 'Dado 1',
                valor: valorDado1,
                animacion: _animacion,
                animando: _estaLanzando,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DadoAnimado(
                nombre: 'Dado 2',
                valor: valorDado2,
                animacion: _animacion,
                animando: _estaLanzando,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('roll-dice-button'),
            onPressed: _estaLanzando ? null : _lanzarDados,
            icon: const Icon(Icons.casino_outlined),
            label: const Text('Lanzar dados'),
          ),
        ),
        SizedBox(
          height: 20,
          child: _estaLanzando
              ? const Text('Lanzando dados...')
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _DadoAnimado extends StatelessWidget {
  const _DadoAnimado({
    required this.nombre,
    required this.valor,
    required this.animacion,
    required this.animando,
  });

  final String nombre;
  final int? valor;
  final Animation<double> animacion;
  final bool animando;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$nombre: ${valor ?? 'sin lanzar'}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$nombre: ${valor ?? '—'}'),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: animacion,
            builder: (context, child) {
              final movimiento = sin(animacion.value * 2 * pi);
              return Transform.translate(
                offset: Offset(0, animando ? movimiento * 5 : 0),
                child: Transform.rotate(
                  angle: animando ? movimiento * 0.18 : 0,
                  child: child,
                ),
              );
            },
            child: _CaraDado(valor: valor),
          ),
        ],
      ),
    );
  }
}

class _CaraDado extends StatelessWidget {
  const _CaraDado({required this.valor});

  final int? valor;

  @override
  Widget build(BuildContext context) {
    final puntos = switch (valor) {
      1 => {4},
      2 => {0, 8},
      3 => {0, 4, 8},
      4 => {0, 2, 6, 8},
      5 => {0, 2, 4, 6, 8},
      6 => {0, 2, 3, 5, 6, 8},
      _ => <int>{},
    };

    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF252525), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: valor == null
          ? const Center(child: Icon(Icons.question_mark, size: 22))
          : GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: 9,
              itemBuilder: (context, index) => Center(
                child: puntos.contains(index)
                    ? const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF252525),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 7, height: 7),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
    );
  }
}
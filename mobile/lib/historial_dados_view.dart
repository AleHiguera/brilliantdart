import 'package:flutter/material.dart';
import 'package:brilliantdart/historial_dados.dart';

class HistorialDadosView extends StatelessWidget {
  const HistorialDadosView({
    super.key,
    required this.historial,
    this.maxAlturaFilas = 84,
  });

  final HistorialDados historial;
  final double maxAlturaFilas;

  @override
  Widget build(BuildContext context) {
    final lanzamientos = historial.lanzamientos;

    return Container(
      key: const Key('dice-history'),
      width: double.infinity,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: const Color(0xFFBDBDBD)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lanzamientos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: Text('Sin lanzamientos', style: TextStyle(fontSize: 12)),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxAlturaFilas),
              child: ListView.separated(
                key: const Key('dice-history-list'),
                shrinkWrap: true,
                itemCount: lanzamientos.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1),
                itemBuilder: (context, index) {
                  final lanzamiento = lanzamientos[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    child: Column(
                      key: Key('dice-history-row-${lanzamiento.numeroLanzamiento}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lanzamiento ${lanzamiento.numeroLanzamiento} — Dados: '
                          '(${lanzamiento.resultadoDado1}, ${lanzamiento.resultadoDado2})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Acción: ${lanzamiento.accionRealizada ?? '—'}',
                          key: Key(
                            'dice-history-action-${lanzamiento.numeroLanzamiento}',
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

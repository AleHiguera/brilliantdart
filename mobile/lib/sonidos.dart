import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

abstract class Sonido {
  static const String victoria = 'sonidos/victoria.wav';
  static const String dados = 'sonidos/dados.wav';
  static const String aplausos = 'sonidos/aplausos.wav';
  static const String tristeza = 'sonidos/tristeza.wav';

  /// Hace sonar el sonido. Termina cuando el sonido acaba (o se corta), así
  /// quien quiera puede esperar a que acabe antes de tocar otro.
  Future<void> reproducir();

  /// Corta el sonido si está sonando.
  Future<void> detener() async {}

  void dispose() {}
}

class SonidoAsset extends Sonido {
  SonidoAsset(this.ruta);

  final String ruta;
  AudioPlayer? _reproductor;
  Completer<void>? _fin;

  /// Ningún sonido del juego dura tanto: si el aviso de que terminó no llega,
  /// no se espera más.
  static const Duration duracionMaxima = Duration(seconds: 8);

  @override
  Future<void> reproducir() async {
    _terminar();
    final fin = _fin = Completer<void>();
    StreamSubscription<void>? alTerminar;
    try {
      final reproductor = _reproductor ??= AudioPlayer();
      await reproductor.stop();
      alTerminar = reproductor.onPlayerComplete.listen((_) => _terminar());
      await reproductor.play(AssetSource(ruta));
      await fin.future.timeout(duracionMaxima, onTimeout: () {});
    } catch (_) {
      // Si el navegador o el dispositivo no permiten el audio, el juego
      // sigue igual, solo que sin sonido.
    } finally {
      await alTerminar?.cancel();
      if (identical(_fin, fin)) _terminar();
    }
  }

  void _terminar() {
    final fin = _fin;
    if (fin != null && !fin.isCompleted) fin.complete();
  }

  @override
  Future<void> detener() async {
    _terminar();
    try {
      await _reproductor?.stop();
    } catch (_) {
      // Sin audio no hay nada que cortar.
    }
  }

  @override
  void dispose() {
    _terminar();
    _reproductor?.dispose();
  }
}

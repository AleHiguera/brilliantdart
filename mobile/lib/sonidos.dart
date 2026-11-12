import 'package:audioplayers/audioplayers.dart';

abstract class Sonido {
  static const String victoria = 'sonidos/victoria.wav';
  static const String dados = 'sonidos/dados.wav';
  static const String aplausos = 'sonidos/aplausos.wav';
  static const String tristeza = 'sonidos/tristeza.wav';

  Future<void> reproducir();

  /// Corta el sonido si está sonando.
  Future<void> detener() async {}

  void dispose() {}
}

class SonidoAsset extends Sonido {
  SonidoAsset(this.ruta);

  final String ruta;
  AudioPlayer? _reproductor;

  @override
  Future<void> reproducir() async {
    try {
      final reproductor = _reproductor ??= AudioPlayer();
      await reproductor.stop();
      await reproductor.play(AssetSource(ruta));
    } catch (_) {
      // Si el navegador o el dispositivo no permiten el audio, el juego
      // sigue igual, solo que sin sonido.
    }
  }

  @override
  Future<void> detener() async {
    try {
      await _reproductor?.stop();
    } catch (_) {
      // Sin audio no hay nada que cortar.
    }
  }

  @override
  void dispose() {
    _reproductor?.dispose();
  }
}

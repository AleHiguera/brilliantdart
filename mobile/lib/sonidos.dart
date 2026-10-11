import 'package:audioplayers/audioplayers.dart';

abstract class Sonido {
  static const String victoria = 'sonidos/victoria.wav';
  static const String dados = 'sonidos/dados.wav';

  Future<void> reproducir();

  void dispose() {}
}

class SonidoAsset extends Sonido {
  SonidoAsset(this.ruta);

  final String ruta;
  AudioPlayer? _reproductor;

  @override
  Future<void> reproducir() async {
    final reproductor = _reproductor ??= AudioPlayer();
    try {
      await reproductor.stop();
      await reproductor.play(AssetSource(ruta));
    } catch (_) {
      // Si el navegador o el dispositivo no permiten el audio, el juego
      // sigue igual, solo que sin sonido.
    }
  }

  @override
  void dispose() {
    _reproductor?.dispose();
  }
}

import 'package:audioplayers/audioplayers.dart';

abstract class SonidoVictoria {
  Future<void> reproducir();

  void dispose() {}
}

class SonidoVictoriaAudio extends SonidoVictoria {
  AudioPlayer? _reproductor;

  @override
  Future<void> reproducir() async {
    final reproductor = _reproductor ??= AudioPlayer();
    try {
      await reproductor.play(AssetSource('sonidos/victoria.wav'));
    } catch (_) {
      // Si el navegador o el dispositivo no permiten el audio, la partida
      // termina igual, solo que sin sonido.
    }
  }

  @override
  void dispose() {
    _reproductor?.dispose();
  }
}

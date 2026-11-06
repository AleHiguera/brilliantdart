import 'mapa.dart';
import 'mapa_cuatro.dart';
import 'mapa_dos.dart';
import 'mapa_tres.dart';
import 'mapa_uno.dart';

/// Los mapas que se pueden jugar, en el orden en que se ofrecen.
const List<Mapa> mapasDisponibles = [mapaUno, mapaDos, mapaTres, mapaCuatro];

/// El mapa con ese número; el servidor de partidas lo identifica así.
Mapa mapaNumero(int numero) =>
    mapasDisponibles.firstWhere((mapa) => mapa.numero == numero);

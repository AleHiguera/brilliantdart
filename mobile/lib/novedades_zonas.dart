/// Una zona que otro jugador acaba de completar.
typedef ZonaAjena = ({String jugador, int zona, int ronda});

/// Compara el registro de zonas de antes con el de ahora y dice qué zonas
/// completaron los demás desde entonces. Las del propio [usuario] no cuentan:
/// esas ya las celebró al mover. No sabe nada de pantallas ni de sonidos.
List<ZonaAjena> zonasNuevasDeOtros({
  required Map<int, Map<String, int>> antes,
  required Map<int, Map<String, int>> ahora,
  required String? usuario,
}) {
  final zonas = ahora.keys.toList()..sort();
  return [
    for (final zona in zonas)
      for (final MapEntry(key: jugador, value: ronda) in ahora[zona]!.entries)
        if (jugador != usuario && !(antes[zona]?.containsKey(jugador) ?? false))
          (jugador: jugador, zona: zona, ronda: ronda),
  ];
}

/// Qué hacer con las zonas ajenas que aún no se han avisado.
typedef RepartoAvisos = ({
  List<ZonaAjena> avisar,
  List<ZonaAjena> esperar,
  List<ZonaAjena> descartar,
});

/// Decide qué zonas ajenas se avisan ya a [usuario]:
/// - Si él también llenó esa zona, antes o en la misma ronda (empate), no se
///   le avisa nunca: no le ganaron nada.
/// - Una zona de la ronda en juego espera a que él haya jugado esa ronda: hasta
///   entonces todavía podría empatarla, y además no debe enterarse a media
///   ronda de lo que hicieron los demás.
/// - Las de rondas ya cerradas, o las de esta si ya jugó, se avisan.
///
/// [registro] es el registro de zonas que conoce, con la suya recién llenada.
RepartoAvisos repartirAvisos({
  required List<ZonaAjena> pendientes,
  required Map<int, Map<String, int>> registro,
  required String? usuario,
  required int rondaActual,
  required bool yaJugoEstaRonda,
}) {
  final avisar = <ZonaAjena>[];
  final esperar = <ZonaAjena>[];
  final descartar = <ZonaAjena>[];
  for (final ajena in pendientes) {
    final mia = registro[ajena.zona]?[usuario];
    if (mia != null && mia <= ajena.ronda) {
      descartar.add(ajena);
    } else if (ajena.ronda >= rondaActual && !yaJugoEstaRonda) {
      esperar.add(ajena);
    } else {
      avisar.add(ajena);
    }
  }
  return (avisar: avisar, esperar: esperar, descartar: descartar);
}

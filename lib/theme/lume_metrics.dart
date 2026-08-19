/// Escala de espaçamento (base 2) e raios do kit de design da Lume.
/// O raio cresce com a área do elemento: chip pequeno arredonda pouco,
/// cartão grande arredonda muito, botão de ação é pílula.
class LumeSpacing {
  LumeSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const screenMargin = 16.0;
  static const cardPadding = 22.0;
  static const section = 26.0;
}

class LumeRadii {
  LumeRadii._();

  static const badge = 6.0;
  static const field = 16.0;
  static const listRow = 18.0;
  static const card = 24.0;
  static const sheet = 26.0;
  static const pill = 999.0;
}

class LumeTouch {
  LumeTouch._();

  static const minimum = 44.0;
  static const recommended = 48.0;
  static const primaryAction = 56.0;
  static const twoLineRow = 66.0;
}

# Pruebas de widgets

Esta carpeta contiene **solo pruebas de widgets** de la app Brilliant: pruebas
que construyen pantallas de Flutter con `testWidgets`, tocan botones y celdas
con `WidgetTester` y comprueban lo que se ve.

- Cada archivo termina en `_widget_test.dart`.
- Las pruebas de la lógica del juego (sin pantallas) están en `test/` en la
  raíz del proyecto y se ejecutan con `dart test`.
- Las funciones de ayuda compartidas (dados fijos, tablero casi lleno, sonido
  falso) están en `test/helpers.dart`.

Para ejecutarlas, dentro de la carpeta `mobile`:

```
flutter test test/widgets
```

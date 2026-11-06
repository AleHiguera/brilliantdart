# brilliant_mobile

A new Flutter project.

## Abrir la app en el mismo Chrome que el servidor

El certificado del servidor de cuentas es autofirmado y Chrome recuerda su
aceptación por perfil. `flutter run -d chrome` abre un Chrome aparte con un
perfil temporal, donde la conexión falla. Para usar tu Chrome normal:

- En VS Code, pulsa F5 con **Brilliant (mismo Chrome que el servidor)**.
- En una terminal, dentro de `mobile`, ejecuta
  `flutter run -d web-server --web-port 5055 --web-hostname localhost` y abre
  `http://localhost:5055`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

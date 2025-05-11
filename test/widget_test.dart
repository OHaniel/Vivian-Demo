// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vivian_flutter/main.dart';

void main() {
  testWidgets('Prueba básica de la aplicación', (WidgetTester tester) async {
    // Construir nuestra aplicación y esperar a que se renderice
    await tester.pumpWidget(const MyApp());

    // Verificar que los elementos principales estén presentes
    expect(find.text('Mi Aplicación'), findsOneWidget); // Título de la AppBar
    expect(find.text('Audio'), findsOneWidget); // Botón de audio
    expect(find.text('Repetir'), findsOneWidget); // Botón de repetir
    expect(find.text('Cuenta'),
        findsOneWidget); // Opción de la barra de navegación
    expect(find.text('Traductor'),
        findsOneWidget); // Opción de la barra de navegación
    expect(find.text('Avatar de Unity (animaciones)'),
        findsOneWidget); // Texto del contenedor central

    // Verificar que el campo de texto esté presente
    expect(find.byType(TextField), findsOneWidget);

    // Verificar que los iconos de la barra de navegación estén presentes
    expect(find.byIcon(Icons.account_circle), findsOneWidget);
    expect(find.byIcon(Icons.translate), findsOneWidget);
  });
}

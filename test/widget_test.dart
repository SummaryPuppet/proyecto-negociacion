// This is a basic Flutter widget test for RepartoJusto app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:repartojusto/main.dart';

void main() {
  testWidgets('App starts and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: RepartoJustoApp()));

    // Verify that login screen is shown.
    expect(find.text('RepartoJusto'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
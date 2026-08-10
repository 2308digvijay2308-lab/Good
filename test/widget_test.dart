import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_jarvis/screens/home_screen.dart';

void main() {
  testWidgets('JARVIS renders title, status, mic and send button',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Give async bootstrap (TTS init) a moment to settle.
    await tester.pumpAndSettle();

    // Top navigation bar branding.
    expect(find.text('PROJECT JARVIS'), findsOneWidget);

    // Status node + label.
    expect(find.text('IDLE'), findsOneWidget);

    // Input field + prominent send button.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    // Pulsing mic FAB.
    expect(find.byIcon(Icons.mic_none), findsOneWidget);

    // Welcome bubble appears after bootstrap.
    expect(find.textContaining('I am JARVIS'), findsOneWidget);
  });

  testWidgets('typing a message and pressing send appends a user bubble',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello, JARVIS!');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(find.text('Hello, JARVIS!'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tamjid/core/theme/app_theme.dart';
import 'package:tamjid/providers/auth_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final authProvider = AuthProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: authProvider,
        child: MaterialApp(
          home: Scaffold(
            body: Container(color: AppTheme.slate50),
          ),
        ),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
  });
}

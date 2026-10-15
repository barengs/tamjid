import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tamjid/models/finance.dart';
import 'package:tamjid/models/santri.dart';
import 'package:tamjid/providers/finance_provider.dart';
import 'package:tamjid/screens/finance/mutation_screen.dart';

class MockFinanceProvider extends FinanceProvider {
  final List<AccountMovementItem> mockMovements;

  MockFinanceProvider(this.mockMovements);

  @override
  bool get isLoadingMovements => false;

  @override
  List<AccountMovementItem> get movements => mockMovements;

  @override
  Future<bool> fetchMovements(String nis) async => true;
}

void main() {
  final student = Student(
    id: 1,
    nis: '14400197052',
    firstName: 'Moh. Kholilur',
    lastName: 'Rohman',
    status: 'active',
  );

  final testItems = [
    const AccountMovementItem(
      id: 1,
      accountNumber: '14400197052',
      type: 'debit',
      amount: 200000,
      balanceBefore: 300000,
      balanceAfter: 100000,
      description: 'Pembayaran UCS ( Unit Catering Santri ) [PAY-20261004-WCEPEAWF]',
      createdAt: '2026-10-04T03:00:00Z',
    ),
    const AccountMovementItem(
      id: 2,
      accountNumber: '14400197052',
      type: 'credit',
      amount: 150000,
      balanceBefore: 0,
      balanceAfter: 150000,
      description: 'Top-up tunai via kasir',
      createdAt: '2026-10-04T02:00:00Z',
    ),
  ];

  testWidgets('MutationScreen renders without RenderFlex overflow on narrow screen', (WidgetTester tester) async {
    // Set narrow screen size (360 x 640) matching budget/compact Android phones
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockFinance = MockFinanceProvider(testItems);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<FinanceProvider>.value(
          value: mockFinance,
          child: MutationScreen(student: student),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and content
    expect(find.text('Riwayat Mutasi'), findsOneWidget);
    expect(find.text('Pembayaran UCS ( Unit Catering Santri ) [PAY-20261004-WCEPEAWF]'), findsOneWidget);
    expect(find.text('Top-up tunai via kasir'), findsOneWidget);

    // Verify amounts
    expect(find.text('- Rp 200.000'), findsOneWidget);
    expect(find.text('+ Rp 150.000'), findsOneWidget);

    // Verify no RenderFlex exception was thrown (no zebra overflow)
    expect(tester.takeException(), isNull);
  });
}

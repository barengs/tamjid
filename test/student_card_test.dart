import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamjid/models/santri.dart';
import 'package:tamjid/models/wali_user.dart';
import 'package:tamjid/widgets/guardian_card_widget.dart';
import 'package:tamjid/widgets/student_card_qr.dart';

void main() {
  final student1 = Student(
    id: 1,
    nis: '14400197052',
    firstName: 'Moh. Kholilur',
    lastName: 'Rohman',
    status: 'active',
    bornIn: 'Sampang',
    bornAt: '2013-04-26',
    address: 'Dsn. Diya\'an',
    village: 'Temoran',
  );

  final student2 = Student(
    id: 2,
    nis: '14460197389',
    firstName: 'M. Yusuf',
    lastName: 'D.',
    status: 'active',
    bornIn: 'Pamekasan',
    bornAt: '2014-01-10',
    address: 'Jl. Raya Palengaan',
  );

  testWidgets('Renders single StudentCardQrWidget with web layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: StudentCardQrWidget(student: student1),
            ),
          ),
        ),
      ),
    );

    // Verify student data is rendered
    expect(find.text('MOH. KHOLILUR ROHMAN'), findsOneWidget);
    expect(find.text('14400197052'), findsOneWidget);
    expect(find.text('PERBESAR'), findsOneWidget);
  });

  testWidgets('Renders StackedStudentCardsWidget with stacked front and back cards', (WidgetTester tester) async {
    Student? selectedStudent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: 350,
                child: StackedStudentCardsWidget(
                  students: [student1, student2],
                  activeStudent: student1,
                  onSelect: (s) => selectedStudent = s,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Both students are visible in the stack (one in front, one peeking in back)
    expect(find.text('MOH. KHOLILUR ROHMAN'), findsOneWidget);
    expect(find.text('M. YUSUF D.'), findsWidgets);

    // Tap back card header to switch
    final backCardHeaderFinder = find.byKey(const Key('peeking_back_card_header'));
    expect(backCardHeaderFinder, findsOneWidget);
    await tester.tap(backCardHeaderFinder);
    await tester.pumpAndSettle();

    expect(selectedStudent?.id, 2);
  });

  testWidgets('Swiping front card horizontally triggers transition to next student', (WidgetTester tester) async {
    Student? selectedStudent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: 350,
                child: StackedStudentCardsWidget(
                  students: [student1, student2],
                  activeStudent: student1,
                  onSelect: (s) => selectedStudent = s,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Swipe front card to the left
    final frontCardFinder = find.text('MOH. KHOLILUR ROHMAN');
    await tester.drag(frontCardFinder, const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(selectedStudent?.id, 2);
  });

  testWidgets('Tapping PERBESAR opens the QR enlargement dialog with full content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: StudentCardQrWidget(student: student1),
            ),
          ),
        ),
      ),
    );

    // Tap PERBESAR button on the card
    final perbesarFinder = find.text('PERBESAR');
    expect(perbesarFinder, findsOneWidget);
    await tester.tap(perbesarFinder);
    await tester.pumpAndSettle();

    // Verify dialog is open and visible
    expect(find.text('QR Santri Digital'), findsOneWidget);
    expect(find.text('NIS: 14400197052'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);

    // Close dialog
    final closeButtonFinder = find.byIcon(Icons.close_rounded);
    expect(closeButtonFinder, findsOneWidget);
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // Verify dialog is closed
    expect(find.text('QR Santri Digital'), findsNothing);
  });

  testWidgets('Renders GuardianCardWidget with web layout and opens QR dialog', (WidgetTester tester) async {
    final parent = ParentProfile(
      id: 10,
      userId: 5,
      firstName: 'Moh.',
      lastName: 'Muri',
      nik: '3527141101800014',
      phone: '081234567890',
      parentAs: 'Ayah',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: GuardianCardWidget(
                profile: parent,
                students: [student1, student2],
              ),
            ),
          ),
        ),
      ),
    );

    // Verify parent data is rendered
    expect(find.text('3527141101800014'), findsOneWidget);
    expect(find.text('MOH. MURI'), findsOneWidget);
    expect(find.text('AYAH'), findsOneWidget);
    expect(find.text('081234567890'), findsOneWidget);
    expect(find.textContaining('MOH. KHOLILUR ROHMAN'), findsOneWidget);

    // Tap PERBESAR button on the card
    final perbesarFinder = find.text('PERBESAR');
    expect(perbesarFinder, findsOneWidget);
    await tester.tap(perbesarFinder);
    await tester.pumpAndSettle();

    // Verify dialog is open and visible
    expect(find.text('QR Wali Santri'), findsOneWidget);
    expect(find.text('NIK: 3527141101800014'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);

    // Close dialog
    final closeButtonFinder = find.byIcon(Icons.close_rounded);
    expect(closeButtonFinder, findsOneWidget);
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // Verify dialog is closed
    expect(find.text('QR Wali Santri'), findsNothing);
  });
}


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tamjid/models/wali_user.dart';
import 'package:tamjid/providers/auth_provider.dart';
import 'package:tamjid/screens/profile/edit_profile_screen.dart';

class MockAuthProvider extends AuthProvider {
  final WaliUser? mockUser;

  MockAuthProvider({this.mockUser});

  @override
  WaliUser? get currentUser => mockUser;

  @override
  Future<String?> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    return null;
  }

  @override
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    return null;
  }
}

void main() {
  final testUser = WaliUser(
    id: 10,
    name: 'Ahmad Dahlan',
    email: 'ahmad@example.com',
    username: '3528012345670001',
    profile: ParentProfile(
      id: 5,
      userId: 10,
      firstName: 'Ahmad',
      lastName: 'Dahlan',
      nik: '3528012345670001',
      kk: '3528012345670001',
      email: 'ahmad@example.com',
      phone: '081234567890',
      parentAs: 'ayah',
      gender: 'L',
    ),
  );

  testWidgets('EditProfileScreen renders Data Diri tab with user data', (WidgetTester tester) async {
    final mockAuth = MockAuthProvider(mockUser: testUser);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuth,
          child: const EditProfileScreen(initialTab: 0),
        ),
      ),
    );

    // Verify AppBar and TabBar
    expect(find.text('Edit Profil Wali'), findsOneWidget);
    expect(find.text('Data Diri'), findsOneWidget);
    expect(find.text('Ganti Password'), findsOneWidget);

    // Verify NIK and initial form values
    expect(find.text('NIK: 3528012345670001'), findsOneWidget);
    expect(find.text('Ayah'), findsOneWidget);
    expect(find.text('Ahmad Dahlan'), findsOneWidget);
    expect(find.text('ahmad@example.com'), findsOneWidget);
    expect(find.text('081234567890'), findsOneWidget);

    // Verify submit button
    expect(find.text('Simpan Perubahan'), findsOneWidget);
  });

  testWidgets('EditProfileScreen can switch to Ganti Password tab', (WidgetTester tester) async {
    final mockAuth = MockAuthProvider(mockUser: testUser);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuth,
          child: const EditProfileScreen(initialTab: 1),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Ganti Password fields
    expect(find.text('Password Saat Ini'), findsOneWidget);
    expect(find.text('Password Baru'), findsOneWidget);
    expect(find.text('Konfirmasi Password Baru'), findsOneWidget);
    expect(find.text('Ubah Password'), findsOneWidget);
    expect(find.text('Amankan Akun Anda'), findsOneWidget);
  });

  testWidgets('EditProfileScreen validates empty required fields', (WidgetTester tester) async {
    final mockAuth = MockAuthProvider(mockUser: testUser);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuth,
          child: const EditProfileScreen(initialTab: 0),
        ),
      ),
    );

    // Clear name field
    final nameFinder = find.widgetWithText(TextFormField, 'Ahmad Dahlan');
    await tester.enterText(nameFinder, '');
    await tester.pumpAndSettle();

    // Tap Simpan Perubahan
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    // Verify validation error
    expect(find.text('Nama lengkap tidak boleh kosong'), findsOneWidget);
  });
}

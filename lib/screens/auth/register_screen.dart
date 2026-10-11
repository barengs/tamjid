import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final VoidCallback onRegisterSuccess;

  const RegisterScreen({
    super.key,
    required this.authProvider,
    required this.onRegisterSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nikController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nikController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmController.text,
      nik: _nikController.text,
      phone: _phoneController.text,
    );

    if (!mounted) return;

    if (success) {
      widget.onRegisterSuccess();
    } else {
      final error = widget.authProvider.errorMessage ?? 'Pendaftaran gagal.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.rose500,
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.authProvider.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Pendaftaran Wali Santri'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Buat Akun Wali Baru',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lengkapi informasi dasar untuk mendaftarkan akun wali santri Anda.',
                style: TextStyle(color: AppTheme.slate500, fontSize: 13),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.slate200),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nama Lengkap
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap Wali',
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.slate400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) =>
                            val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Alamat Email',
                          prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.slate400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Email wajib diisi';
                          if (!val.contains('@')) return 'Format email tidak valid';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // NIK (Nomor Induk Kependudukan)
                      TextFormField(
                        controller: _nikController,
                        keyboardType: TextInputType.number,
                        maxLength: 16,
                        decoration: InputDecoration(
                          labelText: 'NIK Wali (Opsional / 16 Digit)',
                          hintText: '3201xxxxxxxxxxxx',
                          counterText: '',
                          prefixIcon: const Icon(Icons.credit_card_outlined, color: AppTheme.slate400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          helperText: 'Diperlukan untuk menghubungkan data santri otomatis',
                          helperMaxLines: 2,
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            if (val.trim().length != 16) {
                              return 'NIK harus terdiri dari 16 digit angka';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(val.trim())) {
                              return 'NIK hanya boleh berisi angka';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nomor HP / WhatsApp
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Nomor HP / WhatsApp (Opsional)',
                          hintText: '0812xxxxxxxx',
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.slate400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            if (!RegExp(r'^[0-9+]+$').hasMatch(val.trim())) {
                              return 'Nomor HP hanya boleh berisi angka';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Kata Sandi
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.slate400),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppTheme.slate400,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Kata sandi wajib diisi';
                          if (val.length < 6) return 'Minimal 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Konfirmasi Kata Sandi
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Ulangi Kata Sandi',
                          prefixIcon: const Icon(Icons.lock_reset, color: AppTheme.slate400),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val != _passwordController.text) {
                            return 'Kata sandi tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.emerald600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Daftarkan Akun',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

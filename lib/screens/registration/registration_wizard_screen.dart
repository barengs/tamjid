import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/registration_provider.dart';

/// Wizard multi-step untuk Pendaftaran Santri Baru (PSB).
/// 4 langkah: Data Wali → Data Calon Santri → Riwayat Pendidikan → Konfirmasi & Kirim.
class RegistrationWizardScreen extends StatefulWidget {
  const RegistrationWizardScreen({super.key});

  @override
  State<RegistrationWizardScreen> createState() =>
      _RegistrationWizardScreenState();
}

class _RegistrationWizardScreenState extends State<RegistrationWizardScreen> {
  int _currentStep = 0;

  // Global Keys per step
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // Controllers Step 1: Wali
  final _waliNamaDepan = TextEditingController();
  final _waliNamaBelakang = TextEditingController();
  final _waliNik = TextEditingController();
  final _waliKk = TextEditingController();
  final _waliTelepon = TextEditingController();
  final _waliEmail = TextEditingController();
  final _waliAlamatKtp = TextEditingController();
  String _waliSebagai = 'Ayah Kandung';

  // Controllers Step 2: Santri
  final _santriNamaDepan = TextEditingController();
  final _santriNamaBelakang = TextEditingController();
  final _santriNisn = TextEditingController();
  final _santriNik = TextEditingController();
  final _santriTempatLahir = TextEditingController();
  final _santriTanggalLahir = TextEditingController();
  final _santriAlamat = TextEditingController();
  String _santriJenisKelamin = 'laki-laki';

  // Controllers Step 3: Pendidikan
  final _sekolahAsal = TextEditingController();
  final _alamatSekolah = TextEditingController();
  final _nomorIjazah = TextEditingController();

  static const _stepTitles = [
    'Data Wali',
    'Data Santri',
    'Pendidikan',
    'Konfirmasi',
  ];

  @override
  void initState() {
    super.initState();
    // Prefill data wali dari akun login jika sudah ada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final profile = auth.currentUser?.profile;
      if (profile != null) {
        if (profile.firstName.isNotEmpty) _waliNamaDepan.text = profile.firstName;
        if (profile.lastName != null) _waliNamaBelakang.text = profile.lastName!;
        if (profile.nik != null) _waliNik.text = profile.nik!;
        if (profile.kk != null) _waliKk.text = profile.kk!;
        if (profile.phone != null) _waliTelepon.text = profile.phone!;
        if (profile.email != null) _waliEmail.text = profile.email!;
        if (profile.address != null) _waliAlamatKtp.text = profile.address!;
      }
    });
  }

  @override
  void dispose() {
    _waliNamaDepan.dispose();
    _waliNamaBelakang.dispose();
    _waliNik.dispose();
    _waliKk.dispose();
    _waliTelepon.dispose();
    _waliEmail.dispose();
    _waliAlamatKtp.dispose();

    _santriNamaDepan.dispose();
    _santriNamaBelakang.dispose();
    _santriNisn.dispose();
    _santriNik.dispose();
    _santriTempatLahir.dispose();
    _santriTanggalLahir.dispose();
    _santriAlamat.dispose();

    _sekolahAsal.dispose();
    _alamatSekolah.dispose();
    _nomorIjazah.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep == 0) {
      if (!_step1Key.currentState!.validate()) return;
      context.read<RegistrationProvider>().saveWali({
        'wali_nama_depan': _waliNamaDepan.text.trim(),
        'wali_nama_belakang': _waliNamaBelakang.text.trim(),
        'wali_nik': _waliNik.text.trim(),
        'wali_kk': _waliKk.text.trim().isNotEmpty ? _waliKk.text.trim() : _waliNik.text.trim(),
        'wali_telepon': _waliTelepon.text.trim(),
        'wali_email': _waliEmail.text.trim(),
        'wali_sebagai': _waliSebagai,
        'wali_alamat_ktp': _waliAlamatKtp.text.trim(),
      });
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (!_step2Key.currentState!.validate()) return;
      context.read<RegistrationProvider>().saveSantri({
        'santri_nama_depan': _santriNamaDepan.text.trim(),
        'santri_nama_belakang': _santriNamaBelakang.text.trim(),
        'santri_nisn': _santriNisn.text.trim(),
        'santri_nik': _santriNik.text.trim(),
        'santri_tempat_lahir': _santriTempatLahir.text.trim(),
        'santri_tanggal_lahir': _santriTanggalLahir.text.trim(),
        'santri_jenis_kelamin': _santriJenisKelamin,
        'santri_alamat': _santriAlamat.text.trim(),
      });
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (!_step3Key.currentState!.validate()) return;
      context.read<RegistrationProvider>().savePendidikan({
        'pendidikan_sekolah_asal': _sekolahAsal.text.trim(),
        'pendidikan_alamat_sekolah': _alamatSekolah.text.trim(),
        'pendidikan_nomor_ijazah': _nomorIjazah.text.trim(),
      });
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit() async {
    final provider = context.read<RegistrationProvider>();
    final ok = await provider.submit();
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const _RegistrationSuccessScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.rose500,
          content: Text(provider.errorMessage ?? 'Pendaftaran gagal.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.select<RegistrationProvider, bool>(
      (p) => p.isSubmitting,
    );

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Pendaftaran Santri Baru'),
      ),
      body: Column(
        children: [
          // Step Header
          _StepIndicator(
            titles: _stepTitles,
            current: _currentStep,
          ),
          const SizedBox(height: 8),

          // Body Step Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _buildCurrentStep(),
            ),
          ),

          // Bottom Bar Navigation
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isSubmitting ? null : _back,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.slate700,
                          side: const BorderSide(color: AppTheme.slate300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Kembali'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.slate300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep == 3
                                  ? 'Kirim Pendaftaran'
                                  : 'Lanjut',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
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
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Wali();
      case 1:
        return _buildStep2Santri();
      case 2:
        return _buildStep3Pendidikan();
      case 3:
        return _buildStep4Konfirmasi();
      default:
        return const SizedBox();
    }
  }

  // --- Step 1: Form Wali ---
  Widget _buildStep1Wali() {
    return Form(
      key: _step1Key,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Langkah 1: Data Wali Santri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Data orang tua atau wali penanggung jawab santri.',
              style: TextStyle(fontSize: 12, color: AppTheme.slate500),
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _waliNamaDepan,
              decoration: const InputDecoration(
                labelText: 'Nama Depan Wali *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _waliNamaBelakang,
              decoration: const InputDecoration(
                labelText: 'Nama Belakang Wali',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _waliNik,
              keyboardType: TextInputType.number,
              maxLength: 16,
              decoration: const InputDecoration(
                labelText: 'NIK Wali (16 Digit) *',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                if (v.trim().length != 16) return 'NIK harus 16 digit';
                return null;
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _waliKk,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nomor Kartu Keluarga (KK)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _waliTelepon,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor HP / WhatsApp',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _waliSebagai,
              decoration: const InputDecoration(
                labelText: 'Hubungan dengan Santri',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Ayah Kandung', child: Text('Ayah Kandung')),
                DropdownMenuItem(value: 'Ibu Kandung', child: Text('Ibu Kandung')),
                DropdownMenuItem(value: 'Wali / Kerabat', child: Text('Wali / Kerabat')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _waliSebagai = val);
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _waliAlamatKtp,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat KTP Wali',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 2: Form Calon Santri ---
  Widget _buildStep2Santri() {
    return Form(
      key: _step2Key,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Langkah 2: Data Calon Santri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Informasi identitas santri baru yang akan didaftarkan.',
              style: TextStyle(fontSize: 12, color: AppTheme.slate500),
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _santriNamaDepan,
              decoration: const InputDecoration(
                labelText: 'Nama Depan Santri *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _santriNamaBelakang,
              decoration: const InputDecoration(
                labelText: 'Nama Belakang Santri',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _santriNisn,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'NISN Santri (10 Digit) *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'NISN wajib diisi' : null,
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _santriJenisKelamin,
              decoration: const InputDecoration(
                labelText: 'Jenis Kelamin',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'laki-laki', child: Text('Laki-laki (Ikhwan)')),
                DropdownMenuItem(value: 'perempuan', child: Text('Perempuan (Akhwat)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _santriJenisKelamin = val);
              },
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _santriTempatLahir,
                    decoration: const InputDecoration(
                      labelText: 'Tempat Lahir',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _santriTanggalLahir,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Tgl Lahir (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _santriAlamat,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat Domisili Santri',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 3: Riwayat Pendidikan ---
  Widget _buildStep3Pendidikan() {
    return Form(
      key: _step3Key,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Langkah 3: Riwayat Pendidikan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Asal sekolah dan ijazah terakhir calon santri.',
              style: TextStyle(fontSize: 12, color: AppTheme.slate500),
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _sekolahAsal,
              decoration: const InputDecoration(
                labelText: 'Nama Sekolah / Madrasah Asal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _alamatSekolah,
              decoration: const InputDecoration(
                labelText: 'Alamat Sekolah Asal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _nomorIjazah,
              decoration: const InputDecoration(
                labelText: 'Nomor Seri Ijazah (Jika Ada)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 4: Konfirmasi ---
  Widget _buildStep4Konfirmasi() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Langkah 4: Konfirmasi Pendaftaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Periksa kembali data pendaftaran sebelum dikirimkan ke panitia PSB.',
            style: TextStyle(fontSize: 12, color: AppTheme.slate500),
          ),
          const SizedBox(height: 18),

          _SummarySection(
            title: 'Wali Santri',
            items: {
              'Nama Wali': '${_waliNamaDepan.text} ${_waliNamaBelakang.text}'.trim(),
              'NIK': _waliNik.text,
              'Sebagai': _waliSebagai,
              'Telepon': _waliTelepon.text.isNotEmpty ? _waliTelepon.text : '-',
            },
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.slate200),
          const SizedBox(height: 14),

          _SummarySection(
            title: 'Calon Santri',
            items: {
              'Nama Santri': '${_santriNamaDepan.text} ${_santriNamaBelakang.text}'.trim(),
              'NISN': _santriNisn.text,
              'Jenis Kelamin': _santriJenisKelamin == 'laki-laki' ? 'Laki-laki' : 'Perempuan',
              'Tempat/Tgl Lahir': '${_santriTempatLahir.text} / ${_santriTanggalLahir.text}',
            },
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.slate200),
          const SizedBox(height: 14),

          _SummarySection(
            title: 'Pendidikan Asal',
            items: {
              'Sekolah Asal': _sekolahAsal.text.isNotEmpty ? _sekolahAsal.text : '-',
              'No Ijazah': _nomorIjazah.text.isNotEmpty ? _nomorIjazah.text : '-',
            },
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.emerald50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.emerald600.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.emerald700, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dengan mengirimkan formulir ini, Anda menyatakan bahwa data yang diisikan adalah benar dan valid.',
                    style: TextStyle(fontSize: 11, color: AppTheme.emerald900, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final Map<String, String> items;

  const _SummarySection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.emerald700,
          ),
        ),
        const SizedBox(height: 8),
        ...items.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    e.key,
                    style: const TextStyle(fontSize: 12, color: AppTheme.slate500),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.slate800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final List<String> titles;
  final int current;

  const _StepIndicator({required this.titles, required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(
        children: List.generate(titles.length, (index) {
          final isActive = index == current;
          final isDone = index < current;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppTheme.emerald600
                        : isActive
                            ? AppTheme.emerald500
                            : AppTheme.slate200,
                  ),
                  alignment: Alignment.center,
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : AppTheme.slate500,
                          ),
                        ),
                ),
                const SizedBox(width: 4),
                if (index < titles.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: isDone ? AppTheme.emerald600 : AppTheme.slate200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _RegistrationSuccessScreen extends StatelessWidget {
  const _RegistrationSuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppTheme.emerald100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: AppTheme.emerald600,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pendaftaran Terkirim!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Data calon santri berhasil dikirim. Panitia PSB akan memverifikasi berkas dan memberi pemberitahuan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.slate500, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Beranda',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

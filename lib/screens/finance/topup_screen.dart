import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/finance.dart';
import '../../models/santri.dart';
import '../../providers/finance_provider.dart';
import '../../providers/student_provider.dart';
import 'topup_history.dart';

/// Form Pengajuan Top-Up Transfer Bank & Upload Bukti Pembayaran
class TopUpScreen extends StatefulWidget {
  final Student? student;

  const TopUpScreen({super.key, this.student});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  PaymentPackageBrief? _selectedPackage;
  File? _proofFile;
  final ImagePicker _picker = ImagePicker();

  final List<int> _presetAmounts = [50000, 100000, 250000, 500000, 1000000];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fp = context.read<FinanceProvider>();
      if (fp.availablePackages.isEmpty) {
        fp.fetchAvailablePackages().then((_) {
          if (mounted && fp.availablePackages.isNotEmpty) {
            setState(() {
              _selectedPackage = fp.availablePackages.first;
              if (_selectedPackage != null && _selectedPackage!.totalAmount > 0) {
                _amountController.text =
                    _selectedPackage!.totalAmount.toInt().toString();
              }
            });
          }
        });
      } else {
        setState(() {
          _selectedPackage = fp.availablePackages.first;
          if (_selectedPackage != null && _selectedPackage!.totalAmount > 0) {
            _amountController.text =
                _selectedPackage!.totalAmount.toInt().toString();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Student? get _targetStudent =>
      widget.student ?? context.read<StudentProvider>().activeStudent;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _proofFile = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppTheme.rose500,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Foto Bukti Transfer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate800,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.emerald50,
                  child: Icon(Icons.camera_alt_rounded,
                      color: AppTheme.emerald600),
                ),
                title: const Text('Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.emerald50,
                  child:
                      Icon(Icons.photo_library_rounded, color: AppTheme.emerald600),
                ),
                title: const Text('Galeri Foto',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    final student = _targetStudent;
    if (student == null || student.nis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih santri terlebih dahulu.'),
          backgroundColor: AppTheme.rose500,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wajib melampirkan foto struk bukti transfer.'),
          backgroundColor: AppTheme.rose500,
        ),
      );
      return;
    }

    final packageId = _selectedPackage?.id ?? 1;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    final result =
        await context.read<FinanceProvider>().submitBankTransferTopUp(
              accountNumber: student.nis,
              paymentPackageId: packageId,
              amount: amount,
              filePath: _proofFile!.path,
              notes: _notesController.text.trim(),
            );

    if (!mounted) return;

    if (result.success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.emerald50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.emerald600,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pengajuan Terkirim!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.slate600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: AppTheme.slate300),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Selesai'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TopUpHistoryScreen(student: student),
                          ),
                        );
                      },
                      child: const Text(
                        'Lihat Status',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.rose500,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _targetStudent;
    final financeProvider = context.watch<FinanceProvider>();
    final packages = financeProvider.availablePackages;

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Top-Up Transfer Bank'),
        actions: [
          IconButton(
            tooltip: 'Riwayat Top-Up',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              if (student != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopUpHistoryScreen(student: student),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Rekening Tujuan Transfer Pesantren
              _buildBankDestinationCard(),
              const SizedBox(height: 20),

              // Kartu Santri Penerima
              if (student != null) _buildStudentBadge(student),
              const SizedBox(height: 20),

              // Pilihan Paket Pembayaran / Alokasi
              const Text(
                'Alokasi Pembayaran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate700,
                ),
              ),
              const SizedBox(height: 6),
              if (financeProvider.isLoadingPackages)
                const LinearProgressIndicator()
              else if (packages.isNotEmpty)
                DropdownButtonFormField<PaymentPackageBrief>(
                  initialValue: _selectedPackage,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.slate200),
                    ),
                  ),
                  items: packages.map((pkg) {
                    return DropdownMenuItem(
                      value: pkg,
                      child: Text(
                        '${pkg.packageName} (${_currencyFormat.format(pkg.totalAmount)})',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPackage = val;
                      if (val != null && val.totalAmount > 0) {
                        _amountController.text =
                            val.totalAmount.toInt().toString();
                      }
                    });
                  },
                ),
              const SizedBox(height: 20),

              // Input Nominal Top-Up
              const Text(
                'Nominal Transfer (Rp)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate900,
                ),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate600,
                  ),
                  hintText: '100000',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.slate200),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nominal transfer wajib diisi';
                  }
                  final num = int.tryParse(val.trim());
                  if (num == null || num < 10000) {
                    return 'Nominal minimal Rp 10.000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Preset Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetAmounts.map((amt) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _amountController.text = amt.toString();
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Text(
                        _currencyFormat.format(amt),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Upload Foto Bukti Struk
              const Text(
                'Bukti Struk Transfer (Wajib)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate700,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _proofFile != null
                          ? AppTheme.emerald600
                          : AppTheme.slate200,
                      width: _proofFile != null ? 1.5 : 1,
                    ),
                  ),
                  child: _proofFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                _proofFile!,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppTheme.emerald50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                color: AppTheme.emerald600,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Sentuh untuk unggah foto struk',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.slate700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mendukung JPG, PNG, atau WEBP maks 2MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.slate400,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Catatan Tambahan (Opsional)
              const Text(
                'Catatan / Nama Pengirim (Opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate700,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Contoh: Transfer atas nama Bpk. Hidayat',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.slate200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.slate200),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: financeProvider.isSubmittingTopUp ? null : _submit,
                  child: financeProvider.isSubmittingTopUp
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Kirim Bukti Pembayaran',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankDestinationCard() {
    const bankName = 'BANK SYARIAH INDONESIA (BSI)';
    const accountNum = '7123456789';
    const accountHolder = 'YAYASAN PESANTREN TAMJIDUL QURAN';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: AppTheme.slate200.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.emerald50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: AppTheme.emerald600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Rekening Resmi Pesantren',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            bankName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                accountNum,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTheme.emerald700,
                  fontFamily: 'monospace',
                ),
              ),
              InkWell(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: accountNum));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nomor rekening disalin ke clipboard.'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.copy_rounded,
                          size: 14, color: AppTheme.emerald600),
                      SizedBox(width: 4),
                      Text(
                        'Salin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.emerald600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'a.n. $accountHolder',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.slate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentBadge(Student student) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded, size: 18, color: AppTheme.slate600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Santri: ${student.fullName} (NIS: ${student.nis})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

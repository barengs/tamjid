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

/// Form Pengajuan Top-Up Transfer Bank & Pembayaran Layanan Pesantren
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

  /// 0 = Top-Up Saldo Uang Saku Bebas (Tanpa Paket)
  /// 1 = Pembayaran Paket Pesantren & Fasilitas Tambahan (Add-On)
  int _serviceType = 0;

  PaymentPackageBrief? _selectedPackage;
  final Set<int> _selectedAddonIds = {};
  File? _proofFile;
  final ImagePicker _picker = ImagePicker();

  final List<int> _presetAmounts = [50000, 100000, 200000, 500000, 1000000];

  @override
  void initState() {
    super.initState();
    _amountController.text = '100000';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final student = _targetStudent;
      final fp = context.read<FinanceProvider>();
      final sId = student?.id;

      fp.fetchAvailablePackages(studentId: sId).then((_) {
        if (mounted && fp.availablePackages.isNotEmpty) {
          setState(() {
            _selectedPackage ??= fp.availablePackages.first;
            if (_serviceType == 1) {
              _recalculateTotalAmount();
            }
          });
        }
      });

      fp.fetchAvailableAddons(studentId: sId);
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

  void _recalculateTotalAmount() {
    final fp = context.read<FinanceProvider>();
    final pkgAmount = _selectedPackage?.totalAmount ?? 0.0;

    double addonTotal = 0.0;
    for (final addon in fp.availableAddons) {
      if (_selectedAddonIds.contains(addon.id)) {
        addonTotal += addon.defaultAmount;
      }
    }

    final total = pkgAmount + addonTotal;
    _amountController.text = total.toInt().toString();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1400,
        maxHeight: 1400,
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
          content: Text('Pilih data santri terlebih dahulu.'),
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

    final isPackage = _serviceType == 1;
    final packageId = isPackage ? _selectedPackage?.id : null;
    final addonIds = isPackage && _selectedAddonIds.isNotEmpty
        ? _selectedAddonIds.toList()
        : null;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    final result = await context.read<FinanceProvider>().submitBankTransferTopUp(
          studentId: student.id,
          accountNumber: student.nis,
          paymentPackageId: packageId,
          addonItemIds: addonIds,
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
    final addons = financeProvider.availableAddons;

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Top-Up & Pembayaran'),
        actions: [
          IconButton(
            tooltip: 'Riwayat Pengajuan',
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
              const SizedBox(height: 16),

              // Santri Penerima
              if (student != null) _buildStudentBadge(student),
              const SizedBox(height: 20),

              // Selector Jenis Layanan
              _buildServiceTypeSelector(),
              const SizedBox(height: 20),

              // Form Sesuai Jenis Layanan
              if (_serviceType == 0)
                _buildSakuTopUpSection()
              else
                _buildPackagePaymentSection(packages, addons, financeProvider),

              const SizedBox(height: 20),

              // Upload Foto Bukti Struk
              _buildProofUploadSection(),
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
                      : Text(
                          _serviceType == 0
                              ? 'Kirim Top-Up Uang Saku'
                              : 'Kirim Pembayaran Paket & Fasilitas',
                          style: const TextStyle(
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

  /// Selector Segmented Button Jenis Layanan
  Widget _buildServiceTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.slate200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_serviceType != 0) {
                  setState(() {
                    _serviceType = 0;
                    _amountController.text = '100000';
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _serviceType == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _serviceType == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 16,
                      color: _serviceType == 0
                          ? AppTheme.emerald700
                          : AppTheme.slate600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Uang Saku Bebas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _serviceType == 0
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _serviceType == 0
                            ? AppTheme.emerald800
                            : AppTheme.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_serviceType != 1) {
                  setState(() {
                    _serviceType = 1;
                    _recalculateTotalAmount();
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _serviceType == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _serviceType == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      size: 16,
                      color: _serviceType == 1
                          ? AppTheme.emerald700
                          : AppTheme.slate600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Paket & Fasilitas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _serviceType == 1
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: _serviceType == 1
                            ? AppTheme.emerald800
                            : AppTheme.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tampilan Khusus Tab 1: Top-Up Uang Saku Santri Bebas
  Widget _buildSakuTopUpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.emerald50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.emerald100),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppTheme.emerald700, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dana top-up ini 100% langsung masuk ke saldo rekening kartu santri untuk kebutuhan harian, jajan di koperasi, dan kasir pesantren.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.emerald900,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
      ],
    );
  }

  /// Tampilan Khusus Tab 2: Pembayaran Paket Pesantren & Add-On Fasilitas
  Widget _buildPackagePaymentSection(
    List<PaymentPackageBrief> packages,
    List<TransactionItemAddon> addons,
    FinanceProvider fp,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilihan Paket Pembayaran',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.slate700,
          ),
        ),
        const SizedBox(height: 6),
        if (fp.isLoadingPackages)
          const LinearProgressIndicator()
        else if (packages.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: const Text('Belum ada paket pembayaran aktif.'),
          )
        else
          DropdownButtonFormField<PaymentPackageBrief>(
            initialValue: _selectedPackage,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedPackage = val;
                _recalculateTotalAmount();
              });
            },
          ),
        const SizedBox(height: 12),

        // Rincian Komponen Paket (Accordion / Box)
        if (_selectedPackage != null && _selectedPackage!.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rincian Komponen Paket:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate800,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(_selectedPackage!.totalAmount),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.emerald700,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                ..._selectedPackage!.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          item.isSaku
                              ? Icons.account_balance_wallet_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 15,
                          color: item.isSaku
                              ? AppTheme.emerald600
                              : AppTheme.slate400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.itemName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (item.isSaku)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Uang Saku',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.emerald700,
                              ),
                            ),
                          ),
                        Text(
                          _currencyFormat.format(item.amount),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.isSaku
                                ? AppTheme.emerald700
                                : AppTheme.slate700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: 18),

        // Fasilitas Tambahan (Add-On Checklist)
        const Text(
          'Fasilitas Tambahan Santri (Opsional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.slate700,
          ),
        ),
        const SizedBox(height: 6),
        if (fp.isLoadingAddons)
          const LinearProgressIndicator()
        else if (addons.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: const Text(
              'Tidak ada fasilitas tambahan opsional.',
              style: TextStyle(fontSize: 12, color: AppTheme.slate500),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(
              children: addons.map((addon) {
                final isChecked = _selectedAddonIds.contains(addon.id);
                return CheckboxListTile(
                  dense: true,
                  value: isChecked,
                  activeColor: AppTheme.emerald600,
                  title: Text(
                    addon.itemName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: addon.description != null &&
                          addon.description!.isNotEmpty
                      ? Text(addon.description!,
                          style: const TextStyle(fontSize: 11))
                      : null,
                  secondary: Text(
                    _currencyFormat.format(addon.defaultAmount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.emerald700,
                    ),
                  ),
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedAddonIds.add(addon.id);
                      } else {
                        _selectedAddonIds.remove(addon.id);
                      }
                      _recalculateTotalAmount();
                    });
                  },
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 18),

        // Total Pembayaran Terkalkulasi
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.slate900, AppTheme.slate800],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL TRANSFER',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Paket + Add-On Terpilih',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
              Text(
                _currencyFormat.format(
                  double.tryParse(_amountController.text) ?? 0,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget Upload Foto Bukti Struk
  Widget _buildProofUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                        'Mendukung JPG, PNG, atau WEBP maks 5MB',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.slate400,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// Kartu Rekening Tujuan Transfer Pesantren
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

  /// Badge Santri Penerima
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

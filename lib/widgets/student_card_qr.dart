import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/api/api_endpoints.dart';
import '../core/theme/app_theme.dart';
import '../models/santri.dart';
import '../models/student_card_setting.dart';

/// Kartu Santri Digital Menggunakan Template Resmi Web Backend
/// (Contoh: https://api.tamjid.or.id/storage/student-card/0UpSH3cU4jBnBP70pP93i8rKcpkm7KawKt8vxtxp.webp)
/// Dengan border-radius ramping (ID Card standard) dan QR Code interaktif.
class StudentCardQrWidget extends StatelessWidget {
  final Student student;
  final StudentCardSetting? cardSetting;
  final VoidCallback? onTap;

  const StudentCardQrWidget({
    super.key,
    required this.student,
    this.cardSetting,
    this.onTap,
  });

  void _showFullQrDialog(BuildContext context) {
    // Menampilkan dialog QR di atas layar menggunakan root navigator
    // agar tidak tertutup, buram, atau tidak muncul di balik elemen lain
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final qrData = student.nis.isNotEmpty
            ? student.nis
            : student.id.toString();
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            color:
                Colors.white, // Memastikan latar dialog benar-benar solid putih
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.qr_code_rounded,
                          color: AppTheme.emerald700,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'QR Santri Digital',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.slate900,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: AppTheme.slate600,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: 260,
                  height: 260,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.slate200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.slate200.withValues(alpha: 0.7),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppTheme.emerald800,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppTheme.slate900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  student.fullName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIS: ${student.nis}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.emerald700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Arahkan QR Code ini ke pemindai pos keamanan, mesin absensi, atau kasir koperasi pesantren.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.slate500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateIndo(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String? _getPhotoUrl(String? photo) {
    if (photo == null || photo.isEmpty) return null;
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }
    return '${ApiEndpoints.smpBase}/storage/$photo';
  }

  @override
  Widget build(BuildContext context) {
    final setting = cardSetting;
    final templateUrl =
        setting?.frontTemplateUrl ?? StudentCardSetting.defaultFrontTemplateUrl;
    final stampUrl = setting?.stampUrl ?? StudentCardSetting.defaultStampUrl;
    final signatureUrl =
        setting?.signatureUrl ?? StudentCardSetting.defaultSignatureUrl;
    final officialName =
        setting?.officialName ?? 'Drs. KH. Muhammad Nur Hidayat, M.Si';

    // Format TTL
    final ttlText = [
      if (student.bornIn != null && student.bornIn!.isNotEmpty)
        student.bornIn!.toUpperCase(),
      if (student.birthDateFormatted != '-')
        student.birthDateFormatted.toUpperCase(),
    ].join(', ');

    // Format Alamat
    final rawAddress = [
      if (student.address != null && student.address!.isNotEmpty)
        student.address!,
      if (student.village != null && student.village!.isNotEmpty)
        student.village!,
    ].join(', ').trim().toUpperCase();
    final addressText = rawAddress.isNotEmpty ? rawAddress : '-';

    final todayFormatted = _formatDateIndo(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        // Rasio kartu debit/ID Card ISO 7810 ID-1: 85.6mm x 53.98mm (~1.5858)
        final cardHeight = cardWidth / (85.6 / 53.98);
        final scale = cardWidth / 360.0;

        return Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            // Border radius ramping sesuai permintaan user
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: AppTheme.slate200, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9.2),
            child: Stack(
              children: [
                // 1. Template Background Gambar Web Backend
                Positioned.fill(
                  child: Image.network(
                    templateUrl,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback visual jika template sedang dimuat atau offline
                      return Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            Container(
                              height: cardHeight * 0.30,
                              color: const Color(0xFF0F3D3E),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12 * scale,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32 * scale,
                                    height: 32 * scale,
                                    decoration: const BoxDecoration(
                                      color: Colors.white24,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.school,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  SizedBox(width: 8 * scale),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'KARTU TANDA SANTRI',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10 * scale,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        'Pondok Pesantren Miftahul Ulum Panyeppen',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 7 * scale,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // 2. Konten Dinamis Sesuai Layout Web DebitStudentCard.tsx
                // Top: 33%, Left: 4.5%, Right: 4.5%, Bottom: 4%
                Positioned(
                  top: cardHeight * 0.325,
                  left: cardWidth * 0.045,
                  right: cardWidth * 0.045,
                  bottom: cardHeight * 0.035,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sisi Kiri: Foto Santri (Rasio 3:4)
                      _buildPhotoWidget(scale, cardWidth),

                      SizedBox(width: 8.0 * scale),

                      // Sisi Kanan: Baris Data Diri + Tanda Tangan + QR Code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Data Baris (NIS, NAMA, TTL, ALAMAT)
                            _buildDataRow('NIS', student.nis, scale),
                            _buildDataRow(
                              'NAMA',
                              student.fullName.toUpperCase(),
                              scale,
                              isBoldName: true,
                            ),
                            _buildDataRow(
                              'TTL',
                              ttlText.isNotEmpty ? ttlText : '-',
                              scale,
                            ),
                            _buildDataRow('ALAMAT', addressText, scale),

                            const Spacer(),

                            // Bagian Bawah: Tanggal, Stempel, TTD & QR Code
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Tanda Tangan & Pengurus
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Pamekasan, $todayFormatted',
                                        style: TextStyle(
                                          fontSize: 6.8 * scale,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1F2937),
                                        ),
                                      ),
                                      SizedBox(height: 1 * scale),
                                      // Layer Stempel & Tanda Tangan
                                      SizedBox(
                                        height: 28 * scale,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.network(
                                              stampUrl,
                                              width: 32 * scale,
                                              height: 32 * scale,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, _, _) =>
                                                  const SizedBox.shrink(),
                                            ),
                                            Image.network(
                                              signatureUrl,
                                              width: 65 * scale,
                                              height: 26 * scale,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, _, _) =>
                                                  const SizedBox.shrink(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        officialName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 6.8 * scale,
                                          fontWeight: FontWeight.w800,
                                          decoration: TextDecoration.underline,
                                          color: const Color(0xFF111827),
                                        ),
                                      ),
                                      Text(
                                        'Ketua Umum Pengurus',
                                        style: TextStyle(
                                          fontSize: 6.0 * scale,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(width: 4 * scale),

                                // QR Code Interaktif
                                GestureDetector(
                                  onTap: () => _showFullQrDialog(context),
                                  child: Container(
                                    padding: EdgeInsets.all(2.0 * scale),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        3.0 * scale,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.slate200,
                                        width: 0.6,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.10,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        QrImageView(
                                          data: student.nis.isNotEmpty
                                              ? student.nis
                                              : student.id.toString(),
                                          version: QrVersions.auto,
                                          size: 42.0 * scale,
                                          padding: EdgeInsets.zero,
                                          eyeStyle: const QrEyeStyle(
                                            eyeShape: QrEyeShape.square,
                                            color: AppTheme.slate900,
                                          ),
                                          dataModuleStyle:
                                              const QrDataModuleStyle(
                                                dataModuleShape:
                                                    QrDataModuleShape.square,
                                                color: AppTheme.slate900,
                                              ),
                                        ),
                                        Text(
                                          'PERBESAR',
                                          style: TextStyle(
                                            fontSize: 5.5 * scale,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.emerald800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoWidget(double scale, double cardWidth) {
    final photoWidth = cardWidth * 0.19;
    final photoHeight = photoWidth * (4.0 / 3.0);
    final photoUrl = _getPhotoUrl(student.photo);

    return Container(
      width: photoWidth,
      height: photoHeight,
      margin: EdgeInsets.only(top: 2 * scale),
      decoration: BoxDecoration(
        color: AppTheme.slate100,
        borderRadius: BorderRadius.circular(2.5 * scale),
        border: Border.all(color: Colors.white, width: 1.2 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1.8 * scale),
        child: photoUrl != null
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPhotoFallback(scale),
              )
            : _buildPhotoFallback(scale),
      ),
    );
  }

  Widget _buildPhotoFallback(double scale) {
    return Container(
      color: AppTheme.slate200,
      alignment: Alignment.center,
      child: Text(
        student.firstName.isNotEmpty ? student.firstName[0].toUpperCase() : 'S',
        style: TextStyle(
          color: AppTheme.slate600,
          fontWeight: FontWeight.w900,
          fontSize: 16 * scale,
        ),
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value,
    double scale, {
    bool isBoldName = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.2 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44.0 * scale,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 8.4 * scale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
                height: 1.2,
              ),
            ),
          ),
          Text(
            ' : ',
            style: TextStyle(
              fontSize: 8.4 * scale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
              height: 1.2,
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isBoldName ? 9.0 * scale : 8.4 * scale,
                fontWeight: isBoldName ? FontWeight.w900 : FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: isBoldName ? 0.2 : 0,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu Santri Bertumpuk dengan Model Slide Depan Belakang (Stacked Cards)
/// Sesuai instruksi:
/// - Jika santri > 1, kartu bertumpuk depan-belakang.
/// - Kartu yang di belakang tampil sebagian (peeking) di bagian atas.
/// - Sentuh atau geser kartu depan untuk beralih santri.
class StackedStudentCardsWidget extends StatefulWidget {
  final List<Student> students;
  final Student? activeStudent;
  final ValueChanged<Student> onSelect;
  final StudentCardSetting? cardSetting;

  const StackedStudentCardsWidget({
    super.key,
    required this.students,
    required this.activeStudent,
    required this.onSelect,
    this.cardSetting,
  });

  @override
  State<StackedStudentCardsWidget> createState() =>
      _StackedStudentCardsWidgetState();
}

class _StackedStudentCardsWidgetState extends State<StackedStudentCardsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  int _targetIndex = 0;
  bool _isAnimating = false;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: -1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onSelect(widget.students[_targetIndex]);
        _animController.reset();
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _currentIndex {
    if (widget.activeStudent == null) return 0;
    final idx = widget.students.indexWhere(
      (s) => s.id == widget.activeStudent!.id,
    );
    return idx >= 0 ? idx : 0;
  }

  void _switchStudent(int newIndex) {
    if (_isAnimating ||
        newIndex == _currentIndex ||
        widget.students.length <= 1) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _isAnimating = true;
      _targetIndex = newIndex;
    });
    _animController.forward();
  }

  void _nextStudent() {
    if (widget.students.length <= 1) return;
    final nextIdx = (_currentIndex + 1) % widget.students.length;
    _switchStudent(nextIdx);
  }

  void _prevStudent() {
    if (widget.students.length <= 1) return;
    final prevIdx =
        (_currentIndex - 1 + widget.students.length) % widget.students.length;
    _switchStudent(prevIdx);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.students.isEmpty) return const SizedBox.shrink();

    // Jika santri hanya 1: Tampilkan kartu tunggal tanpa tumpukan
    if (widget.students.length == 1) {
      return StudentCardQrWidget(
        student: widget.students.first,
        cardSetting: widget.cardSetting,
      );
    }

    final currentStudent = widget.students[_currentIndex];
    final nextIndex = (_currentIndex + 1) % widget.students.length;
    final nextStudent = widget.students[nextIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = cardWidth / (85.6 / 53.98);
        const peekHeight = 26.0; // Sebagian kartu belakang yang tampil di atas
        final totalHeight = cardHeight + peekHeight;

        return Column(
          children: [
            // Container Bertumpuk (Stack Slide Depan Belakang)
            SizedBox(
              width: cardWidth,
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Kartu Belakang (Sebagian Tampil di Atas)
                  Positioned(
                    top: 0,
                    left: 12,
                    right: 12,
                    height: cardHeight,
                    child: GestureDetector(
                      onTap: () => _switchStudent(nextIndex),
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final scale = _isAnimating
                              ? _scaleAnimation.value
                              : 0.96;
                          return Transform.scale(
                            scale: scale,
                            alignment: Alignment.topCenter,
                            child: child,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Tampilan kartu santri di belakang
                              StudentCardQrWidget(
                                student: nextStudent,
                                cardSetting: widget.cardSetting,
                              ),
                              // Baris penanda peeking di bagian atas kartu belakang
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: peekHeight,
                                child: Container(
                                  key: const Key('peeking_back_card_header'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0F3D3E),
                                        Color(0xFF047857),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(10),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.touch_app_rounded,
                                            size: 13,
                                            color: Colors.amberAccent,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            nextStudent.fullName.toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'NIS: ${nextStudent.nis}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          fontSize: 9.5,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w700,
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
                    ),
                  ),

                  // 2. Kartu Depan (Aktif) dengan Gesture Geser (Slide)
                  Positioned(
                    top: peekHeight - 2,
                    left: 0,
                    right: 0,
                    height: cardHeight,
                    child: GestureDetector(
                      onHorizontalDragStart: (_) => _dragOffset = 0.0,
                      onHorizontalDragUpdate: (details) =>
                          _dragOffset += details.delta.dx,
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0.0;
                        if (velocity < -80 || _dragOffset < -40) {
                          // Geser ke kiri -> kartu berikutnya
                          _nextStudent();
                        } else if (velocity > 80 || _dragOffset > 40) {
                          // Geser ke kanan -> kartu sebelumnya
                          _prevStudent();
                        }
                        _dragOffset = 0.0;
                      },
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final slideX = _isAnimating
                              ? _slideAnimation.value * cardWidth
                              : 0.0;
                          final opacity = _isAnimating
                              ? (1.0 - _animController.value).clamp(0.0, 1.0)
                              : 1.0;

                          return Transform.translate(
                            offset: Offset(slideX, 0),
                            child: Opacity(opacity: opacity, child: child),
                          );
                        },
                        child: StudentCardQrWidget(
                          student: currentStudent,
                          cardSetting: widget.cardSetting,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 2),

            // Indikator Paginasi Santri & Tombol Geser Halus
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  color: AppTheme.slate600,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: _prevStudent,
                  tooltip: 'Santri Sebelumnya',
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.students.length, (idx) {
                    final isActive = idx == _currentIndex;
                    return GestureDetector(
                      onTap: () => _switchStudent(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.emerald700
                              : AppTheme.slate300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  color: AppTheme.slate600,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: _nextStudent,
                  tooltip: 'Santri Berikutnya',
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

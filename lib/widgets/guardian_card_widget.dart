import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/api/api_endpoints.dart';
import '../core/theme/app_theme.dart';
import '../models/santri.dart';
import '../models/student_card_setting.dart';
import '../models/wali_user.dart';

/// Widget Kartu Tanda Wali Santri Digital
/// Mengikuti spesifikasi dan layout dari menu setting kartu di web (WaliSantriCard.tsx).
class GuardianCardWidget extends StatelessWidget {
  final ParentProfile profile;
  final List<Student> students;
  final StudentCardSetting? cardSetting;

  const GuardianCardWidget({
    super.key,
    required this.profile,
    this.students = const [],
    this.cardSetting,
  });

  String _formatDateIndo(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String? _getPhotoUrl(String? photo) {
    if (photo == null || photo.isEmpty) return null;
    if (photo.startsWith('http://') || photo.startsWith('https://')) return photo;
    return '${ApiEndpoints.smpBase}/storage/$photo';
  }

  @override
  Widget build(BuildContext context) {
    final setting = cardSetting;
    final templateUrl = setting?.guardianFrontTemplateUrl ?? StudentCardSetting.defaultFrontTemplateUrl;
    final stampUrl = setting?.stampUrl ?? StudentCardSetting.defaultStampUrl;
    final signatureUrl = setting?.signatureUrl ?? StudentCardSetting.defaultSignatureUrl;
    final officialName = setting?.officialName ?? 'Drs. KH. Muhammad Nur Hidayat, M.Si';

    final todayFormatted = _formatDateIndo(DateTime.now());

    // Format Santri String
    final santriListText = students.isNotEmpty
        ? students
            .take(2)
            .map((s) => '${s.fullName} (${s.nis})')
            .join(', ') +
            (students.length > 2 ? ' +${students.length - 2} lainnya' : '')
        : '-';

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
                // 1. Template Background Gambar Web Backend (guardian_front_template)
                Positioned.fill(
                  child: Image.network(
                    templateUrl,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback visual jika template belum diupload / offline
                      return Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            Container(
                              height: cardHeight * 0.30,
                              color: const Color(0xFF0F3D3E),
                              padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32 * scale,
                                    height: 32 * scale,
                                    decoration: const BoxDecoration(
                                      color: Colors.white24,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.badge_rounded, color: Colors.white, size: 18),
                                  ),
                                  SizedBox(width: 8 * scale),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'KARTU TANDA WALI SANTRI',
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

                // 2. Konten Dinamis Sesuai Layout Web WaliSantriCard.tsx
                // Top: 33%, Left: 4.5%, Right: 4.5%, Bottom: 4%
                Positioned(
                  top: cardHeight * 0.325,
                  left: cardWidth * 0.045,
                  right: cardWidth * 0.045,
                  bottom: cardHeight * 0.035,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sisi Kiri: Foto Wali (Rasio 3:4)
                      _buildPhotoWidget(scale, cardWidth),

                      SizedBox(width: 8.0 * scale),

                      // Sisi Kanan: Baris Data Diri + Tanda Tangan + QR Code
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Data Baris (NIK, NAMA, STATUS, TELP, SANTRI)
                            _buildDataRow('NIK', profile.nik ?? '-', scale),
                            _buildDataRow('NAMA', profile.fullName.toUpperCase(), scale, isBoldName: true),
                            _buildDataRow('STATUS', (profile.parentAs ?? 'Wali Santri').toUpperCase(), scale),
                            if (profile.phone != null && profile.phone!.isNotEmpty)
                              _buildDataRow('TELP', profile.phone!, scale),
                            _buildDataRow('SANTRI', santriListText.toUpperCase(), scale),

                            const Spacer(),

                            // Bagian Bawah: Tanggal, Stempel, TTD & QR Code
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Tanda Tangan & Pengurus
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
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
                                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                            ),
                                            Image.network(
                                              signatureUrl,
                                              width: 65 * scale,
                                              height: 26 * scale,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
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

                                // QR Code Interaktif dari NIK Wali
                                GestureDetector(
                                  onTap: () => _showFullQrDialog(context),
                                  child: Container(
                                    padding: EdgeInsets.all(2.0 * scale),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(3.0 * scale),
                                      border: Border.all(color: AppTheme.slate200, width: 0.6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.10),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        QrImageView(
                                          data: (profile.nik != null && profile.nik!.isNotEmpty)
                                              ? profile.nik!
                                              : profile.id.toString(),
                                          version: QrVersions.auto,
                                          size: 42.0 * scale,
                                          padding: EdgeInsets.zero,
                                          eyeStyle: const QrEyeStyle(
                                            eyeShape: QrEyeShape.square,
                                            color: AppTheme.slate900,
                                          ),
                                          dataModuleStyle: const QrDataModuleStyle(
                                            dataModuleShape: QrDataModuleShape.square,
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
    final photoUrl = _getPhotoUrl(profile.photo);

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
        profile.firstName.isNotEmpty ? profile.firstName[0].toUpperCase() : 'W',
        style: TextStyle(
          color: AppTheme.slate600,
          fontWeight: FontWeight.w900,
          fontSize: 16 * scale,
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, double scale, {bool isBoldName = false}) {
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

  void _showFullQrDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) {
        final qrData = (profile.nik != null && profile.nik!.isNotEmpty)
            ? profile.nik!
            : profile.id.toString();

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          backgroundColor: Colors.white,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge_rounded, color: AppTheme.emerald700, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'QR Wali Santri',
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
                  profile.fullName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIK: ${profile.nik ?? '-'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.emerald700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pondok Pesantren Miftahul Ulum Panyeppen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.slate500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


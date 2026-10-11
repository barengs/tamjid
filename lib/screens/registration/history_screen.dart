import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/dio_client.dart';
import '../../core/theme/app_theme.dart';
import 'registration_wizard_screen.dart';

/// Halaman Riwayat Pendaftaran Santri Baru (PSB)
class RegistrationHistoryScreen extends StatefulWidget {
  const RegistrationHistoryScreen({super.key});

  @override
  State<RegistrationHistoryScreen> createState() =>
      _RegistrationHistoryScreenState();
}

class _RegistrationHistoryScreenState extends State<RegistrationHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _registrations = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient().dio;
      final response = await dio.get(ApiEndpoints.smpRegistrationList);

      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        List<dynamic> list = [];
        if (raw is Map && raw['data'] != null) {
          final dataNode = raw['data'];
          if (dataNode is List) {
            list = dataNode;
          } else if (dataNode is Map && dataNode['data'] is List) {
            list = dataNode['data'];
          }
        } else if (raw is List) {
          list = raw;
        }

        setState(() {
          _registrations = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception(response.data?['message'] ?? 'Gagal mengambil riwayat.');
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Terjadi kesalahan jaringan.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Riwayat PSB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _fetchHistory,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.emerald600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Daftar Baru', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistrationWizardScreen(),
            ),
          ).then((_) => _fetchHistory());
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.emerald600,
          strokeWidth: 2.5,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.rose500, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.slate600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchHistory,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_registrations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_edu_rounded, size: 64, color: AppTheme.slate300),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Pendaftaran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Anda belum pernah mengajukan pendaftaran santri baru.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.slate500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: _registrations.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _registrations[index];
        final regNo = item['registration_number']?.toString() ?? '-';
        final firstName = item['first_name']?.toString() ?? '';
        final lastName = item['last_name']?.toString() ?? '';
        final name = '$firstName $lastName'.trim();
        final status = item['status']?.toString() ?? 'pending';
        final createdAt = item['created_at']?.toString();

        return _RegistrationCard(
          registrationNumber: regNo,
          studentName: name.isNotEmpty ? name : 'Calon Santri',
          status: status,
          dateStr: createdAt,
        );
      },
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final String registrationNumber;
  final String studentName;
  final String status;
  final String? dateStr;

  const _RegistrationCard({
    required this.registrationNumber,
    required this.studentName,
    required this.status,
    this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeText;
    String statusLabel;

    switch (status.toLowerCase()) {
      case 'accepted':
      case 'diterima':
        badgeBg = AppTheme.emerald100;
        badgeText = AppTheme.emerald800;
        statusLabel = 'Diterima';
        break;
      case 'rejected':
      case 'ditolak':
        badgeBg = const Color(0xFFFFE4E6);
        badgeText = AppTheme.rose500;
        statusLabel = 'Ditolak';
        break;
      default:
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFF92400E);
        statusLabel = 'Menunggu Verifikasi';
    }

    String formattedDate = '-';
    if (dateStr != null && dateStr!.isNotEmpty) {
      try {
        final dt = DateTime.tryParse(dateStr!);
        if (dt != null) {
          formattedDate = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
        }
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'No: $registrationNumber',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate500,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            studentName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.slate400),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

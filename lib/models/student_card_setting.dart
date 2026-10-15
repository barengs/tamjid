import '../core/api/api_endpoints.dart';

class AuthorizedOfficial {
  final int? id;
  final String firstName;
  final String? lastName;

  AuthorizedOfficial({
    this.id,
    required this.firstName,
    this.lastName,
  });

  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  factory AuthorizedOfficial.fromJson(Map<String, dynamic> json) {
    return AuthorizedOfficial(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString(),
    );
  }
}

class StudentCardSetting {
  final int? id;
  final String? frontTemplate;
  final String? backTemplate;
  final String? guardianFrontTemplate;
  final String? stamp;
  final String? signature;
  final AuthorizedOfficial? authorizedOfficial;
  final bool isActive;

  StudentCardSetting({
    this.id,
    this.frontTemplate,
    this.backTemplate,
    this.guardianFrontTemplate,
    this.stamp,
    this.signature,
    this.authorizedOfficial,
    this.isActive = true,
  });

  static const String defaultFrontTemplateUrl =
      'https://api.tamjid.or.id/storage/student-card/0UpSH3cU4jBnBP70pP93i8rKcpkm7KawKt8vxtxp.webp';
  static const String defaultStampUrl =
      'https://api.tamjid.or.id/storage/student-card/djOuTgiAwD3fqZX0l4vFz05ZgIXGhm6yvurDxiCs.webp';
  static const String defaultSignatureUrl =
      'https://api.tamjid.or.id/storage/student-card/lsz0Z05YTebC3ksaciqReY96lBq5rZdwQxlyj4G9.webp';

  String get frontTemplateUrl {
    if (frontTemplate != null && frontTemplate!.isNotEmpty) {
      if (frontTemplate!.startsWith('http')) return frontTemplate!;
      return '${ApiEndpoints.smpBase}/storage/$frontTemplate';
    }
    return defaultFrontTemplateUrl;
  }

  String get guardianFrontTemplateUrl {
    if (guardianFrontTemplate != null && guardianFrontTemplate!.isNotEmpty) {
      if (guardianFrontTemplate!.startsWith('http')) return guardianFrontTemplate!;
      return '${ApiEndpoints.smpBase}/storage/$guardianFrontTemplate';
    }
    return defaultFrontTemplateUrl;
  }

  String get stampUrl {
    if (stamp != null && stamp!.isNotEmpty) {
      if (stamp!.startsWith('http')) return stamp!;
      return '${ApiEndpoints.smpBase}/storage/$stamp';
    }
    return defaultStampUrl;
  }

  String get signatureUrl {
    if (signature != null && signature!.isNotEmpty) {
      if (signature!.startsWith('http')) return signature!;
      return '${ApiEndpoints.smpBase}/storage/$signature';
    }
    return defaultSignatureUrl;
  }

  String get officialName {
    final name = authorizedOfficial?.fullName ?? '';
    return name.isNotEmpty ? name : 'Drs. KH. Muhammad Nur Hidayat, M.Si';
  }

  factory StudentCardSetting.fromJson(Map<String, dynamic> json) {
    return StudentCardSetting(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      frontTemplate: json['front_template']?.toString(),
      backTemplate: json['back_template']?.toString(),
      guardianFrontTemplate: json['guardian_front_template']?.toString(),
      stamp: json['stamp']?.toString(),
      signature: json['signature']?.toString(),
      authorizedOfficial: json['authorized_official'] is Map<String, dynamic>
          ? AuthorizedOfficial.fromJson(json['authorized_official'] as Map<String, dynamic>)
          : null,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}

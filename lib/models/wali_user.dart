class ParentProfile {
  final int id;
  final int userId;
  final String? code;
  final String firstName;
  final String? lastName;
  final String? nik;
  final String? kk;
  final String? email;
  final String? phone;
  final String? address;
  final String? cardAddress;
  final String? domicileAddress;
  final String? photo;
  final String? parentAs;

  ParentProfile({
    required this.id,
    required this.userId,
    this.code,
    required this.firstName,
    this.lastName,
    this.nik,
    this.kk,
    this.email,
    this.phone,
    this.address,
    this.cardAddress,
    this.domicileAddress,
    this.photo,
    this.parentAs,
  });

  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      code: json['code']?.toString(),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString(),
      nik: json['nik']?.toString(),
      kk: json['kk']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      cardAddress: json['card_address']?.toString(),
      domicileAddress: json['domicile_address']?.toString(),
      photo: json['photo']?.toString(),
      parentAs: json['parent_as']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'code': code,
    'first_name': firstName,
    'last_name': lastName,
    'nik': nik,
    'kk': kk,
    'email': email,
    'phone': phone,
    'address': address,
    'card_address': cardAddress,
    'domicile_address': domicileAddress,
    'photo': photo,
    'parent_as': parentAs,
  };
}

class WaliUser {
  final int id;
  final String name;
  final String email;
  final String username;
  final ParentProfile? profile;

  WaliUser({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.profile,
  });

  factory WaliUser.fromJson(Map<String, dynamic> json) {
    return WaliUser(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profile: json['profile'] != null && json['profile'] is Map<String, dynamic>
          ? ParentProfile.fromJson(json['profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'username': username,
    'profile': profile?.toJson(),
  };
}

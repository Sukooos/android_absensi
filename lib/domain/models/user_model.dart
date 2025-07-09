class User {
  final int id;
  final String name;
  final String email;
  final String? position;
  final String? employeeId;
  final String? phone;
  final String? address;
  final String? profilePicture;
  final Map<String, dynamic>? additionalData;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.position,
    this.employeeId,
    this.phone,
    this.address,
    this.profilePicture,
    this.additionalData,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle different possible ID formats (int or string)
    int userId;
    if (json['id'] is int) {
      userId = json['id'];
    } else if (json['id'] is String) {
      userId = int.tryParse(json['id']) ?? 0;
    } else {
      userId = 0;
    }

    return User(
      id: userId,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      position: json['position']?.toString(),
      employeeId:
          json['employee_id']?.toString() ?? json['employeeId']?.toString(),
      phone: json['phone']?.toString() ?? json['phoneNumber']?.toString(),
      address: json['address']?.toString(),
      profilePicture:
          json['profile_picture']?.toString() ??
          json['profilePicture']?.toString() ??
          json['avatar']?.toString(),
      additionalData: json['additional_data'] is Map
          ? json['additional_data']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'position': position,
      'employee_id': employeeId,
      'phone': phone,
      'address': address,
      'profile_picture': profilePicture,
      'additional_data': additionalData,
    };
  }

  // Copy with method to allow easy updating of user data
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? position,
    String? employeeId,
    String? phone,
    String? address,
    String? profilePicture,
    Map<String, dynamic>? additionalData,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      position: position ?? this.position,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

class User {
  final int? id;
  final String? username;
  final String? role;
  final String? email;
  final String? phone;

  User({
    this.id,
    this.username,
    this.role,
    this.email,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      username: json['username'] as String?,
      role: json['role'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (role != null) 'role': role,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };
  }

  bool get isAdmin => role == 'ADMIN';
}
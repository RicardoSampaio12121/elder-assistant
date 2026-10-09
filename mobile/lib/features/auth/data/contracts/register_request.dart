class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.phoneNumber,
  });

  final String name;
  final String email;
  final String password;
  final String? phoneNumber;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      };
}

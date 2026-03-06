class UserModel {
  final String id;
  final String name;
  final String email;
  final String? apiToken;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.apiToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      apiToken: token,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'api_token': apiToken,
    };
  }
}

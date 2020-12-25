class APIVersion {
  int major, minor;
  APIVersion({this.major, this.minor});
  factory APIVersion.fromJson(Map<String, dynamic> json) {
    return APIVersion(
      major: json['major'],
      minor: json['minor'],
    );
  }
}

class Authorization {
  String username, token;
  bool isAdmin;
  Authorization({this.username, this.token, this.isAdmin});
  factory Authorization.fromJson(Map<String, dynamic> json) {
    return Authorization(
      username: json['username'],
      token: json['token'],
      isAdmin: json['is_admin'],
    );
  }
}

class Credentials {
  String username, password;
  Credentials({this.username, this.password});
  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}

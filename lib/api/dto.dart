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

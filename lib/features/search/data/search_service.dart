class SearchData {
  final String fullName;
  final String email;
  final String phone;

  SearchData({
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory SearchData.fromJson(Map<String, dynamic> json) {
    return SearchData(
      fullName: json['full_name'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      phone: json['phone'] ?? 'N/A',
    );
  }
}

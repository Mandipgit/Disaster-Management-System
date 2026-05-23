class User {
  final String id;
  final String email;
  final String role;
  final String? fullName;
  final String? phone;
  final String? citizenshipNumber;
  final String? citizenshipIssueDate;
  final String? citizenshipIssueDistrict;

  User({
    required this.id, 
    required this.email, 
    required this.role,
    this.fullName,
    this.phone,
    this.citizenshipNumber,
    this.citizenshipIssueDate,
    this.citizenshipIssueDistrict,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      role: json['role'],
      fullName: json['full_name'],
      phone: json['phone'],
      citizenshipNumber: json['citizenship_number'],
      citizenshipIssueDate: json['citizenship_issue_date'],
      citizenshipIssueDistrict: json['citizenship_issue_district'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'full_name': fullName,
      'phone': phone,
      'citizenship_number': citizenshipNumber,
      'citizenship_issue_date': citizenshipIssueDate,
      'citizenship_issue_district': citizenshipIssueDistrict,
    };
  }
}

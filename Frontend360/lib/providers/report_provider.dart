import 'package:flutter/material.dart';
import 'package:disaster360/services/api_service.dart';

class ReportModel {
  final int id;
  final String userId;
  final String disasterType;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String severity;
  final String status;
  int likes;
  int dislikes;
  final String createdAt;

  ReportModel({
    required this.id,
    required this.userId,
    required this.disasterType,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.status,
    required this.likes,
    required this.dislikes,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      disasterType: json['disaster_type'] ?? 'Unknown',
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 'Unknown',
      status: json['status'] ?? 'Pending',
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ReportProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ReportModel> _reports = [];
  bool _isLoading = false;

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;

  Future<void> fetchReports() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('/reports/');
      if (response is List) {
        _reports = response.map((data) => ReportModel.fromJson(data)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching reports: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reactToReport(int reportId, String reactionType) async {
    try {
      final response = await _apiService.post('/reports/$reportId/react?reaction=$reactionType');
      final newLikes = response['likes'];
      final newDislikes = response['dislikes'];

      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index].likes = newLikes;
        _reports[index].dislikes = newDislikes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error reacting to report: $e");
    }
  }
}

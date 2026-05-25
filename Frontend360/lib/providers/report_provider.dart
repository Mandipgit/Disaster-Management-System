import 'package:flutter/material.dart';
import 'package:disaster360/services/api_service.dart';
import 'dart:async';

class ReportModel {
  final int id;
  final String userId;
  final String userName;
  final String disasterType;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String severity;
  final String status;
  final bool verified;
  int likes;
  int dislikes;
  String? userReaction;
  final String createdAt;
  final List<dynamic> submissions;
  final List<String> mediaUrls;

  ReportModel({
    required this.id,
    required this.userId,
    this.userName = 'Unknown',
    required this.disasterType,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.status,
    this.verified = false,
    required this.likes,
    required this.dislikes,
    this.userReaction,
    required this.createdAt,
    this.submissions = const [],
    this.mediaUrls = const [],
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final verified = json['verified'] ?? false;
    return ReportModel(
      id: json['id'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      userName: (json['submissions'] != null && json['submissions'].isNotEmpty) ? json['submissions'][0]['user_name'] ?? 'Unknown' : 'Unknown',
      disasterType: json['disaster_type'] ?? 'Unknown',
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 'Unknown',
      status: json['status'] ?? (verified ? 'Verified' : 'Pending'),
      verified: verified,
      likes: json['likes'] ?? 0,
      dislikes: json['dislikes'] ?? 0,
      userReaction: json['user_reaction'],
      createdAt: json['created_at'] ?? '',
      submissions: json['submissions'] ?? [],
      mediaUrls: (json['media_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class ReportProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ReportModel> _reports = [];
  List<Map<String, dynamic>> _activeRescues = [];
  List<Map<String, dynamic>> _duplicateReports = [];
  bool _isLoading = false;

  List<ReportModel> get reports => _reports;
  List<Map<String, dynamic>> get activeRescues => _activeRescues;
  List<Map<String, dynamic>> get duplicateReports => _duplicateReports;
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

  Future<void> fetchActiveRescues() async {
    try {
      final response = await _apiService.get('/admin/active-rescues');
      if (response is List) {
        _activeRescues = List<Map<String, dynamic>>.from(response);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching active rescues: $e");
    }
  }

  Future<void> fetchDuplicateReports() async {
    try {
      final response = await _apiService.get('/admin/duplicate-reports');
      if (response is List) {
        _duplicateReports = List<Map<String, dynamic>>.from(response);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching duplicate reports: $e");
    }
  }

  Future<void> reactToReport(int reportId, String reactionType) async {
    try {
      final response = await _apiService.post(
        '/reports/$reportId/react?reaction=$reactionType',
      );
      final newLikes = response['likes'];
      final newDislikes = response['dislikes'];
      final newReaction = response['user_reaction'];

      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index].likes = newLikes;
        _reports[index].dislikes = newDislikes;
        _reports[index].userReaction = newReaction;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error reacting to report: $e");
    }
  }

  Future<void> deleteReport(int reportId) async {
    try {
      await _apiService.delete('/reports/$reportId');
      _reports.removeWhere((r) => r.id == reportId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting report: $e');
      rethrow;
    }
  }

  Future<void> deleteReportAdmin(int reportId) async {
    try {
      await _apiService.delete('/admin/reports/$reportId');
      _reports.removeWhere((r) => r.id == reportId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting admin report: $e');
      rethrow;
    }
  }

  Future<void> updateReport(int reportId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/reports/$reportId', body: data);
      // Re-fetch to get updated data
      await fetchReports();
    } catch (e) {
      debugPrint('Error updating report: $e');
      rethrow;
    }
  }

  final Map<int, Timer> _deletionTimers = {};
  Set<int> get pendingDeletions => _deletionTimers.keys.toSet();

  void deleteReportWithInlineUndo(int reportId) {
    if (_deletionTimers.containsKey(reportId)) return;
    
    // Start a 5-second timer
    _deletionTimers[reportId] = Timer(const Duration(seconds: 5), () async {
      _deletionTimers.remove(reportId);
      
      try {
        await _apiService.delete('/admin/reports/$reportId');
        // Successfully deleted, remove from the list
        _reports.removeWhere((r) => r.id == reportId);
        notifyListeners();
      } catch (e) {
        // Deletion failed, revert the pending state so the card shows again
        debugPrint("Failed to delete $reportId: $e");
        notifyListeners();
      }
    });
    
    notifyListeners(); // Rebuild UI to show the inline banner
  }

  void undoInlineDeletion(int reportId) {
    if (_deletionTimers.containsKey(reportId)) {
      _deletionTimers[reportId]?.cancel();
      _deletionTimers.remove(reportId);
      notifyListeners();
    }
  }

  Future<void> undoRejectReport(int reportId) async {
    try {
      await _apiService.put('/admin/reports/$reportId/undo-reject');

      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index] = ReportModel(
          id: _reports[index].id,
          userId: _reports[index].userId,
          disasterType: _reports[index].disasterType,
          title: _reports[index].title,
          description: _reports[index].description,
          latitude: _reports[index].latitude,
          longitude: _reports[index].longitude,
          severity: _reports[index].severity,
          status: 'Pending',
          verified: _reports[index].verified,
          likes: _reports[index].likes,
          dislikes: _reports[index].dislikes,
          createdAt: _reports[index].createdAt,
          submissions: _reports[index].submissions,
          mediaUrls: _reports[index].mediaUrls,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error undoing rejection: $e');
      rethrow;
    }
  }

  Future<void> rejectReport(int reportId) async {
    try {
      await _apiService.put('/admin/reports/$reportId/reject');

      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index] = ReportModel(
          id: _reports[index].id,
          userId: _reports[index].userId,
          disasterType: _reports[index].disasterType,
          title: _reports[index].title,
          description: _reports[index].description,
          latitude: _reports[index].latitude,
          longitude: _reports[index].longitude,
          severity: _reports[index].severity,
          status: 'Rejected',
          verified: _reports[index].verified,
          likes: _reports[index].likes,
          dislikes: _reports[index].dislikes,
          createdAt: _reports[index].createdAt,
          submissions: _reports[index].submissions,
          mediaUrls: _reports[index].mediaUrls,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error rejecting report: $e');
      rethrow;
    }
  }

  Future<void> verifyReport(int reportId) async {
    try {
      await _apiService.put('/admin/reports/$reportId/verify');

      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index] = ReportModel(
          id: _reports[index].id,
          userId: _reports[index].userId,
          disasterType: _reports[index].disasterType,
          title: _reports[index].title,
          description: _reports[index].description,
          latitude: _reports[index].latitude,
          longitude: _reports[index].longitude,
          severity: _reports[index].severity,
          status: 'Verified',
          verified: true,
          likes: _reports[index].likes,
          dislikes: _reports[index].dislikes,
          createdAt: _reports[index].createdAt,
          submissions: _reports[index].submissions,
          mediaUrls: _reports[index].mediaUrls,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error verifying report: $e');
      rethrow;
    }
  }

  Future<void> unverifyReport(int reportId) async {
    try {
      await _apiService.put('/admin/reports/$reportId/unverify');

      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index != -1) {
        _reports[index] = ReportModel(
          id: _reports[index].id,
          userId: _reports[index].userId,
          disasterType: _reports[index].disasterType,
          title: _reports[index].title,
          description: _reports[index].description,
          latitude: _reports[index].latitude,
          longitude: _reports[index].longitude,
          severity: _reports[index].severity,
          status: 'Pending',
          verified: false,
          likes: _reports[index].likes,
          dislikes: _reports[index].dislikes,
          createdAt: _reports[index].createdAt,
          submissions: _reports[index].submissions,
          mediaUrls: _reports[index].mediaUrls,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error unverifying report: $e');
      rethrow;
    }
  }
}

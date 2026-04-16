import re

file_path = 'f:/Disaster Management System/Frontend360/lib/admin/admin_home_dashboard.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Imports
if 'package:provider/provider.dart' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:provider/provider.dart';\nimport 'package:disaster360/services/report_provider.dart';")

# 2. _buildStatCards
old_stat_cards = \"\"\"  Widget _buildStatCards(BuildContext context) {
    final isTabletOrDesktop =
        _Breakpoint.isTablet(context) || _Breakpoint.isDesktop(context);

    final cards = [
      _StatCardData('8', 'Total Reports', AppColors.info),
      _StatCardData('2', 'Unverified', AppColors.danger),
      _StatCardData('2', 'Teams Active', AppColors.success),
    ];\"\"\"

new_stat_cards = \"\"\"  Widget _buildStatCards(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final totalR = reportProvider.reports.length.toString();
    final unverifieds = reportProvider.reports.where((r) => r.status.toLowerCase() == 'pending').length.toString();
    final isTabletOrDesktop =
        _Breakpoint.isTablet(context) || _Breakpoint.isDesktop(context);

    final cards = [
      _StatCardData(totalR, 'Total Reports', AppColors.info),
      _StatCardData(unverifieds, 'Unverified', AppColors.danger),
      _StatCardData('2', 'Teams Active', AppColors.success),
    ];\"\"\"
    
content = content.replace(old_stat_cards, new_stat_cards)

old_pending = \"\"\"  Widget _buildPendingVerification(BuildContext context) {
    final reports = [
      _PendingReportData(
        reportId: 'RPT-00420',
        status: 'Pending',
        submittedAgo: 'Submitted 10 min ago',
        type: 'Flood',
        location: 'Ward 5, Dharan',
        description:
            'River Bagmati overflowed near the old bridge. Water level rising rapidly. Sewers...',
        upvotes: 24,
        downvotes: 2,
        date: 'Mar 17, 2026',
        lat: '26.8065°N',
        lng: '87.2846°E',
        trustScore: 78,
        photoCount: 2,
      ),
      _PendingReportData(
        reportId: 'RPT-00412',
        status: 'Pending',
        submittedAgo: 'Submitted 10 min ago',
        type: 'Flood',
        location: 'Ward 5, Dharan',
        description: 'Severe flooding near bridge area...',
        upvotes: 15,
        downvotes: 3,
        date: 'Mar 10, 2026',
        lat: '26.8060°N',
        lng: '87.2840°E',
        reporter: 'Rajan Thapa',
        trustScore: 88,
        photoCount: 1,
      ),
    ];\"\"\"

new_pending = \"\"\"  Widget _buildPendingVerification(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final reportsModels = reportProvider.reports.where((r) => r.status.toLowerCase() == 'pending').toList();
    final reports = reportsModels.map((m) => _PendingReportData(
      reportId: m.id.length > 8 ? m.id.substring(0, 8) : m.id,
      status: m.status,
      submittedAgo: 'Just now',
      type: m.type,
      location: m.location,
      description: m.description,
      upvotes: m.upvotes,
      downvotes: m.downvotes,
      date: m.date,
      lat: m.latitude.toStringAsFixed(4) + '°N',
      lng: m.longitude.toStringAsFixed(4) + '°E',
      reporter: m.userId.length > 8 ? m.userId.substring(0, 8) : m.userId,
      trustScore: 80,
      photoCount: m.imageUrls.length,
    )).toList();
\"\"\"
content = content.replace(old_pending, new_pending)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done modifying admin dashboard")

import re

file_path = 'f:/Disaster Management System/Frontend360/lib/admin/admin_myreport.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
if 'package:provider/provider.dart' not in content:
    content = content.replace(\"import 'package:flutter/material.dart';\", \"import 'package:flutter/material.dart';\\nimport 'package:provider/provider.dart';\\nimport 'package:disaster360/services/report_provider.dart';\")

# 2. Extract _allReports dummy array
pattern = r\"final List<AdminReportData> _allReports = const \\[[\\s\\S]*?  \\];\"
content = re.sub(pattern, \"\", content)

# 3. Add dynamic _allReports directly inside the build method.
old_build = \"\"\"  @override
  Widget build(BuildContext context) {
    List<AdminReportData> filtered =
        _allReports.where((r) {
          final matchesFilter = _activeFilter == 'All' || r.status == _activeFilter;
          final q = _searchQuery.toLowerCase();
          final matchesSearch =
              r.title.toLowerCase().contains(q) ||
              r.type.toLowerCase().contains(q) ||
              r.location.toLowerCase().contains(q);
          return matchesFilter && matchesSearch;
        }).toList();\"\"\"

new_build = \"\"\"  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final _allReports = provider.reports.map((m) => AdminReportData(
      reportId: m.id.length > 8 ? m.id.substring(0, 8) : m.id,
      status: m.status == 'unverified' ? 'Pending' : m.status.isEmpty ? 'Pending' : (m.status[0].toUpperCase() + m.status.substring(1)),
      type: m.type,
      title: m.type + ' � ' + m.location,
      description: m.description,
      date: m.date,
      location: m.location,
      lat: m.latitude.toStringAsFixed(4) + '�N',
      lng: m.longitude.toStringAsFixed(4) + '�E',
      reporter: m.userId.length > 8 ? m.userId.substring(0, 8) : m.userId,
      trustScore: 80,
      upvotes: m.upvotes,
      downvotes: m.downvotes,
      photoCount: m.imageUrls.length,
    )).toList();

    List<AdminReportData> filtered =
        _allReports.where((r) {
          final matchesFilter = _activeFilter == 'All' || r.status.toLowerCase() == _activeFilter.toLowerCase();
          final q = _searchQuery.toLowerCase();
          final matchesSearch =
              r.title.toLowerCase().contains(q) ||
              r.type.toLowerCase().contains(q) ||
              r.location.toLowerCase().contains(q);
          return matchesFilter && matchesSearch;
        }).toList();\"\"\"

content = content.replace(old_build, new_build)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done modifying admin reports")
 # type: ignore
import os
import re

path = r'f:\Disaster Management System\Frontend360\lib\citizen\citizen_home_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Add a state variable for filter
if 'String _selectedHomeFilter' not in text:
    text = text.replace('class _CitizenHomeScreenState extends State<CitizenHomeScreen> {', '''class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  String _selectedHomeFilter = 'All';
  final List<String> _homeFilters = [
    'All',
    'My Reports',
    'Pending',
    'On Rescue',
    'Verified',
    'Fire',
    'Landslide',
    'Road Block',
    'Flood',
    'Earthquake'
  ];''')

# Define how to filter reports based on the type
filter_logic = '''
  List<ReportModel> _getFilteredReports(BuildContext context) {
    final all = context.watch<ReportProvider>().reports;
    if (_selectedHomeFilter == 'All') return all;
    
    if (_selectedHomeFilter == 'My Reports') {
      final auth = context.read<AuthProvider>();
      return all.where((r) => r.userId == auth.user?.id).toList();
    }
    
    // Status filters
    if (['Pending', 'On Rescue', 'Verified'].contains(_selectedHomeFilter)) {
      if (_selectedHomeFilter == 'On Rescue') {
         return all.where((r) => r.status == 'In Progress').toList();
      }
      return all.where((r) => r.status == _selectedHomeFilter).toList();
    }
    
    // Type filters
    return all.where((r) => r.disasterType == _selectedHomeFilter).toList();
  }
'''

if '_getFilteredReports' not in text:
    text = text.replace('  Widget _buildReportCardsSection(BuildContext context) {', filter_logic + '\n  Widget _buildReportCardsSection(BuildContext context) {')


# Define the filter tabs widget
filter_tabs_widget = '''
  Widget _buildHomeFilterTabs() {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _homeFilters.length,
        itemBuilder: (context, index) {
          final filter = _homeFilters[index];
          final isActive = _selectedHomeFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedHomeFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isActive ? AppColors.orange : AppColors.bgSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isActive
                          ? AppColors.orange
                          : Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
'''

if '_buildHomeFilterTabs' not in text:
    text = text.replace('  // ── REPORT CARDS SECTION', filter_tabs_widget + '\n  // ── REPORT CARDS SECTION')

# Replace the report rendering mapping to use the filtered reports
old_report_render = '''...context.watch<ReportProvider>().reports.map((report) {
          return _ReportCard(
            key: ValueKey(report.id.toString()),
            report: report,
            animationDelay: Duration(milliseconds: 60 * context.watch<ReportProvider>().reports.indexOf(report)),
            onUpvote: () => context.read<ReportProvider>().reactToReport(report.id, 'LIKE'),
            onDownvote: () => context.read<ReportProvider>().reactToReport(report.id, 'DISLIKE'),
          );
        }),'''

new_report_render = '''_buildHomeFilterTabs(),
        ..._getFilteredReports(context).map((report) {
          return _ReportCard(
            key: ValueKey(report.id.toString()),
            report: report,
            animationDelay: Duration(milliseconds: 60 * _getFilteredReports(context).indexOf(report)),
            onUpvote: () => context.read<ReportProvider>().reactToReport(report.id, 'LIKE'),
            onDownvote: () => context.read<ReportProvider>().reactToReport(report.id, 'DISLIKE'),
          );
        }),'''

text = text.replace(old_report_render, new_report_render)

# Inject missing auth import
if "import 'package:disaster360/providers/auth_provider.dart';" not in text:
    text = text.replace("import 'package:disaster360/providers/report_provider.dart';", "import 'package:disaster360/providers/report_provider.dart';\nimport 'package:disaster360/providers/auth_provider.dart';")

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Citizen Home Screen updated with filters.")

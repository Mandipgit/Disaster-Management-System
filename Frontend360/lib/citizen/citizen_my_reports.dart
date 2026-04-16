import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/colors.dart';
import 'package:disaster360/providers/report_provider.dart';
import 'package:disaster360/providers/auth_provider.dart';
import 'package:disaster360/citizen/citizen_report_detail_screen.dart';

class CitizenMyReportsScreen extends StatefulWidget {
  const CitizenMyReportsScreen({super.key});

  @override
  State<CitizenMyReportsScreen> createState() => _CitizenMyReportsScreenState();
}

class _CitizenMyReportsScreenState extends State<CitizenMyReportsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<String> _filters = ['All', 'Pending', 'Verified', 'Closed'];

  List<ReportModel> _getFilteredReports(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id;
    final allReports = context.watch<ReportProvider>().reports;
    final myReports = allReports.where((r) => r.userId == userId).toList();

    return myReports.where((r) {
      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'Closed' &&
              (r.status == 'Controlled' || r.status == 'Rejected')) ||
          r.status == _selectedFilter;

      final matchesSearch =
          _searchQuery.isEmpty ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.id.toString().contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 14),
                _buildFilterButton(context),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child:
                _getFilteredReports(context).isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _getFilteredReports(context).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final report = _getFilteredReports(context)[index];
                        return _ReportCard(
                          data: report,
                          onTap: () {
                            // Optionally navigate to details
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      titleSpacing: 20,
      title: const Text(
        'My Reports',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search reports...',
          hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.white30, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFilterBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list_rounded, color: AppColors.orange, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Filter: ',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                Text(
                  _selectedFilter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (ctx, index) {
                    final filter = _filters[index];
                    final isSelected = filter == _selectedFilter;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? AppColors.orange : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.orange, size: 22)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedFilter = filter);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, color: Colors.white24, size: 56),
          const SizedBox(height: 14),
          const Text(
            'No reports found',
            style: TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel data;
  final VoidCallback onTap;

  const _ReportCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data.createdAt.split("T").first} · #${data.id}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusBadge(status: data.status),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.5,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    _TagChip(label: data.disasterType),
                  ]
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.thumb_up, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '${data.likes}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white60, fontSize: 11),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    
    final lowercaseStatus = status.toLowerCase();
    if (lowercaseStatus.contains('progress')) {
        bg = AppColors.orange.withOpacity(0.18);
        text = AppColors.orange;
    } else if (lowercaseStatus.contains('controlled')) {
        bg = AppColors.success.withOpacity(0.15);
        text = AppColors.success;
    } else if (lowercaseStatus.contains('verified')) {
        bg = AppColors.info.withOpacity(0.18);
        text = AppColors.info;
    } else if (lowercaseStatus.contains('rejected')) {
        bg = AppColors.danger.withOpacity(0.18);
        text = AppColors.danger;
    } else {
        bg = AppColors.warning.withOpacity(0.15);
        text = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: text.withOpacity(0.4), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

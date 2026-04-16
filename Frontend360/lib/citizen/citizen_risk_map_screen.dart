import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/colors.dart';
import 'package:disaster360/providers/report_provider.dart';
import 'package:disaster360/citizen/citizen_report_detail_screen.dart';

class CitizenRiskMapScreen extends StatefulWidget {
  const CitizenRiskMapScreen({super.key});

  @override
  State<CitizenRiskMapScreen> createState() => _CitizenRiskMapScreenState();
}

class _CitizenRiskMapScreenState extends State<CitizenRiskMapScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All Risks';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _filters = [
    'All Risks',
    'Flood',
    'Landslide',
    'Fire',
    'Road Blockage',
  ];

  List<ReportModel> get _filteredIncidents {
    final all = context.watch<ReportProvider>().reports;
    if (_selectedFilter == 'All Risks') return all;
    return all.where((i) => i.disasterType == _selectedFilter).toList();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            _buildFilterButton(context),
            const SizedBox(height: 14),
            _buildMapPlaceholder(),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNearbySection(),
                    const SizedBox(height: 16),
                    _buildRiskZoneBanner(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Risk Map',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder:
                    (_, __) => Opacity(
                      opacity: _pulseAnimation.value,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFilterBottomSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  'Risk Type: ',
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
                  'Select Risk Type',
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

  Widget _buildMapPlaceholder() {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: _GridPainter()),
          Positioned(
            top: 40,
            left: 60,
            child: _RiskZoneOverlay(color: AppColors.danger, size: 100),
          ),
          Positioned(
            top: 80,
            right: 100,
            child: _RiskZoneOverlay(color: AppColors.warning, size: 80),
          ),
          ..._filteredIncidents.map((incident) {
            // Pseudo-random placeholder map layout
            final double mapX = 20.0 + ((incident.id * 15) % 280);
            final double mapY = 20.0 + ((incident.id * 25) % 180);
            final color = incident.severity == 'High' ? AppColors.danger : (incident.severity == 'Medium' ? AppColors.warning : AppColors.info);
            
            return Positioned(
              top: mapY,
              left: mapX,
              child: _MapDot(
                color: color,
                label: incident.disasterType,
              ),
            );
          }),
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.my_location, color: Colors.white70, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbySection() {
    final incidents = _filteredIncidents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NEARBY VERIFIED INCIDENTS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (incidents.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: const Text(
              'No incidents for this filter',
              style: TextStyle(color: Colors.white30, fontSize: 13),
            ),
          )
        else
          ...incidents.map(
            (incident) => _IncidentTile(incident: incident),
          ).toList(),
      ],
    );
  }

  Widget _buildRiskZoneBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(color: Colors.white70, fontSize: 13.5),
          children: [
            TextSpan(text: 'You are currently in a '),
            TextSpan(
              text: 'Medium Risk',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: ' zone · Ward 5'),
          ],
        ),
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  final ReportModel incident;

  const _IncidentTile({required this.incident});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Optionally pass ReportModel directly to a detail screen if converted
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 12),
              decoration: const BoxDecoration(
                color: AppColors.info,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${incident.disasterType} - ${incident.severity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    incident.title,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Text(
              'Alert sent \u2713',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapDot extends StatelessWidget {
  final Color color;
  final String label;
  const _MapDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskZoneOverlay extends StatelessWidget {
  final Color color;
  final double size;
  const _RiskZoneOverlay({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.7,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.04)
          ..strokeWidth = 1;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

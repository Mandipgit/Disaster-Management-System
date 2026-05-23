import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────
//  APP COLORS  (paste from your colors.dart)
//  → Once integrated, remove this block and
//    import 'package:your_app/colors.dart';
// ─────────────────────────────────────────────

class AppColors {
  AppColors._();
  static const Color bgPrimary = Color(0xFF0D1117);
  static const Color bgSurface = Color(0xFF141B27);
  static const Color bgDark = Color(0xFF1A2030);
  static const Color border = Color(0xFF1E2A3A);
  static const Color orange = Color(0xFFFF6B2B);
  static const Color danger = Color(0xFFFF3B3B);
  static const Color warning = Color(0xFFFFB800);
  static const Color success = Color(0xFF00D4AA);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color info = Color(0xFF4D9EFF);
  static const Color textLight = Colors.white;
  static const Color textMuted = Colors.white38;
}

// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────

enum DisasterType { flood, landslide, roadblock, earthquake, fire }

enum SeverityLevel { high, moderate, low }

class DisasterIncident {
  final String id;
  final String title;
  final String description;
  final DisasterType type;
  final SeverityLevel severity;
  final LatLng location;
  final DateTime reportedAt;
  final String reportedBy;
  final String district;
  final String? assignedTeam;
  final int? affectedPeople;
  final String? contactNumber;
  bool isControlled;

  DisasterIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.location,
    required this.reportedAt,
    required this.reportedBy,
    required this.district,
    this.assignedTeam,
    this.affectedPeople,
    this.contactNumber,
    this.isControlled = false,
  });
}

// ─────────────────────────────────────────────
//  DISASTER STYLE HELPERS  (uses AppColors)
// ─────────────────────────────────────────────

class DisasterStyle {
  static Color colorForType(DisasterType t) {
    switch (t) {
      case DisasterType.flood:
        return AppColors.info;
      case DisasterType.landslide:
        return AppColors.warning;
      case DisasterType.roadblock:
        return AppColors.orange;
      case DisasterType.earthquake:
        return AppColors.danger;
      case DisasterType.fire:
        return const Color(0xFFFF6F00);
    }
  }

  static Color zoneColor(DisasterType t) => colorForType(t).withOpacity(0.16);

  static Color severityColor(SeverityLevel s) {
    switch (s) {
      case SeverityLevel.high:
        return AppColors.danger;
      case SeverityLevel.moderate:
        return AppColors.warning;
      case SeverityLevel.low:
        return AppColors.success;
    }
  }

  static IconData iconForType(DisasterType t) {
    switch (t) {
      case DisasterType.flood:
        return Icons.water_rounded;
      case DisasterType.landslide:
        return Icons.terrain_rounded;
      case DisasterType.roadblock:
        return Icons.block_rounded;
      case DisasterType.earthquake:
        return Icons.crisis_alert_rounded;
      case DisasterType.fire:
        return Icons.local_fire_department_rounded;
    }
  }

  static String labelForType(DisasterType t) {
    switch (t) {
      case DisasterType.flood:
        return 'Flood';
      case DisasterType.landslide:
        return 'Landslide';
      case DisasterType.roadblock:
        return 'Road Block';
      case DisasterType.earthquake:
        return 'Earthquake';
      case DisasterType.fire:
        return 'Fire';
    }
  }
}

// ─────────────────────────────────────────────
//  NEPAL-WIDE DEMO INCIDENTS  (20 incidents)
// ─────────────────────────────────────────────

final List<DisasterIncident> demoIncidents = [];

// ─────────────────────────────────────────────
//  NEPAL BOUNDS & CENTER
// ─────────────────────────────────────────────

const LatLng _nepalCenter = LatLng(28.2, 83.9);
const LatLng _nepalSW = LatLng(26.347, 80.052);
const LatLng _nepalNE = LatLng(30.448, 88.201);

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────

class DisasterMapScreen extends StatefulWidget {
  const DisasterMapScreen({super.key});
  @override
  State<DisasterMapScreen> createState() => _DisasterMapScreenState();
}

class _DisasterMapScreenState extends State<DisasterMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  DisasterType? _activeFilter;
  DisasterIncident? _selectedIncident;
  bool _showLegend = false;
  bool _showZones = true;
  bool _isSatellite = false;

  List<DisasterIncident> _incidents = List.from(demoIncidents);

  late AnimationController _pulseCtrl;
  late AnimationController _panelCtrl;
  late Animation<double> _panelAnim;

  int get _highCount =>
      _incidents
          .where((i) => i.severity == SeverityLevel.high && !i.isControlled)
          .length;
  int get _moderateCount =>
      _incidents
          .where((i) => i.severity == SeverityLevel.moderate && !i.isControlled)
          .length;
  int get _activeCount => _incidents.where((i) => !i.isControlled).length;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _panelAnim = CurvedAnimation(
      parent: _panelCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _panelCtrl.dispose();
    super.dispose();
  }

  List<DisasterIncident> get _filtered =>
      _incidents.where((i) {
        if (_activeFilter != null && i.type != _activeFilter) return false;
        return true;
      }).toList();

  void _selectIncident(DisasterIncident inc) {
    setState(() => _selectedIncident = inc);
    _panelCtrl.forward();
    _mapController.move(inc.location, 11.5);
  }

  void _closePanel() {
    _panelCtrl.reverse().then((_) => setState(() => _selectedIncident = null));
  }

  // ─── BUILD ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(),
          _buildStatsStrip(),
          _buildFilterBar(),
          if (_showLegend) _buildLegend(),
          _buildMapControls(),
          if (_selectedIncident != null) _buildDetailPanel(),
          _buildReportFAB(),
        ],
      ),
    );
  }

  // ─── MAP ─────────────────────────────────────

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _nepalCenter,
        initialZoom: 7.0,
        minZoom: 6.5,
        maxZoom: 18,
        cameraConstraint: CameraConstraint.containCenter(
          bounds: LatLngBounds(_nepalSW, _nepalNE),
        ),
        onTap: (_, __) {
          if (_selectedIncident != null) _closePanel();
          if (_showLegend) setState(() => _showLegend = false);
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              _isSatellite
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.disaster360.app',
          maxZoom: 18,
        ),
        if (_showZones) _buildZoneLayer(),
        MarkerLayer(markers: _buildMarkers()),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap:
                  () => launchUrl(
                    Uri.parse('https://openstreetmap.org/copyright'),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  CircleLayer _buildZoneLayer() {
    return CircleLayer(
      circles:
          _filtered.map((inc) {
            final radius =
                inc.severity == SeverityLevel.high
                    ? 18000.0
                    : inc.severity == SeverityLevel.moderate
                    ? 11000.0
                    : 6000.0;
            return CircleMarker(
              point: inc.location,
              radius: radius,
              useRadiusInMeter: true,
              color: DisasterStyle.zoneColor(inc.type),
              borderColor: DisasterStyle.colorForType(
                inc.type,
              ).withOpacity(0.4),
              borderStrokeWidth: 1.5,
            );
          }).toList(),
    );
  }

  List<Marker> _buildMarkers() {
    return _filtered.map((inc) {
      return Marker(
        point: inc.location,
        width: 54,
        height: 54,
        child: GestureDetector(
          onTap: () => _selectIncident(inc),
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) {
              final pulse =
                  (inc.severity == SeverityLevel.high && !inc.isControlled)
                      ? (0.85 + 0.15 * sin(_pulseCtrl.value * 2 * pi))
                      : 1.0;
              return Transform.scale(scale: pulse, child: child);
            },
            child: _MarkerWidget(
              incident: inc,
              isSelected: _selectedIncident?.id == inc.id,
            ),
          ),
        ),
      );
    }).toList();
  }

  // ─── TOP BAR ─────────────────────────────────

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgPrimary.withOpacity(0.97),
              AppColors.bgPrimary.withOpacity(0.0),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Row(
              children: [
                _GlassBtn(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISASTER360',
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const Text(
                        'Nepal Risk Map',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // LIVE indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      _PulseDot(color: AppColors.danger),
                      const SizedBox(width: 5),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _GlassBtn(
                  icon: Icons.layers_rounded,
                  onTap: () => setState(() => _showLegend = !_showLegend),
                  active: _showLegend,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── STATS STRIP ─────────────────────────────

  Widget _buildStatsStrip() {
    final top = MediaQuery.of(context).padding.top + 76;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: Row(
        children: [
          _StatPill(
            label: 'Active',
            value: '$_activeCount',
            color: AppColors.info,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(width: 8),
          _StatPill(
            label: 'High',
            value: '$_highCount',
            color: AppColors.danger,
            icon: Icons.priority_high_rounded,
          ),
          const SizedBox(width: 8),
          _StatPill(
            label: 'Moderate',
            value: '$_moderateCount',
            color: AppColors.warning,
            icon: Icons.remove_circle_outline_rounded,
          ),
          const Spacer(),
          // Satellite toggle
          GestureDetector(
            onTap: () => setState(() => _isSatellite = !_isSatellite),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color:
                    _isSatellite
                        ? AppColors.info.withOpacity(0.15)
                        : Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      _isSatellite
                          ? AppColors.info.withOpacity(0.4)
                          : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSatellite
                        ? Icons.satellite_alt_rounded
                        : Icons.map_rounded,
                    color: _isSatellite ? AppColors.info : Colors.white54,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isSatellite ? 'Satellite' : 'Standard',
                    style: TextStyle(
                      color: _isSatellite ? AppColors.info : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FILTER BAR ──────────────────────────────

  Widget _buildFilterBar() {
    final top = MediaQuery.of(context).padding.top + 122;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _FilterChip(
              label: 'All',
              icon: Icons.public_rounded,
              color: Colors.white,
              selected: _activeFilter == null,
              onTap: () => setState(() => _activeFilter = null),
              count: _activeCount,
            ),
            const SizedBox(width: 8),
            ...DisasterType.values.map(
              (t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: DisasterStyle.labelForType(t),
                  icon: DisasterStyle.iconForType(t),
                  color: DisasterStyle.colorForType(t),
                  selected: _activeFilter == t,
                  onTap:
                      () => setState(() {
                        _activeFilter = _activeFilter == t ? null : t;
                      }),
                  count:
                      _incidents
                          .where((i) => i.type == t && !i.isControlled)
                          .length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LEGEND ──────────────────────────────────

  Widget _buildLegend() {
    final top = MediaQuery.of(context).padding.top + 76;
    return Positioned(
      top: top,
      right: 16,
      child: Container(
        width: 215,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface.withOpacity(0.97),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'LEGEND',
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _showLegend = false),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...DisasterType.values.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: DisasterStyle.colorForType(t).withOpacity(0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DisasterStyle.colorForType(t).withOpacity(0.4),
                        ),
                      ),
                      child: Icon(
                        DisasterStyle.iconForType(t),
                        color: DisasterStyle.colorForType(t),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DisasterStyle.labelForType(t),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: AppColors.border, height: 16),
            const Text(
              'Severity',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
            const SizedBox(height: 8),
            ...[
              SeverityLevel.high,
              SeverityLevel.moderate,
              SeverityLevel.low,
            ].map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: DisasterStyle.severityColor(s),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.name[0].toUpperCase() + s.name.substring(1),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: AppColors.border, height: 16),
            _LegendToggle(
              label: 'Affected Zones',
              value: _showZones,
              onChanged: (v) => setState(() => _showZones = v),
              activeColor: AppColors.orange,
            ),
          ],
        ),
      ),
    );
  }

  // ─── MAP CONTROLS ────────────────────────────

  Widget _buildMapControls() {
    return Positioned(
      bottom: 110,
      right: 16,
      child: Column(
        children: [
          _GlassBtn(
            icon: Icons.add_rounded,
            onTap:
                () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom + 1,
                ),
          ),
          const SizedBox(height: 8),
          _GlassBtn(
            icon: Icons.remove_rounded,
            onTap:
                () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom - 1,
                ),
          ),
          const SizedBox(height: 8),
          _GlassBtn(
            icon: Icons.my_location_rounded,
            onTap: () => _mapController.move(_nepalCenter, 7.0),
          ),
          const SizedBox(height: 8),
          _GlassBtn(icon: Icons.list_rounded, onTap: _showIncidentsList),
        ],
      ),
    );
  }

  // ─── DETAIL PANEL ────────────────────────────

  Widget _buildDetailPanel() {
    final inc = _selectedIncident!;
    final color = DisasterStyle.colorForType(inc.type);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_panelAnim),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: Icon(
                            DisasterStyle.iconForType(inc.type),
                            color: color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inc.title,
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _SeverityBadge(severity: inc.severity),
                                  const SizedBox(width: 6),
                                  inc.isControlled
                                      ? _Badge(
                                        label: 'Controlled',
                                        color: AppColors.success,
                                      )
                                      : _Badge(
                                        label: 'Active',
                                        color: AppColors.danger,
                                      ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      inc.district,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _closePanel,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white54,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Description
                    Text(
                      inc.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Info grid row 1
                    Row(
                      children: [
                        _InfoTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Reported by',
                          value: inc.reportedBy,
                        ),
                        const SizedBox(width: 10),
                        _InfoTile(
                          icon: Icons.access_time_rounded,
                          label: 'Reported',
                          value: _timeAgo(inc.reportedAt),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Info grid row 2
                    Row(
                      children: [
                        if (inc.affectedPeople != null) ...[
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.people_alt_outlined,
                              label: 'Affected',
                              value: '~${inc.affectedPeople} people',
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (inc.assignedTeam != null)
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.groups_rounded,
                              label: 'Assigned team',
                              value: inc.assignedTeam!,
                            ),
                          )
                        else
                          Expanded(
                            child: _InfoTile(
                              icon: Icons.location_on_outlined,
                              label: 'District',
                              value: inc.district,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            label: 'Navigate',
                            icon: Icons.navigation_rounded,
                            color: AppColors.info,
                            onTap:
                                () => launchUrl(
                                  Uri.parse(
                                    'https://www.google.com/maps/dir/?api=1&destination=${inc.location.latitude},${inc.location.longitude}',
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (inc.contactNumber != null) ...[
                          Expanded(
                            child: _ActionBtn(
                              label: 'Call Office',
                              icon: Icons.call_rounded,
                              color: AppColors.success,
                              onTap:
                                  () => launchUrl(
                                    Uri.parse('tel:${inc.contactNumber}'),
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: _ActionBtn(
                            label: inc.isControlled ? 'Reopen' : 'Controlled',
                            icon:
                                inc.isControlled
                                    ? Icons.undo_rounded
                                    : Icons.check_circle_outline_rounded,
                            color:
                                inc.isControlled
                                    ? AppColors.warning
                                    : AppColors.successGreen,
                            onTap: () {
                              setState(
                                () => inc.isControlled = !inc.isControlled,
                              );
                              _closePanel();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  // ─── INCIDENTS LIST ───────────────────────────

  void _showIncidentsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.92,
            minChildSize: 0.3,
            builder:
                (_, ctrl) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'All Incidents',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${_filtered.length} incidents',
                                style: TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: ctrl,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _filtered.length,
                          separatorBuilder:
                              (_, __) =>
                                  Divider(color: AppColors.border, height: 1),
                          itemBuilder: (_, i) {
                            final inc = _filtered[i];
                            final color = DisasterStyle.colorForType(inc.type);
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: color.withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  DisasterStyle.iconForType(inc.type),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                inc.title,
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    _SeverityBadge(severity: inc.severity),
                                    const SizedBox(width: 6),
                                    Text(
                                      inc.district,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '· ${_timeAgo(inc.reportedAt)}',
                                      style: const TextStyle(
                                        color: Colors.white24,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing:
                                  inc.isControlled
                                      ? Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.success,
                                        size: 18,
                                      )
                                      : const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white24,
                                        size: 14,
                                      ),
                              onTap: () {
                                Navigator.pop(ctx);
                                _selectIncident(inc);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  // ─── REPORT FAB ──────────────────────────────

  Widget _buildReportFAB() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 20,
      child: GestureDetector(
        onTap: _showReportDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.danger, Color(0xFFB71C1C)],
            ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withOpacity(0.4),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.add_alert_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Report Incident',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── REPORT DIALOG ───────────────────────────

  void _showReportDialog() {
    DisasterType selType = DisasterType.flood;
    SeverityLevel selSeverity = SeverityLevel.moderate;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final districtCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Report New Incident',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Type
                          _FormLabel('Disaster Type'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                DisasterType.values.map((t) {
                                  final sel = selType == t;
                                  final c = DisasterStyle.colorForType(t);
                                  return GestureDetector(
                                    onTap: () => setS(() => selType = t),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            sel
                                                ? c.withOpacity(0.18)
                                                : Colors.white.withOpacity(
                                                  0.05,
                                                ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              sel
                                                  ? c
                                                  : Colors.white.withOpacity(
                                                    0.1,
                                                  ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            DisasterStyle.iconForType(t),
                                            color: sel ? c : Colors.white38,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            DisasterStyle.labelForType(t),
                                            style: TextStyle(
                                              color:
                                                  sel
                                                      ? Colors.white
                                                      : Colors.white54,
                                              fontSize: 12,
                                              fontWeight:
                                                  sel
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),

                          const SizedBox(height: 16),
                          _FormLabel('Severity'),
                          const SizedBox(height: 8),
                          Row(
                            children:
                                [
                                  SeverityLevel.low,
                                  SeverityLevel.moderate,
                                  SeverityLevel.high,
                                ].map((s) {
                                  final sel = selSeverity == s;
                                  final c = DisasterStyle.severityColor(s);
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setS(() => selSeverity = s),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              sel
                                                  ? c.withOpacity(0.18)
                                                  : Colors.white.withOpacity(
                                                    0.05,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                sel
                                                    ? c
                                                    : Colors.white.withOpacity(
                                                      0.1,
                                                    ),
                                          ),
                                        ),
                                        child: Text(
                                          s.name[0].toUpperCase() +
                                              s.name.substring(1),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: sel ? c : Colors.white38,
                                            fontSize: 12,
                                            fontWeight:
                                                sel
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),

                          const SizedBox(height: 16),
                          _FormLabel('Incident Title'),
                          const SizedBox(height: 8),
                          _DarkField(
                            controller: titleCtrl,
                            hint: 'e.g. Bagmati River Overflow',
                          ),
                          const SizedBox(height: 12),
                          _FormLabel('District'),
                          const SizedBox(height: 8),
                          _DarkField(
                            controller: districtCtrl,
                            hint: 'e.g. Kathmandu',
                          ),
                          const SizedBox(height: 12),
                          _FormLabel('Description'),
                          const SizedBox(height: 8),
                          _DarkField(
                            controller: descCtrl,
                            hint: 'Describe the situation, affected people…',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: () {
                                if (titleCtrl.text.trim().isEmpty) return;
                                final center = _mapController.camera.center;
                                setState(() {
                                  _incidents.add(
                                    DisasterIncident(
                                      id:
                                          DateTime.now().millisecondsSinceEpoch
                                              .toString(),
                                      title: titleCtrl.text.trim(),
                                      description:
                                          descCtrl.text.trim().isEmpty
                                              ? 'No description provided.'
                                              : descCtrl.text.trim(),
                                      type: selType,
                                      severity: selSeverity,
                                      location: center,
                                      reportedAt: DateTime.now(),
                                      reportedBy: 'Citizen Report',
                                      district:
                                          districtCtrl.text.trim().isEmpty
                                              ? 'Unknown'
                                              : districtCtrl.text.trim(),
                                    ),
                                  );
                                });
                                Navigator.pop(ctx);
                                _selectIncident(_incidents.last);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.danger,
                                      Color(0xFFB71C1C),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text(
                                  'Submit Report',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _MarkerWidget extends StatelessWidget {
  final DisasterIncident incident;
  final bool isSelected;
  const _MarkerWidget({required this.incident, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final color = DisasterStyle.colorForType(incident.type);
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isSelected)
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
          ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: incident.isControlled ? const Color(0xFF3A3A3A) : color,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              BoxShadow(
                color: (incident.isControlled ? Colors.grey : color)
                    .withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            incident.isControlled
                ? Icons.check_rounded
                : DisasterStyle.iconForType(incident.type),
            color: Colors.white,
            size: 19,
          ),
        ),
        if (!incident.isControlled)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: DisasterStyle.severityColor(incident.severity),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _GlassBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:
              active
                  ? AppColors.orange.withOpacity(0.15)
                  : Colors.black.withOpacity(0.48),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                active
                    ? AppColors.orange.withOpacity(0.4)
                    : Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8),
          ],
        ),
        child: Icon(
          icon,
          color: active ? AppColors.orange : Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? color.withOpacity(0.18)
                  : Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.12),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : Colors.white38, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final SeverityLevel severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = DisasterStyle.severityColor(severity);
    final label = severity.name[0].toUpperCase() + severity.name.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white38, size: 11),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  const _LegendToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.4, end: 1.0).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder:
          (_, __) => Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(_a.value),
              shape: BoxShape.circle,
            ),
          ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12));
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _DarkField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textLight, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}


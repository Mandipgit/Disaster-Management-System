import 'dart:async';
import 'package:disaster360/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:disaster360/providers/report_provider.dart';
import 'package:disaster360/services/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:disaster360/services/supabase_storage_service.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class ReportDisasterScreen extends StatefulWidget {
  const ReportDisasterScreen({super.key});

  @override
  State<ReportDisasterScreen> createState() => _ReportDisasterScreenState();
}

class _ReportDisasterScreenState extends State<ReportDisasterScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ── Form state ─────────────────────────────────────────────────────────────
  String _selectedType = 'Flood';
  int _severityLevel = 0; // 0 = not selected
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final List<String> _uploadedPhotos = []; // Simulated file paths
  bool _isSubmitting = false;

  // Custom Duplicate Detection State
  bool _isDuplicateCheckRunning = false;
  bool _duplicateCheckDone = false;
  bool _isDuplicate = false; // true = merged (match), false = brand new
  int _duplicateStep = 0; // 0 to 3

  // GPS Location State
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _locationServiceEnabled = false;
  LocationPermission _locationPermission = LocationPermission.denied;

  late AnimationController _hourglassController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hourglassController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _checkLocationAndStartStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _hourglassController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationAndStartStream();
    }
  }

  Future<void> _checkLocationAndStartStream() async {
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_locationServiceEnabled) {
      // Ask user to enable it
      _showLocationServiceDialog();
      return;
    }

    _locationPermission = await Geolocator.checkPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
      if (_locationPermission == LocationPermission.denied) {
        if (!mounted) return;
        _snack('Location permission denied.');
        return;
      }
    }

    if (_locationPermission == LocationPermission.deniedForever) {
      if (!mounted) return;
      _snack('Location permissions are permanently denied.');
      return;
    }

    // Start stream
    _startLocationStream();
  }

  void _startLocationStream() {
    _positionStreamSubscription?.cancel();

    // Fetch initial immediately
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((pos) {
          if (mounted) {
            setState(() {
              _currentPosition = pos;
            });
          }
        })
        .catchError((e) => debugPrint("Error fetching location: $e"));

    // On Desktop platforms, getPositionStream has a known issue where it calls 
    // the platform channel on a background thread, causing a crash.
    // Since we already fetched the current location above, we can just return.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  void _showLocationServiceDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.bgSurface,
            title: const Text(
              'Location Disabled',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Please enable location services to report a disaster accurately.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Geolocator.openLocationSettings();
                },
                child: const Text(
                  'Enable',
                  style: TextStyle(color: AppColors.orange),
                ),
              ),
            ],
          ),
    );
  }

  final List<String> _disasterTypes = [
    'Flood',
    'Landslide',
    'Fire',
    'Road Blockage',
    'Earthquake',
  ];

  // Severity metadata
  static const List<_SeverityMeta> _severityLevels = [
    _SeverityMeta(
      level: 1,
      label: 'Low',
      description: 'Minor incident, no immediate danger to life or property.',
      color: Color(0xFF4CAF50),
    ),
    _SeverityMeta(
      level: 2,
      label: 'Moderate',
      description: 'Some risk present. Caution advised in the affected area.',
      color: Color(0xFF8BC34A),
    ),
    _SeverityMeta(
      level: 3,
      label: 'High',
      description: 'Significant danger. Evacuation or immediate action needed.',
      color: Color(0xFFFFB800),
    ),
    _SeverityMeta(
      level: 4,
      label: 'Severe',
      description: 'Major disaster. Multiple areas affected, lives at risk.',
      color: Color(0xFFFF6B2B),
    ),
    _SeverityMeta(
      level: 5,
      label: 'Extreme',
      description:
          'Catastrophic event. Maximum emergency response required immediately.',
      color: Color(0xFFFF3B3B),
    ),
  ];

  // ── Validate & submit ──────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Please enter a title for the report.');
      return;
    }
    if (_severityLevel == 0) {
      _snack('Please select a severity level.');
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _snack('Please describe the situation.');
      return;
    }

    if (_currentPosition == null) {
      _snack('Acquiring precise location. Please wait...');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isDuplicateCheckRunning = true;
      _duplicateCheckDone = false;
      _duplicateStep = 0;
    });

    _hourglassController.repeat();

    try {
      // Ensure minimum photos
      if (_uploadedPhotos.length < 2) {
        _snack('Please provide at least 2 photos of the incident.');
        setState(() {
          _isSubmitting = false;
          _isDuplicateCheckRunning = false;
        });
        _hourglassController.stop();
        return;
      }

      final api = ApiService();
      final storageService = SupabaseStorageService();

      // Step 1: Upload images to Supabase
      List<File> filesToUpload = _uploadedPhotos.map((path) => File(path)).toList();
      List<String> uploadedUrls = await storageService.uploadImages(filesToUpload);

      String severityStr = "Low";
      if (_severityLevel == 1) severityStr = "Medium";
      if (_severityLevel == 2) severityStr = "High";
      if (_severityLevel == 3) severityStr = "Critical";

      // Step 2: Create Report
      final response = await api.post(
        '/reports/',
        body: {
          "disaster_type": _selectedType,
          "title": _titleCtrl.text,
          "description": _descCtrl.text,
          "latitude": _currentPosition!.latitude,
          "longitude": _currentPosition!.longitude,
          "severity": severityStr,
          "created_at": DateTime.now().toUtc().toIso8601String(),
        },
      );

      final bool merged =
          response.containsKey('merged') ? response['merged'] : false;
      final int sourcesCount =
          response.containsKey('sources') ? response['sources'] : 1;
      final reportId = response['report_id'];

      // Step 3: Attach Media URLs to the report
      await api.post(
        '/reports/$reportId/media',
        body: {
          "media_urls": uploadedUrls,
          "file_type": "image"
        }
      );



      // Keep it checking UI state but secretly update _isDuplicate so the step dots color correctly
      if (mounted) {
        setState(() {
          _isDuplicate = merged;
        });
      }

      // Start "Duplicate Detection" artificial animation delay (1.4s per step)
      for (int i = 1; i <= 3; i++) {
        await Future.delayed(const Duration(milliseconds: 1400));
        if (!mounted) return;
        setState(() => _duplicateStep = i);
      }

      // Stop checking animation
      if (mounted) {
        setState(() {
          _isDuplicateCheckRunning = false;
          _duplicateCheckDone = true;
        });
        _hourglassController.stop();
      }

      // Wait 1.5 seconds for users to process result before closing
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        context.read<ReportProvider>().fetchReports(); // Refresh Feed
      }

      setState(() => _isSubmitting = false);

      if (!mounted) return;
      _showSuccessDialog(merged, sourcesCount);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isDuplicateCheckRunning = false;
          _duplicateCheckDone = false;
        });
        _hourglassController.stop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting report: $e')));
      }
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: AppColors.bgSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickPhoto() async {
    if (_uploadedPhotos.length >= 5) {
      _snack('Maximum 5 photos allowed.');
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            if (_uploadedPhotos.length < 5) {
              _uploadedPhotos.add(image.path);
            }
          }
        });
      }
    } catch (e) {
      _snack('Failed to pick images: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() => _uploadedPhotos.removeAt(index));
  }

  void _showSuccessDialog(bool isMerged, int sourcesCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            backgroundColor: AppColors.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isMerged ? 'Matched & Merged!' : 'Report Submitted!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isMerged
                      ? 'Your report is matched with ${sourcesCount - 1} persons for the same incident.'
                      : 'Your report has been submitted and will be reviewed by authorities.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pop(context); // close report screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ok',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1 ── Disaster type
            _sectionLabel('DISASTER TYPE'),
            const SizedBox(height: 12),
            _buildTypeSelector(),
            const SizedBox(height: 24),

            // 2 ── Title
            _sectionLabel('TITLE'),
            const SizedBox(height: 12),
            _buildTitleField(),
            const SizedBox(height: 24),

            // 3 ── Severity level
            _sectionLabel('SEVERITY LEVEL'),
            const SizedBox(height: 12),
            _buildSeveritySlider(),
            const SizedBox(height: 24),

            // 4 ── Description
            _sectionLabel('DESCRIPTION'),
            const SizedBox(height: 12),
            _buildDescriptionField(),
            const SizedBox(height: 24),

            // 5 ── GPS location
            _sectionLabel('GPS LOCATION'),
            const SizedBox(height: 12),
            _buildGpsCard(),
            const SizedBox(height: 24),

            // 6 ── Photo evidence
            _sectionLabel('PHOTO EVIDENCE'),
            const SizedBox(height: 4),
            Text(
              'Min 2, max 5 photos/videos',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 12),
            _buildPhotoEvidence(),
            const SizedBox(height: 32),

            // 7 ── Duplicate report detection (placeholder)
            _buildDuplicateDetectionCard(),
            const SizedBox(height: 24),

            // 8 ── Submit
            _buildSubmitButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      titleSpacing: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
      ),
      title: const Text(
        'Report Disaster',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  // ── 1. Disaster type chips ─────────────────────────────────────────────────
  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          _disasterTypes.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.orange : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.orange : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  // ── 2. Title field ─────────────────────────────────────────────────────────
  Widget _buildTitleField() {
    return TextField(
      controller: _titleCtrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'e.g. Flooding near Koshi bridge',
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // ── 3. Severity slider ─────────────────────────────────────────────────────
  Widget _buildSeveritySlider() {
    final selected =
        _severityLevel > 0 ? _severityLevels[_severityLevel - 1] : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level pills — RIGHT to LEFT (5 on left, 1 on right per spec)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              // i=0 → level 5 (extreme), i=4 → level 1 (low)
              final level = 5 - i;
              final meta = _severityLevels[level - 1];
              final isSelected = _severityLevel == level;

              return GestureDetector(
                onTap: () => setState(() => _severityLevel = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? meta.color.withOpacity(0.20)
                            : AppColors.bgDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? meta.color : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$level',
                        style: TextStyle(
                          color: isSelected ? meta.color : Colors.white38,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      // Volume bar — more filled = higher severity
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(level, (_) {
                          return Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? meta.color : Colors.white24,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          // Label strip (5→1 right-to-left)
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final level = 5 - i;
              final meta = _severityLevels[level - 1];
              final isSelected = _severityLevel == level;
              return SizedBox(
                width: 52,
                child: Text(
                  meta.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? meta.color : Colors.white24,
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              );
            }),
          ),

          // Description of selected level
          if (selected != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected.color.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Level ${selected.level} · ${selected.label}',
                    style: TextStyle(
                      color: selected.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              selected.description,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 4. Description field ───────────────────────────────────────────────────
  Widget _buildDescriptionField() {
    return TextField(
      controller: _descCtrl,
      maxLines: 4,
      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
      decoration: InputDecoration(
        hintText: 'Describe the situation...',
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: AppColors.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // ── 5. GPS card ────────────────────────────────────────────────────────────
  Widget _buildGpsCard() {
    final bool hasLocation = _currentPosition != null;
    final String latStr =
        hasLocation ? _currentPosition!.latitude.toStringAsFixed(4) : '--.----';
    final String lngStr =
        hasLocation
            ? _currentPosition!.longitude.toStringAsFixed(4)
            : '--.----';
    final String locText = '$latStr°N, $lngStr°E';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:
            hasLocation
                ? AppColors.success.withOpacity(0.08)
                : AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              hasLocation
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: hasLocation ? AppColors.success : AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              locText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color:
                  hasLocation
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              hasLocation ? 'Auto-detected' : 'Locating...',
              style: TextStyle(
                color: hasLocation ? AppColors.success : AppColors.warning,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Photo evidence ──────────────────────────────────────────────────────
  Widget _buildPhotoEvidence() {
    return Column(
      children: [
        // Uploaded thumbnails grid
        if (_uploadedPhotos.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _uploadedPhotos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, i) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                      image: DecorationImage(
                        image: FileImage(File(_uploadedPhotos[i])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _removePhoto(i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Photo ${i + 1}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // Upload button
        if (_uploadedPhotos.length < 5)
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white38,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to upload photo/video',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_uploadedPhotos.length}/5 uploaded · min 2 required',
                    style: TextStyle(
                      color:
                          _uploadedPhotos.length < 2
                              ? AppColors.warning.withOpacity(0.8)
                              : Colors.white24,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Photo count indicator
        if (_uploadedPhotos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _uploadedPhotos.length >= 2
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                color:
                    _uploadedPhotos.length >= 2
                        ? AppColors.success
                        : AppColors.warning,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                _uploadedPhotos.length >= 2
                    ? '${_uploadedPhotos.length} photo(s) ready'
                    : 'Need ${2 - _uploadedPhotos.length} more photo(s)',
                style: TextStyle(
                  color:
                      _uploadedPhotos.length >= 2
                          ? AppColors.success
                          : AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── 7. Report Duplicate Detection ─────────────────────────────────────────────────────
  Widget _buildDuplicateDetectionCard() {
    final bool isFinished = _duplicateCheckDone;
    // We already know whether it is merged by the time the loop starts because we wait for the API call first.
    // If _isDuplicateCheckRunning is true, we display coloring based on `_isDuplicate` up to `_duplicateStep`.
    // Wait, the backend result is returned *before* the 5 second loop, but we need to know the result.
    // In our `_submit`, we set `_isDuplicate` *after* the loop! Wait, `_isDuplicate` is set at the end, I need to set it *before* the loop. Let me fix the `_submit` logic in a second. Assuming `_isDuplicate` is set before the loop.

    // Let's determine the badge text and coloring
    String badgeText = 'PENDING';
    Color badgeColor = AppColors.warning;
    if (_isDuplicateCheckRunning) {
      badgeText = 'CHECKING...';
      badgeColor = Colors.blue;
    } else if (_duplicateCheckDone) {
      badgeText = _isDuplicate ? 'MATCH FOUND' : 'UNIQUE';
      badgeColor = _isDuplicate ? AppColors.success : AppColors.danger;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    _isDuplicateCheckRunning
                        ? RotationTransition(
                          turns: _hourglassController,
                          child: Icon(
                            Icons.hourglass_empty_rounded,
                            color: badgeColor,
                            size: 17,
                          ),
                        )
                        : Icon(
                          _duplicateCheckDone
                              ? (_isDuplicate
                                  ? Icons.merge_type_rounded
                                  : Icons.check_circle_outline)
                              : Icons.manage_search_rounded,
                          color: badgeColor,
                          size: 17,
                        ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DUPLICATE DETECTION',
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Powered by backend similarity check',
                    style: TextStyle(
                      color: Colors.white.withAlpha(100),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: badgeColor.withAlpha(80),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // ── Check items ─────────────────────────────────────────────────────
          ...[
            'Checking nearby reports all over the app...',
            'Matching disaster type & severity level...',
            'Comparing report timestamps (±2 hr window)...',
          ].asMap().entries.map((entry) {
            final int index = entry.key;
            final String label = entry.value;

            // Determine the color of this specific step dot
            Color dotColor = Colors.white.withAlpha(80); // default
            if (_duplicateCheckDone ||
                (_isDuplicateCheckRunning && _duplicateStep > index)) {
              // If it's a match, steps are green. If not match, steps are red.
              dotColor = _isDuplicate ? AppColors.success : AppColors.danger;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        // Option to dim un-reached text during loading?
                        color: Colors.white.withAlpha(
                          (_duplicateCheckDone ||
                                  _isDuplicateCheckRunning &&
                                      _duplicateStep > index)
                              ? 255
                              : 130,
                        ),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 4),

          // ── Footer note ─────────────────────────────────────────────────────
          Center(
            child: Text(
              _duplicateCheckDone
                  ? (_isDuplicate
                      ? 'Match found! Your report will be grouped with the existing one.'
                      : 'No matches found. This is a unique disaster.')
                  : 'This check runs automatically on submit — no action needed',
              style: TextStyle(
                color:
                    _duplicateCheckDone
                        ? Colors.white.withAlpha(180)
                        : Colors.white.withAlpha(70),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── 8. Submit button ───────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          disabledBackgroundColor: AppColors.danger.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text(
                  'Submit Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
      ),
    );
  }
}

// ─── Severity metadata model ──────────────────────────────────────────────────

class _SeverityMeta {
  final int level;
  final String label;
  final String description;
  final Color color;

  const _SeverityMeta({
    required this.level,
    required this.label,
    required this.description,
    required this.color,
  });
}

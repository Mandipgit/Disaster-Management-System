import 'package:disaster360/colors.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  final bool isInDialog;
  const FeedbackScreen({super.key, this.isInDialog = false});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _selectedRating = 0;
  String _selectedCategory = '';
  final TextEditingController _feedbackCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  final List<String> _categories = [
    'App Performance',
    'Report Accuracy',
    'Map Features',
    'Alerts & Notifications',
    'Other',
  ];

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      _showSnack('Please select a rating before submitting.');
      return;
    }
    if (_feedbackCtrl.text.trim().isEmpty) {
      _showSnack('Please write your feedback before submitting.');
      return;
    }
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: AppColors.border,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInDialog) {
      // ── Dialog mode: no Scaffold, no AppBar ──────────────────────────────
      return _buildFormContent();
    } else {
      // ── Full‑screen mode: with Scaffold and AppBar ───────────────────────
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: _buildAppBar(context),
        body: _submitted ? _buildSuccessState() : _buildFormContent(),
      );
    }
  }

  // Extract the form content into a separate method (used in both modes)
  Widget _buildFormContent() {
    return _submitted
        ? _buildSuccessState()
        : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro (same as before)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your feedback helps us improve disaster response for everyone in your community.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Star rating
              _buildSectionLabel('RATE YOUR EXPERIENCE'),
              const SizedBox(height: 14),
              _buildStarRating(),
              const SizedBox(height: 28),

              // Category chips
              _buildSectionLabel('FEEDBACK CATEGORY'),
              const SizedBox(height: 14),
              _buildCategoryChips(),
              const SizedBox(height: 28),

              // Text area
              _buildSectionLabel('YOUR FEEDBACK'),
              const SizedBox(height: 14),
              _buildTextArea(),
              const SizedBox(height: 28),

              // Submit button
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        );
  }

  // ── App bar (only used in full‑screen mode) ───────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgPrimary,
      elevation: 0,
      titleSpacing: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
      ),
      title: const Text(
        'Provide Feedback',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  // ── Section label (unchanged) ──────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
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

  // ── Star rating (unchanged) ────────────────────────────────────────────────
  Widget _buildStarRating() {
    final labels = ['Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            final isSelected = star <= _selectedRating;
            return GestureDetector(
              onTap: () => setState(() => _selectedRating = star),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    key: ValueKey(isSelected),
                    color: isSelected ? AppColors.warning : Colors.white24,
                    size: 40,
                  ),
                ),
              ),
            );
          }),
        ),
        if (_selectedRating > 0) ...[
          const SizedBox(height: 10),
          Text(
            labels[_selectedRating - 1],
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  // ── Category chips (unchanged) ─────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children:
          _categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap:
                  () =>
                      setState(() => _selectedCategory = isSelected ? '' : cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.orange.withOpacity(0.18)
                          : AppColors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isSelected
                            ? AppColors.orange
                            : Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? AppColors.orange : Colors.white54,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  // ── Text area (unchanged) ──────────────────────────────────────────────────
  Widget _buildTextArea() {
    return TextField(
      controller: _feedbackCtrl,
      maxLines: 5,
      maxLength: 500,
      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
      decoration: InputDecoration(
        hintText: 'Describe your experience or suggest an improvement...',
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: AppColors.bgSurface,
        counterStyle: const TextStyle(color: Colors.white24, fontSize: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      ),
    );
  }

  // ── Submit button (unchanged) ──────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          disabledBackgroundColor: AppColors.orange.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
                  'Submit Feedback',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
      ),
    );
  }

  // ── Success state (unchanged) ──────────────────────────────────────────────
  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
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
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Thank You!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your feedback has been submitted successfully. We\'ll use it to improve Disaster360 for everyone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Back to Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

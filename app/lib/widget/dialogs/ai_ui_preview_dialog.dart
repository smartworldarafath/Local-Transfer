import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AiUiPreviewDialog extends StatefulWidget {
  final VoidCallback onApply;

  const AiUiPreviewDialog({super.key, required this.onApply});

  static Future<void> show(BuildContext context, {required VoidCallback onApply}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => AiUiPreviewDialog(onApply: onApply),
    );
  }

  @override
  State<AiUiPreviewDialog> createState() => _AiUiPreviewDialogState();
}

class _AiUiPreviewDialogState extends State<AiUiPreviewDialog> {
  final PageController _pageController = PageController(viewportFraction: 0.44);
  int _currentPage = 0;

  static const List<String> _previews = [
    'assets/img/ai_ui/photo_2_2026-10-25_23-34-06.jpg', // Receive
    'assets/img/ai_ui/photo_1_2026-10-25_23-34-06.jpg', // Send
    'assets/img/ai_ui/photo_6_2026-10-25_23-34-06.jpg', // Settings
    'assets/img/ai_ui/photo_7_2026-10-25_23-34-06.jpg', // App Theme
    'assets/img/ai_ui/photo_3_2026-10-25_23-34-06.jpg', // History
    'assets/img/ai_ui/photo_5_2026-10-25_23-34-06.jpg', // Updates
    'assets/img/ai_ui/photo_4_2026-10-25_23-34-06.jpg', // Add to selection
    'assets/img/ai_ui/photo_5_2026-10-26_11-24-11.jpg', // Background Look
    'assets/img/ai_ui/photo_1_2026-10-26_12-04-14.jpg', // Theme selection
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF28233C),
                Color(0xFF161A28),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.only(top: 20, bottom: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Title
              const Text(
                'Ai Ui',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 18),

              // Carousel of Screens
              SizedBox(
                height: 270,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _previews.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final isCurrent = index == _currentPage;
                    return AnimatedScale(
                      scale: isCurrent ? 1.0 : 0.92,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.white.withOpacity(0.55)
                                : Colors.white.withOpacity(0.20),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isCurrent ? 0.45 : 0.25),
                              blurRadius: isCurrent ? 14 : 8,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            _previews[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.white10,
                              alignment: Alignment.center,
                              child: const Icon(Icons.phone_android, color: Colors.white54, size: 40),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_previews.length, (index) {
                  final isCurrent = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isCurrent ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.white : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Action Buttons: Cancel and Apply
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    // Cancel Button
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Apply Button
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onApply();
                        },
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0095FF), Color(0xFF0062FF)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0066FF).withOpacity(0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

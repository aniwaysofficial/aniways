import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aniways/providers/watch_provider.dart';

/// Pill badge displayed when screen controls are locked.
class LockedControlsOverlay extends StatelessWidget {
  const LockedControlsOverlay({super.key, required this.wp});

  final WatchProvider wp;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            wp.toggleControlsLock();
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white38),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Tap to Unlock',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


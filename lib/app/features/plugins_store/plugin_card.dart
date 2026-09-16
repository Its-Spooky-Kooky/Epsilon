import 'package:flutter/material.dart';

class PluginCard extends StatelessWidget {
  final String title;
  final String category;
  final String description;
  final String version;
  final bool isInstalled;
  final VoidCallback? onConfigure;
  final VoidCallback? onToggleInstall;

  const PluginCard({
    super.key,
    required this.title,
    required this.category,
    required this.description,
    required this.version,
    required this.isInstalled,
    this.onConfigure,
    this.onToggleInstall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInstalled
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isInstalled
                      ? Colors.tealAccent.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isInstalled ? Colors.tealAccent : Colors.white54,
                  ),
                ),
              ),
              Text(
                'v$version',
                style: const TextStyle(fontSize: 11, color: Colors.white30),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white60,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (isInstalled && onConfigure != null) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onConfigure,
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Configure Toggles', style: TextStyle(fontSize: 12)),
                ),
                const Spacer(),
              ] else ...[
                const Spacer(),
              ],
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: isInstalled ? Colors.white54 : Colors.white,
                  backgroundColor: isInstalled ? Colors.transparent : Colors.white12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onToggleInstall,
                child: Text(
                  isInstalled ? 'ACTIVE' : 'INSTALL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isInstalled ? Colors.tealAccent : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

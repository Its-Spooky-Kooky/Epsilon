import 'package:flutter/material.dart';

class PluginCard extends StatelessWidget {
  final String title;
  final String category;
  final String description;
  final String version;
  final bool isInstalled;
  final ValueChanged<bool> onToggleInstall;

  const PluginCard({
    super.key,
    required this.title,
    required this.category,
    required this.description,
    required this.version,
    required this.isInstalled,
    required this.onToggleInstall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isInstalled
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isInstalled,
            activeThumbColor: Colors.tealAccent,
            activeTrackColor: Colors.tealAccent.withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
            onChanged: onToggleInstall,
          ),
        ],
      ),
    );
  }
}

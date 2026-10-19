import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:epsilon/app/core/app_settings_provider.dart';

class PluginColorOption {
  final String name;
  final Color color;

  const PluginColorOption(this.name, this.color);
}

class PluginAppearanceSection extends ConsumerStatefulWidget {
  final String pluginId;
  final String pluginName;
  final Color defaultTagColor;
  final Color defaultTextColor;

  const PluginAppearanceSection({
    super.key,
    required this.pluginId,
    required this.pluginName,
    required this.defaultTagColor,
    required this.defaultTextColor,
  });

  @override
  ConsumerState<PluginAppearanceSection> createState() => _PluginAppearanceSectionState();
}

class _PluginAppearanceSectionState extends ConsumerState<PluginAppearanceSection> {
  late Color _currentTagColor;
  late Color _currentTextColor;

  // The 8 allowed plugin theme colors as explicitly requested:
  // blue, navy blue, yellow, green, red, violet, indigo, orange (thats all)
  static const List<PluginColorOption> _themeColors = [
    PluginColorOption('Blue', Color(0xFF2979FF)),
    PluginColorOption('Navy Blue', Color(0xFF0D47A1)),
    PluginColorOption('Yellow', Color(0xFFFFD600)),
    PluginColorOption('Green', Color(0xFF00E676)),
    PluginColorOption('Red', Color(0xFFFF1744)),
    PluginColorOption('Violet', Color(0xFF7C4DFF)),
    PluginColorOption('Indigo', Color(0xFF3D5AFE)),
    PluginColorOption('Orange', Color(0xFFFF9100)),
  ];

  // The 2 allowed font colors as explicitly requested:
  // white or black (thats all)
  static const List<PluginColorOption> _fontColors = [
    PluginColorOption('White', Color(0xFFFFFFFF)),
    PluginColorOption('Black', Color(0xFF000000)),
  ];

  @override
  void initState() {
    super.initState();
    final bundle = ref.read(pluginAppearanceProvider.notifier).getColors(widget.pluginId);
    _currentTagColor = bundle.tagColor;
    _currentTextColor = bundle.textColor;
  }

  void _save(Color tagColor, Color textColor) {
    setState(() {
      _currentTagColor = tagColor;
      _currentTextColor = textColor;
    });
    ref.read(pluginAppearanceProvider.notifier).setColors(
          widget.pluginId,
          tagColor,
          textColor,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(pluginAppearanceProvider)[widget.pluginId];
    if (colors != null) {
      _currentTagColor = colors.tagColor;
      _currentTextColor = colors.textColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.palette_outlined, size: 18, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    'Plugin Theme & Font Color',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _save(widget.defaultTagColor, widget.defaultTextColor),
                child: const Text(
                  'Reset',
                  style: TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Live Tag Preview
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _currentTagColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _currentTagColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alarm, size: 14, color: _currentTextColor),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.pluginName} Sample Event',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _currentTextColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 1. Plugin Theme Colors (8 options)
          const Text(
            'THEME COLOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.2,
            ),
            itemCount: _themeColors.length,
            itemBuilder: (context, index) {
              final opt = _themeColors[index];
              final isSelected = opt.color.toARGB32() == _currentTagColor.toARGB32();

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _save(opt.color, _currentTextColor),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E88E5).withValues(alpha: 0.18)
                        : const Color(0xFF131313),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2979FF) : Colors.white.withValues(alpha: 0.06),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: opt.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          opt.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // 2. Font Colors (White or Black)
          const Text(
            'FONT COLOR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: _fontColors.map((opt) {
              final isSelected = opt.color.toARGB32() == _currentTextColor.toARGB32();

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: opt.name == 'White' ? 4 : 0,
                    left: opt.name == 'Black' ? 4 : 0,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _save(_currentTagColor, opt.color),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1E88E5).withValues(alpha: 0.18)
                            : const Color(0xFF131313),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2979FF) : Colors.white.withValues(alpha: 0.06),
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: opt.color,
                              borderRadius: BorderRadius.circular(3),
                              border: opt.color == const Color(0xFF000000)
                                  ? Border.all(color: Colors.white30, width: 1)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            opt.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

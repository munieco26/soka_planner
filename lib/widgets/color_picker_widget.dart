import 'package:flutter/material.dart';

class ColorPickerWidget extends StatelessWidget {
  final int selectedColor;
  final ValueChanged<int> onColorSelected;

  static const List<int> colors = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFF44336, // Red
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFF009688, // Teal
    0xFFE91E63, // Pink
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
    0xFFFFEB3B, // Yellow
    0xFF3F51B5, // Indigo
    0xFF00BCD4, // Cyan
  ];

  const ColorPickerWidget({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((c) {
        final isSelected = selectedColor == c;
        return GestureDetector(
          onTap: () => onColorSelected(c),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(c),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black87, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(c).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

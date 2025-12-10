import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category.dart';

class CategoryActionPopup extends ConsumerWidget {
  final Category category;
  final VoidCallback onDelete;
  final VoidCallback onModify;

  const CategoryActionPopup({
    super.key,
    required this.category,
    required this.onDelete,
    required this.onModify,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Custom dialog matching the rounded beige aesthetic
    return Dialog(
      backgroundColor: const Color(0xFFFFF8E1), // Light beige background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon and Name Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: category.color
                    .withValues(alpha: 0.2), // Box decoration color follows category color
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Wrap content
                children: [
                  CircleAvatar(
                    backgroundColor: category.color.withValues(alpha: 0.2),
                    radius: 16,
                    child: Icon(category.icon, color: category.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Delete',
                    color: const Color(
                      0xFFFFF3E0,
                    ), // Very light beige for delete
                    textColor: Colors.black87,
                    onTap: () {
                      Navigator.of(context).pop();
                      onDelete();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: 'Modify',
                    color: const Color(0xFFCD5C5C), // Indian Red / Muted Red
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.of(context).pop();
                      onModify();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

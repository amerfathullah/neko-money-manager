import 'package:flutter/material.dart';

class CustomKeypad extends StatelessWidget {
  final VoidCallback onBlackCheckTap;
  final VoidCallback onRedActionTap;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onBackspaceTap;
  final bool isCalculationMode;

  const CustomKeypad({
    super.key,
    required this.onBlackCheckTap,
    required this.onRedActionTap,
    required this.onKeyTap,
    required this.onBackspaceTap,
    required this.isCalculationMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3', '+']),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6', '-']),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9', 'BACK']),
        const SizedBox(height: 12),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        return Expanded(child: _buildKey(key));
      }).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildKey('0')),
        Expanded(child: _buildKey('.')),
        // Black Check Button
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: InkWell(
                onTap: onBlackCheckTap,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent, // Or specific color?
                  ),
                  child: const Icon(
                    Icons.check, // Or check with dash
                    size: 32,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Red Action Button
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: InkWell(
                onTap: onRedActionTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC25E5E), // Muted red/maroon
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isCalculationMode
                        ? Icons.drag_handle
                        : Icons
                              .check, // drag_handle looks like equal sign approx, or use FontAwesome eq
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String key) {
    if (key == 'BACK') {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: InkWell(
            onTap: onBackspaceTap,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.arrow_back, size: 28),
            ),
          ),
        ),
      );
    }

    bool isOperator = ['+', '-'].contains(key);

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: InkWell(
          onTap: () => onKeyTap(key),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOperator
                  ? const Color(0xFFF5E6D3)
                  : Colors.transparent, // Match Amount field color
            ),
            child: isOperator
                ? Icon(
                    key == '+' ? Icons.add : Icons.remove,
                    size: 32,
                    color: Colors.black87,
                  )
                : Text(
                    key,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

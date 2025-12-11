import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/transactions_list_widgets.dart';

class TimeFilterPopup extends StatefulWidget {
  final TransactionTimeRange initialRange;
  final DateTime initialSelectedDate;
  final DateTimeRange? initialCustomDateRange;

  const TimeFilterPopup({
    super.key,
    required this.initialRange,
    required this.initialSelectedDate,
    this.initialCustomDateRange,
  });

  @override
  State<TimeFilterPopup> createState() => _TimeFilterPopupState();
}

class _TimeFilterPopupState extends State<TimeFilterPopup> {
  late TransactionTimeRange _selectedRange;
  late DateTime _focusedDate; // For navigating months/years
  late DateTime _selectedDate;
  late int _annualStartYear;
  DateTimeRange? _customDateRange;
  bool _isEditingCustomStart =
      true; // For custom view: true = start, false = end

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;
    _selectedDate = widget.initialSelectedDate;
    _focusedDate = widget.initialSelectedDate;
    _customDateRange =
        widget.initialCustomDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );
    _annualStartYear = widget.initialSelectedDate.year - 6;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF0), // Cream background
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('Daily', TransactionTimeRange.daily),
                  _buildTab('Weekly', TransactionTimeRange.weekly),
                  _buildTab('Monthly', TransactionTimeRange.monthly),
                  _buildTab('Annual', TransactionTimeRange.annual),
                  _buildTab('Custom', TransactionTimeRange.custom),
                  _buildTab('All', TransactionTimeRange.all),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content Area
            SizedBox(
              height: 340,
              width: double.maxFinite,
              child: _buildContent(),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C), // Deep Red
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, TransactionTimeRange range) {
    final isSelected = _selectedRange == range;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: () => setState(() {
          _selectedRange = range;
          // Reset logic if needed when switching
          if (range == TransactionTimeRange.custom &&
              _customDateRange == null) {
            final now = DateTime.now();
            _customDateRange = DateTimeRange(start: now, end: now);
          }
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFB71C1C) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedRange) {
      case TransactionTimeRange.daily:
        return _buildDailyView();
      case TransactionTimeRange.weekly:
        return _buildDailyView(isWeekly: true);
      case TransactionTimeRange.monthly:
        return _buildMonthlyView();
      case TransactionTimeRange.annual:
        return _buildAnnualView();
      case TransactionTimeRange.custom:
        return _buildCustomView();
      case TransactionTimeRange.all:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.list_alt, size: 48, color: AppColors.textDark),
              SizedBox(height: 16),
              Text(
                "Show all transactions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
    }
  }

  // --- Views ---

  Widget _buildDailyView({bool isWeekly = false}) {
    return Column(
      children: [
        _buildMonthNavigator(),
        const SizedBox(height: 8),
        Expanded(
          child: _CalendarGrid(
            focusedMonth: _focusedDate,
            selectedDate: _selectedDate,
            selectionMode: isWeekly
                ? _CalendarSelectionMode.weekly
                : _CalendarSelectionMode.single,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
                if (date.month != _focusedDate.month ||
                    date.year != _focusedDate.year) {
                  _focusedDate = DateTime(date.year, date.month);
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyView() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.0,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: 12,
            itemBuilder: (ctx, i) {
              final monthIndex = i + 1;
              final isSelected =
                  _selectedDate.month == monthIndex &&
                  _selectedDate.year == _focusedDate.year;
              final monthName = DateFormat(
                'MMM',
              ).format(DateTime(2022, monthIndex));

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _focusedDate.year,
                      monthIndex,
                      _selectedDate.day,
                    );
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      monthName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime(_focusedDate.year - 1);
                });
              },
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: AppColors.textDark,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '${_focusedDate.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime(_focusedDate.year + 1);
                });
              },
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnnualView() {
    final startYear = _annualStartYear;

    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: 12,
            itemBuilder: (ctx, i) {
              final year = startYear + i;
              final isSelected = year == _selectedDate.year;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(
                      year,
                      _selectedDate.month,
                      _selectedDate.day,
                    );
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$year',
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _annualStartYear -= 12;
                });
              },
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: AppColors.textDark,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _annualStartYear += 12;
                });
              },
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomView() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isEditingCustomStart = true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isEditingCustomStart
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _customDateRange != null
                          ? DateFormat(
                              'MMM dd yyyy',
                            ).format(_customDateRange!.start)
                          : "Start Date",
                      style: TextStyle(
                        color: _isEditingCustomStart
                            ? Colors.white
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isEditingCustomStart = false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: !_isEditingCustomStart
                        ? const Color(0xFFB71C1C)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _customDateRange != null
                          ? DateFormat(
                              'MMM dd yyyy',
                            ).format(_customDateRange!.end)
                          : "End Date",
                      style: TextStyle(
                        color: !_isEditingCustomStart
                            ? Colors.white
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildMonthNavigator(),
        const SizedBox(height: 8),
        Expanded(
          child: _CalendarGrid(
            focusedMonth: _focusedDate,
            selectedDate: null,
            selectedRange: _customDateRange,
            selectionMode: _CalendarSelectionMode.range,
            onDateSelected: (date) {
              setState(() {
                // Update Logic
                DateTime newStart = _customDateRange!.start;
                DateTime newEnd = _customDateRange!.end;

                if (_isEditingCustomStart) {
                  newStart = date;
                  // Enforce start <= end
                  if (newStart.isAfter(newEnd)) newEnd = newStart;
                } else {
                  newEnd = date;
                  // Enforce end >= start
                  if (newEnd.isBefore(newStart)) newStart = newEnd;
                }

                _customDateRange = DateTimeRange(start: newStart, end: newEnd);

                // Update focus if needed?
                if (date.month != _focusedDate.month ||
                    date.year != _focusedDate.year) {
                  _focusedDate = DateTime(date.year, date.month);
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () {
            setState(() {
              _focusedDate = DateTime(
                _focusedDate.year,
                _focusedDate.month - 1,
              );
            });
          },
        ),
        Text(
          DateFormat('MMM yyyy').format(_focusedDate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            setState(() {
              _focusedDate = DateTime(
                _focusedDate.year,
                _focusedDate.month + 1,
              );
            });
          },
        ),
      ],
    );
  }

  void _onConfirm() {
    Navigator.pop(context, {
      'range': _selectedRange,
      'date': _selectedDate,
      'customRange': _customDateRange,
    });
  }
}

enum _CalendarSelectionMode { single, weekly, range }

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final DateTimeRange? selectedRange;
  final _CalendarSelectionMode selectionMode;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarGrid({
    required this.focusedMonth,
    this.selectedDate,
    this.selectedRange,
    required this.selectionMode,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final days = _computeDays();
    return Column(
      children: [
        // Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map(
                (d) => SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        // Days
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              final isCurrentMonth = date.month == focusedMonth.month;

              if (selectionMode == _CalendarSelectionMode.weekly &&
                  selectedDate != null) {
                return _buildWeeklyDay(date, isCurrentMonth);
              } else if (selectionMode == _CalendarSelectionMode.range &&
                  selectedRange != null) {
                return _buildRangeDay(date, isCurrentMonth);
              } else {
                return _buildSingleDay(date, isCurrentMonth);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSingleDay(DateTime date, bool isCurrentMonth) {
    final isSelected =
        selectedDate != null &&
        date.year == selectedDate!.year &&
        date.month == selectedDate!.month &&
        date.day == selectedDate!.day;

    return InkWell(
      onTap: () => onDateSelected(date),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFB71C1C)
              : Colors.transparent, // Red circle
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isCurrentMonth ? AppColors.textDark : Colors.grey[400]),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyDay(DateTime date, bool isCurrentMonth) {
    if (selectedDate == null) return _buildSingleDay(date, isCurrentMonth);

    final selectedWeekStart = _startOfWeek(selectedDate!);
    final selectedWeekEnd = selectedWeekStart.add(const Duration(days: 6));

    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      selectedWeekStart.year,
      selectedWeekStart.month,
      selectedWeekStart.day,
    );
    final end = DateTime(
      selectedWeekEnd.year,
      selectedWeekEnd.month,
      selectedWeekEnd.day,
    );

    final isInWeek =
        (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
        (d.isAtSameMomentAs(end) || d.isBefore(end));
    final isSelected =
        d.year == selectedDate!.year &&
        d.month == selectedDate!.month &&
        d.day == selectedDate!.day;

    Color? bgColor;
    Color textColor = isCurrentMonth ? AppColors.textDark : Colors.grey[400]!;

    if (isInWeek) {
      bgColor = const Color(0xFFB71C1C);
      textColor = Colors.white;
    }

    BorderRadius? radius;
    if (isInWeek) {
      bool isStart = d.weekday == DateTime.sunday;
      bool isEnd = d.weekday == DateTime.saturday;

      radius = BorderRadius.horizontal(
        left: isStart ? const Radius.circular(20) : Radius.zero,
        right: isEnd ? const Radius.circular(20) : Radius.zero,
      );
    }

    return InkWell(
      onTap: () => onDateSelected(date),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.transparent,
          borderRadius: radius,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: isInWeek || isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeDay(DateTime date, bool isCurrentMonth) {
    if (selectedRange == null) return _buildSingleDay(date, isCurrentMonth);

    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      selectedRange!.start.year,
      selectedRange!.start.month,
      selectedRange!.start.day,
    );
    final end = DateTime(
      selectedRange!.end.year,
      selectedRange!.end.month,
      selectedRange!.end.day,
    );

    final isStart = d.isAtSameMomentAs(start);
    final isEnd = d.isAtSameMomentAs(end);
    final isInBetween = d.isAfter(start) && d.isBefore(end);
    final isSelected = isStart || isEnd;

    Color? bgColor;
    Color textColor = isCurrentMonth ? AppColors.textDark : Colors.grey[400]!;

    if (isSelected) {
      bgColor = const Color(0xFFB71C1C);
      textColor = Colors.white;
    } else if (isInBetween) {
      bgColor = const Color(0xFFB71C1C).withValues(alpha: 0.3); // Lighter red
      textColor = AppColors.textDark; // Or white if opacity is high
    }

    BorderRadius? radius;
    if (isSelected || isInBetween) {
      radius = BorderRadius.horizontal(
        left: isStart ? const Radius.circular(20) : Radius.zero,
        right: isEnd ? const Radius.circular(20) : Radius.zero,
      );
      // If single day range
      if (isStart && isEnd) radius = BorderRadius.circular(20);
    }

    return InkWell(
      onTap: () => onDateSelected(date),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.transparent,
          borderRadius: radius,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  List<DateTime> _computeDays() {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final offset = firstDayOfMonth.weekday % 7;
    final startOfGrid = firstDayOfMonth.subtract(Duration(days: offset));
    return List.generate(42, (index) => startOfGrid.add(Duration(days: index)));
  }

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }
}

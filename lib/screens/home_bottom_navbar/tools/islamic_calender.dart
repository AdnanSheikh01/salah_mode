import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IslamicCalenderPage extends StatefulWidget {
  const IslamicCalenderPage({super.key});

  @override
  State<IslamicCalenderPage> createState() => _IslamicCalenderPageState();
}

class _IslamicCalenderPageState extends State<IslamicCalenderPage> {
  DateTime selectedDate = DateTime.now();
  DateTime visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  int moonOffset = 0; // 🌙 location-based offset
  final DateTime _today = DateTime.now();

  // 🌙 Simple Hijri approximation (civil algorithm)
  String getHijriDate(DateTime date) {
    final jd = (date.millisecondsSinceEpoch / 86400000) + 2440587.5;
    final islamicEpoch = 1948439.5;
    final days = jd - islamicEpoch + moonOffset;

    final year = ((30 * days + 10646) ~/ 10631);
    final priorDays = days - (354 * (year - 1) + ((3 + (11 * year)) ~/ 30));
    final month = ((priorDays) / 29.5).ceil().clamp(1, 12);
    final day =
        (days -
                (354 * (year - 1) +
                    ((3 + (11 * year)) ~/ 30) +
                    (29.5 * (month - 1)).floor()) +
                1)
            .toInt();

    const months = [
      "Muharram",
      "Safar",
      "Rabi' al-awwal",
      "Rabi' al-thani",
      "Jumada al-awwal",
      "Jumada al-thani",
      "Rajab",
      "Sha'ban",
      "Ramadan",
      "Shawwal",
      "Dhul-Qi'dah",
      "Dhul-Hijjah",
    ];

    return "$day ${months[month - 1]} $year AH";
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  // 📆 ULTRA: month navigation
  void _changeMonth(int delta) {
    setState(() {
      visibleMonth = DateTime(visibleMonth.year, visibleMonth.month + delta);
    });
  }

  List<DateTime> _buildMonthDays() {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final startWeekday = firstDay.weekday % 7;
    final startDate = firstDay.subtract(Duration(days: startWeekday));

    return List.generate(42, (i) => startDate.add(Duration(days: i)));
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isSelected(DateTime d) {
    return d.year == selectedDate.year &&
        d.month == selectedDate.month &&
        d.day == selectedDate.day;
  }

  // 🌙 ULTRA: detect Islamic events
  String? _getIslamicEvent(DateTime date) {
    final hijri = getHijriDate(date);

    if (hijri.contains("Ramadan")) return "Ramadan";
    if (hijri.contains("10 Dhul-Hijjah")) return "Eid al-Adha";
    if (hijri.contains("1 Shawwal")) return "Eid al-Fitr";
    if (hijri.contains("10 Muharram")) return "Ashura";

    return null;
  }

  Color _eventColor(String event, BuildContext context) {
    switch (event) {
      case "Ramadan":
        return Colors.green;
      case "Ramadan Begins":
        return Colors.green;
      case "Eid al-Fitr":
      case "Eid al-Adha":
        return Colors.orange;
      case "Ashura":
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  // 🧭 Jump to today
  void _jumpToToday() {
    setState(() {
      selectedDate = _today;
      visibleMonth = DateTime(_today.year, _today.month);
    });
  }

  // 📊 Hijri month progress (approx)
  double _getHijriMonthProgress() {
    final hijri = getHijriDate(selectedDate);
    final day = int.tryParse(hijri.split(" ").first) ?? 1;
    return (day / 30).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final hijri = getHijriDate(selectedDate);
    final gregorian = DateFormat.yMMMMEEEEd().format(selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text("Islamic Calendar"), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 🌙 Premium card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Hijri Date",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hijri,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      gregorian,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // 🗓️ ULTRA Hijri monthly calendar
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    DateFormat.yMMMM().format(visibleMonth),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // 📊 Hijri month progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _getHijriMonthProgress(),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 8),

              // 🗓️ Weekday labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Sun"),
                  Text("Mon"),
                  Text("Tue"),
                  Text("Wed"),
                  Text("Thu"),
                  Text("Fri"),
                  Text("Sat"),
                ],
              ),

              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 42,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final days = _buildMonthDays();
                  final date = days[index];
                  final isCurrentMonth = date.month == visibleMonth.month;
                  final isToday = _isToday(date);
                  final isSelected = _isSelected(date);
                  final event = _getIslamicEvent(date);

                  return GestureDetector(
                    onTap: () => setState(() => selectedDate = date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : isToday
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(.25)
                            : Colors.transparent,
                        border: event != null
                            ? Border.all(
                                color: _eventColor(event, context),
                                width: 1.4,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${date.day}",
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : isCurrentMonth
                                    ? null
                                    : Colors.grey,
                              ),
                            ),
                            if (event != null)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: _eventColor(event, context),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              const SizedBox(height: 20),

              // 🧭 Jump to today button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _jumpToToday,
                  icon: const Icon(Icons.my_location),
                  label: const Text("Today"),
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text("Select Date"),
                ),
              ),

              const SizedBox(height: 30),

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Moon Offset"),
                  IconButton(
                    onPressed: () => setState(() => moonOffset--),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text("$moonOffset"),
                  IconButton(
                    onPressed: () => setState(() => moonOffset++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "Note: Hijri date is calculated using civil approximation. "
                  "Actual moon sighting may vary.",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

Widget salamHeader(BuildContext context, {String userName = "Mohd Adnan"}) {
  final hour = DateTime.now().hour;
  final theme = Theme.of(context);

  String greeting;
  IconData timeIcon;

  // Minimalist logic for time-based icons/greetings
  if (hour >= 5 && hour < 12) {
    greeting = "Good Morning";
    timeIcon = Icons.wb_twilight_rounded;
  } else if (hour >= 12 && hour < 17) {
    greeting = "Good Afternoon";
    timeIcon = Icons.wb_sunny_rounded;
  } else if (hour >= 17 && hour < 21) {
    greeting = "Good Evening";
    timeIcon = Icons.nights_stay_rounded;
  } else {
    greeting = "Good Night";
    timeIcon = Icons.bedtime_rounded;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      // Dark Glassmorphism look
      color: const Color(0xFF1A1A1A).withOpacity(0.8),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        // ✨ Modern Icon Container
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.4),
                theme.colorScheme.primary.withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Icon(timeIcon, color: theme.colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 16),

        // 👤 User Greeting Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Assalamu Alaikum",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              userName == ""
                  ? const SizedBox()
                  : Text(
                      userName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
            ],
          ),
        ),

        // 🕒 Subdued Time Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            greeting,
            style: TextStyle(
              color: theme.colorScheme.primary.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    ),
  );
}

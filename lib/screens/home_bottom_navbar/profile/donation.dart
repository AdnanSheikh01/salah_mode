import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  int? _selectedAmount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Support Salah Mode"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🌙 Header Card
            _buildHeaderCard(theme),

            const SizedBox(height: 24),

            // 💝 Donation options
            _buildDonationGrid(theme),

            const SizedBox(height: 24),

            // 🤲 Custom amount
            _buildCustomDonation(theme),

            const SizedBox(height: 40),

            // 🕌 Du'a message
            _buildDuaText(theme),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeaderCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1F3B4D), Color(0xFF0F2027)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.volunteer_activism, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            "Support Salah Mode",
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Help us keep the app free and improve Islamic features for the Ummah.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ================= DONATION GRID =================

  Widget _buildDonationGrid(ThemeData theme) {
    final amounts = [50, 100, 250, 500];

    return GridView.builder(
      itemCount: amounts.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (_, index) {
        final amount = amounts[index];
        final isSelected = _selectedAmount == amount;

        return InkWell(
          onTap: () {
            setState(() => _selectedAmount = amount);
            _donate(amount);
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.15)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : Colors.white10,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                "₹$amount",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= CUSTOM =================

  Widget _buildCustomDonation(ThemeData theme) {
    final controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter custom amount",
              prefixText: "₹ ",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final amount = int.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  _donate(amount);
                }
              },
              child: const Text("Donate Now"),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DUA =================

  Widget _buildDuaText(ThemeData theme) {
    return Text(
      "May Allah reward you for supporting this effort 🤲",
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: Colors.greenAccent,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // ================= ACTION =================

  void _donate(int amount) {
    Get.snackbar(
      "Donation",
      "Proceeding to donate ₹$amount",
      colorText: Colors.white,
      backgroundColor: Colors.green,
    );

    // TODO: integrate Razorpay / Stripe here
  }
}

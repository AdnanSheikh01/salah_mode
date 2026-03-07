import 'package:flutter/material.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final List<Map<String, dynamic>> users = [
    {
      "name": "Ahmed Raza",
      "points": 1250,
      "initial": "AR",
      "trend": "up",
      "badge": "Hafiz",
    },
    {
      "name": "Bilal Khan",
      "points": 840,
      "initial": "BK",
      "trend": "down",
      "badge": "Guide",
    },
    {
      "name": "Zain Malik",
      "points": 720,
      "initial": "ZM",
      "trend": "up",
      "badge": "Helper",
    },
    {
      "name": "Fatima Noor",
      "points": 650,
      "initial": "FN",
      "trend": "up",
      "badge": "Guide",
    },
    {
      "name": "Omar Ali",
      "points": 600,
      "initial": "OA",
      "trend": "down",
      "badge": "Helper",
    },
  ];

  Widget _buildLeaderboard() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _podiumUser(users[1], 2, 70, Colors.grey),
                  _podiumUser(users[0], 1, 90, Colors.amber),
                  _podiumUser(users[2], 3, 70, Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length - 3,
                itemBuilder: (context, index) {
                  final user = users[index + 3];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xffffffff), Color(0xfff1f3f5)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            "${index + 4}.",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Text(
                          "${index + 4}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        CircleAvatar(
                          backgroundColor: Colors.purple.shade100,
                          child: Text(user["initial"]?.toString() ?? ""),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user["name"]?.toString() ?? "",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (user["badge"] == "Hafiz")
                                          ? Colors.amber.withOpacity(.2)
                                          : (user["badge"] == "Guide")
                                          ? Colors.blue.withOpacity(.2)
                                          : Colors.green.withOpacity(.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      user["badge"]?.toString() ?? "",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: (user["badge"] == "Hafiz")
                                            ? Colors.amber
                                            : (user["badge"] == "Guide")
                                            ? Colors.blue
                                            : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (user["points"] ?? 0) / 1500,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.green,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    user["trend"] == "up"
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 16,
                                    color: user["trend"] == "up"
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user["trend"] == "up"
                                        ? "Rising"
                                        : "Falling",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: user["trend"] == "up"
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${user["points"]?.toString() ?? "0"} pts",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // 👤 YOUR RANK PINNED
        Positioned(
          bottom: 10,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff1F4037), Color(0xff99F2C8)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.2), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text("YOU"),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Your Rank: 12",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Text(
                  "430 pts",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _podiumUser(
    Map<String, dynamic> user,
    int rank,
    double size,
    Color borderColor,
  ) {
    bool isWinner = rank == 1;

    return Column(
      children: [
        if (isWinner)
          TweenAnimationBuilder(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.9, end: 1.2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 36,
                ),
              );
            },
          )
        else
          Icon(Icons.workspace_premium, color: borderColor, size: 26),

        const SizedBox(height: 6),

        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isWinner
                    ? const LinearGradient(
                        colors: [Color(0xffffd700), Color(0xffffa000)],
                      )
                    : null,
              ),
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: borderColor.withOpacity(.25),
                child: CircleAvatar(
                  radius: size / 2 - 4,
                  backgroundColor: Colors.purple.shade100,
                  child: Text(
                    user["initial"]?.toString() ?? "",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -8,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: borderColor,
                child: Text(
                  "$rank",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          user["name"]?.toString() ?? "",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 4),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${user["points"]?.toString() ?? "0"} pts",
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xff0F2027),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Text(
            "Leaderboard",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge!.color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(text: "City"),
              Tab(text: "National"),
              Tab(text: "Global"),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff0F2027), Color(0xff203A43), Color(0xff2C5364)],
            ),
          ),
          child: TabBarView(
            children: [
              _buildLeaderboard(),
              _buildLeaderboard(),
              _buildLeaderboard(),
            ],
          ),
        ),
      ),
    );
  }
}

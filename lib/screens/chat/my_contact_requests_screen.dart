import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../services/cache_service.dart';

class MyContactRequestsScreen extends StatefulWidget {
  const MyContactRequestsScreen({super.key});

  @override
  State<MyContactRequestsScreen> createState() =>
      _MyContactRequestsScreenState();
}

class _MyContactRequestsScreenState extends State<MyContactRequestsScreen> {
  List<dynamic> requests = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  static const String _cacheKey = 'my_contact_requests';

  Future<void> loadRequests() async {
    // ── Step 1: Show cached data immediately ─────────────────────────────
    final cached = await CacheService.getList(
      _cacheKey,
      ttlMs: CacheService.ttlMedium,
    );
    if (cached != null && mounted) {
      setState(() {
        requests = cached;
        loading = false;
      });
    } else {
      setState(() => loading = true);
    }

    // ── Step 2: Fetch fresh from backend ──────────────────────────────────
    final data = await ApiService.getMyContactRequests();
    if (data.isNotEmpty) {
      await CacheService.setList(_cacheKey, data);
    }
    if (mounted) {
      setState(() {
        requests = data;
        loading = false;
      });
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return "-";

    try {
      final dt = DateTime.parse(value.toString());

      return DateFormat("dd MMM yyyy • hh:mm a").format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  Widget statusChip(String status) {
    status = status.toUpperCase();

    Color color;
    IconData icon;

    switch (status) {
      case "ACCEPTED":
        color = const Color(0xff00C853);
        icon = Icons.check_circle_rounded;
        break;

      case "REJECTED":
        color = const Color(0xffFF5252);
        icon = Icons.cancel_rounded;
        break;

      default:
        color = const Color(0xffFF9800);
        icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.18),

        borderRadius: BorderRadius.circular(30),

        border: Border.all(color: color.withOpacity(.35)),

        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget glassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),

            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(.55),
                Colors.white.withOpacity(.22),
              ],
            ),

            border: Border.all(
              color: Colors.white.withOpacity(.55),
              width: 1.2,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget avatar(String name) {
    final letter = name.isEmpty ? "?" : name.substring(0, 1).toUpperCase();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,

        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff7EA7FF), Color(0xff4F7DFF)],
        ),

        border: Border.all(color: Colors.white.withOpacity(.75), width: 2),

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget infoTile(IconData icon, Color color, String text) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.50),

            borderRadius: BorderRadius.circular(12),

            border: Border.all(color: Colors.white.withOpacity(.40)),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget summaryCard(IconData icon, Color color, String title, int count) {
    return Expanded(
      child: glassCard(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),

              const SizedBox(height: 10),

              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "$count",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRequestCard(dynamic item) {
    final name = item["ToLoginid"] ?? "";
    final status = item["Status"] ?? "PENDING";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: glassCard(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  avatar(name),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: .2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  statusChip(status),
                ],
              ),

              const SizedBox(height: 14),

              Divider(color: Colors.white.withOpacity(.45), thickness: 1),

              const SizedBox(height: 14),

              infoTile(
                Icons.send_rounded,
                Colors.blue,
                "Requested : ${formatDate(item["RequestedOn"])}",
              ),

              if (item["AcceptedOn"] != null) ...[
                const SizedBox(height: 10),

                infoTile(
                  Icons.check_circle,
                  Colors.green,
                  "Accepted : ${formatDate(item["AcceptedOn"])}",
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = requests
        .where((e) => (e["Status"] ?? "") == "PENDING")
        .length;

    final accepted = requests
        .where((e) => (e["Status"] ?? "") == "ACCEPTED")
        .length;
    final rejected = requests
        .where((e) => (e["Status"] ?? "").toUpperCase() == "REJECTED")
        .length;
    final total = requests.length;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xffEEF4FF),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "My Chat Requests",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),

      body: Stack(
        children: [
          /// Background Gradient
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xffEEF4FF),
                  Color(0xffF7F9FF),
                  Color(0xffFFFFFF),
                ],
              ),
            ),
          ),

          /// Decorative Blur Circle
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withOpacity(.05),
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(.03),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(.08),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.20),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(.25)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : requests.isEmpty
                ? RefreshIndicator(
                    onRefresh: loadRequests,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        const SizedBox(height: 80),

                        Icon(
                          Icons.people_alt_rounded,
                          size: 90,
                          color: Colors.white.withOpacity(.85),
                        ),

                        const SizedBox(height: 25),

                        const Center(
                          child: Text(
                            "No Contact Requests",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Center(
                          child: Text(
                            "New chat requests will appear here.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: loadRequests,

                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),

                          padding: const EdgeInsets.fromLTRB(18, 90, 18, 24),

                          itemCount: requests.length + 1,

                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 350),
                                tween: Tween(begin: 0, end: 1),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 30 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    children: [
                                      summaryCard(
                                        Icons.schedule_rounded,
                                        const Color(0xffFF9800),
                                        "Pending",
                                        pending,
                                      ),
                                      const SizedBox(width: 12),
                                      summaryCard(
                                        Icons.check_circle_rounded,
                                        const Color(0xff00C853),
                                        "Accepted",
                                        accepted,
                                      ),
                                      const SizedBox(width: 12),
                                      summaryCard(
                                        Icons.cancel_rounded,
                                        Colors.red,
                                        "Rejected",
                                        rejected,
                                      ),
                                      const SizedBox(width: 12),
                                      summaryCard(
                                        Icons.people_alt_rounded,
                                        Colors.blue,
                                        "Total",
                                        total,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final item = requests[index - 1];

                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 350 + ((index - 1) * 120),
                              ),

                              tween: Tween(begin: 0, end: 1),

                              curve: Curves.easeOutCubic,

                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,

                                  child: Transform.translate(
                                    offset: Offset(0, 30 * (1 - value)),

                                    child: child,
                                  ),
                                );
                              },

                              child: buildRequestCard(item),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

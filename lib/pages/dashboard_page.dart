// dashboard_page.dart
// Improved & cleaned-up version of your original DashboardPage
// - Preserves glassmorphism, tilt/parallax, gradients & shadows
// - Fixes deprecated Color.withOpacity -> Color.withValues(alpha: ...)
// - Avoids exposing private types in public APIs (BirthdayUser is public)
// - Keeps all Firestore streams for announcements, events, news, users (birthdays)
// - Adds comments and small refactors for readability and reuse

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mcaverse/pages/academics_page.dart';
import 'filter_page.dart';

/// Public model to represent a birthday user.
/// Made public to avoid exposing private types in a public API.
class BirthdayUser {
  final String name;
  final String year; // yearOfStudy or similar display value
  final String avatar;

  const BirthdayUser({
    required this.name,
    required this.year,
    required this.avatar,
  });
}

/// Main dashboard page (stateful so we can use `mounted` checks and local state later)
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    // Current authenticated user (may be null if not signed in)
    final user = FirebaseAuth.instance.currentUser;

    // Friendly date string (e.g. "Tue, 23 Sep 2025")
    final today = DateTime.now();
    final dateStr =
        "${wdayAbbr(today.weekday)}, ${today.day} ${monthAbbr(today.month)} ${today.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          const _BackgroundBlob(), // decorative background
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- Header / Greeting ----------------
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("users")
                              .doc(user?.uid)
                              .snapshots(),
                          builder: (context, snap) {
                            final data =
                                (snap.data?.data() as Map<String, dynamic>?) ??
                                {};
                            final name = (data["name"] as String?)?.trim();
                            final greetingName = (name == null || name.isEmpty)
                                ? "there"
                                : name;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hi $greetingName 👋",
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade400,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Welcome to McaVerse",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const CircleAvatar(
                        radius: 28,
                        backgroundImage: AssetImage(
                          "assets/images/avatar_placeholder.png",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ---------------- Quick Access Grid ----------------
                  _SectionHeader(
                    title: "Quick Access",
                    trailing: TextButton(
                      onPressed: () {
                        // optional: open customize bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Customize clicked")),
                        );
                      },
                      child: const Text("Customize"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: [
                      _QuickCard(
                        title: "Academics",
                        icon: Icons.school_rounded,
                        color: Colors.indigo,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AcademicsPage(),
                          ),
                        ),
                      ),
                      _QuickCard(
                        title: "Events",
                        icon: Icons.event_rounded,
                        color: Colors.purple,
                        onTap: () => _go(context, "/events"),
                        badge: "Live",
                      ),
                      _QuickCard(
                        title: "Announcements",
                        icon: Icons.campaign_rounded,
                        color: Colors.redAccent,
                        onTap: () => _go(context, "/announcements"),
                      ),
                      _QuickCard(
                        title: "Donation",
                        icon: Icons.volunteer_activism_rounded,
                        color: Colors.pink,
                        onTap: () => _go(context, "/donation"),
                      ),
                      _QuickCard(
                        title: "Filter Users",
                        icon: Icons.filter_alt_rounded,
                        color: Colors.blueGrey,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FilterPage()),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ---------------- Announcements (Firestore) ----------------
                  const _SectionHeader(title: "Announcements"),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("announcements")
                        .orderBy("timestamp", descending: true)
                        .limit(6)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text(
                          "No announcements yet.",
                          style: TextStyle(color: Colors.blueGrey.shade600),
                        );
                      }
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return _AnnouncementTile(
                            title: (d["title"] ?? "Untitled").toString(),
                            subtitle: (d["subtitle"] ?? "").toString(),
                            color: Colors.redAccent,
                            onTap: () =>
                                _go(context, "/announcements/${doc.id}"),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ---------------- Upcoming Events (horizontal) ----------------
                  const _SectionHeader(title: "Upcoming Events"),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("events")
                          .orderBy("date")
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "No upcoming events.",
                              style: TextStyle(color: Colors.blueGrey.shade600),
                            ),
                          );
                        }
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            return _EventCard(
                              title: (d["title"] ?? "Event").toString(),
                              date: _formatEventDate(d["date"]),
                              color: Colors.blue,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------------- Birthdays (derived from users collection) ----------------
                  const _SectionHeader(title: "Birthdays Today"),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("users")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final today = DateTime.now();
                      // Map Firestore docs into BirthdayUser only for those matching today
                      final users = (snapshot.data?.docs ?? [])
                          .where((doc) => _isBirthdayToday(doc['dob'], today))
                          .map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            return BirthdayUser(
                              name: (d["name"] ?? "Unknown").toString(),
                              year: (d["yearOfStudy"] ?? "").toString(),
                              avatar:
                                  (d["profileImageUrl"] ??
                                          "https://ui-avatars.com/api/?name=${Uri.encodeComponent((d['name'] ?? 'U').toString())}")
                                      .toString(),
                            );
                          })
                          .toList();

                      if (users.isEmpty) {
                        return Text(
                          "No birthdays today 🎉",
                          style: TextStyle(color: Colors.blueGrey.shade600),
                        );
                      }
                      return BirthdayRow(users: users);
                    },
                  ),

                  const SizedBox(height: 24),

                  // ---------------- Tech News Feed ----------------
                  const _SectionHeader(title: "Tech News Feed"),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("news")
                        .orderBy("timestamp", descending: true)
                        .limit(8)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text(
                          "No news yet.",
                          style: TextStyle(color: Colors.blueGrey.shade600),
                        );
                      }
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return _NewsCard(
                            source: (d["source"] ?? "Unknown").toString(),
                            title: (d["title"] ?? "No Title").toString(),
                            onTap: () => _go(context, "/news/${doc.id}"),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // ---------------- Quick Links ----------------
                  const _SectionHeader(title: "Quick Links"),
                  const SizedBox(height: 10),
                  _QuickLinksRow(
                    links: const [
                      _QuickLink("Classroom", Icons.class_rounded),
                      _QuickLink("Library", Icons.local_library_rounded),
                      _QuickLink("Website", Icons.public_rounded),
                      _QuickLink("Placements", Icons.work_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple helper to surface navigation routes (currently placeholder)
  static void _go(BuildContext context, String route) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Navigate → $route")));
  }

  // Formats events stored as Timestamp, DateTime or string "yyyy-mm-dd" etc.
  static String _formatEventDate(dynamic val) {
    if (val == null) return "";
    if (val is Timestamp) {
      final dt = val.toDate();
      return "${monthAbbr(dt.month)} ${dt.day}";
    }
    if (val is DateTime) {
      return "${monthAbbr(val.month)} ${val.day}";
    }
    final s = val.toString();
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
    final m = iso.firstMatch(s);
    if (m != null) {
      final month = int.tryParse(m.group(2) ?? "0") ?? 0;
      final day = int.tryParse(m.group(3) ?? "0") ?? 0;
      return "${monthAbbr(month)} $day";
    }
    return s;
  }
}

/* ----------------------------- Helpers / Decor ----------------------------- */

/// Month abbreviation without intl
String monthAbbr(int m) {
  const mm = [
    "",
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
  if (m < 1 || m > 12) return "";
  return mm[m];
}

/// Weekday abbreviation without intl
String wdayAbbr(int w) {
  const wd = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  if (w < 1 || w > 7) return "";
  return wd[w];
}

/// Robust birthday checker (handles Timestamp, DateTime, "yyyy-mm-dd", "dd/mm", "dd-mm", compact digits)
bool _isBirthdayToday(dynamic dob, DateTime today) {
  if (dob == null) return false;

  // Timestamp
  if (dob is Timestamp) {
    final dt = dob.toDate();
    return dt.day == today.day && dt.month == today.month;
  }

  // DateTime
  if (dob is DateTime) {
    return dob.day == today.day && dob.month == today.month;
  }

  final s = dob.toString().trim();
  if (s.isEmpty) return false;

  // ISO yyyy-mm-dd
  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$');
  final mIso = iso.firstMatch(s);
  if (mIso != null) {
    final mm = int.tryParse(mIso.group(2) ?? "0") ?? 0;
    final dd = int.tryParse(mIso.group(3) ?? "0") ?? 0;
    return dd == today.day && mm == today.month;
  }

  // dd-mm or dd/mm or d-m
  final dm = RegExp(r'^(\d{1,2})[-/](\d{1,2})$');
  final mDm = dm.firstMatch(s);
  if (mDm != null) {
    final dd = int.tryParse(mDm.group(1)!) ?? -1;
    final mm = int.tryParse(mDm.group(2)!) ?? -1;
    return dd == today.day && mm == today.month;
  }

  // Compact digits like "66" -> 6/6, "1309" -> 13/09
  final digits = RegExp(r'^\d{2,4}$');
  if (digits.hasMatch(s)) {
    int dd = -1, mm = -1;
    if (s.length == 2) {
      dd = int.parse(s[0]);
      mm = int.parse(s[1]);
    } else if (s.length == 3) {
      dd = int.parse(s.substring(0, 2));
      mm = int.parse(s.substring(2));
    } else if (s.length == 4) {
      dd = int.parse(s.substring(0, 2));
      mm = int.parse(s.substring(2, 4));
    }
    if (dd > 0 && mm > 0) {
      return dd == today.day && mm == today.month;
    }
  }

  return false;
}

/* ----------------------------- Background Blob ---------------------------- */

class _BackgroundBlob extends StatelessWidget {
  const _BackgroundBlob();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _BlobPainter(), size: Size.infinite),
    );
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    final g1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEEF5FF), Color(0xFFF8FAFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, g1);

    // Soft blurred blobs using precise alpha values
    final paint = Paint()
      ..color = const Color(0xFFCCE0FF).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    final paint2 = Paint()
      ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    canvas.drawCircle(Offset(size.width * .15, size.height * .12), 90, paint);
    canvas.drawCircle(Offset(size.width * .9, size.height * .18), 120, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/* -------------------------------- Sections -------------------------------- */

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/* --------------------------------- Glass Card ----------------------------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xBFFFFFFF),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: child,
    );
  }
}

/* ------------------------------ Tilt 3D effect ---------------------------- */

class _Tilt3D extends StatefulWidget {
  final Widget child;
  const _Tilt3D({required this.child});

  @override
  State<_Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<_Tilt3D> {
  double _rx = 0, _ry = 0, _z = 0;

  void _reset() => setState(() {
    _rx = 0;
    _ry = 0;
    _z = 0;
  });

  void _update(Offset localPos, Size size) {
    final dx = (localPos.dx - size.width / 2) / (size.width / 2);
    final dy = (localPos.dy - size.height / 2) / (size.height / 2);

    setState(() {
      _ry = dx * 0.22;
      _rx = -dy * 0.22;
      _z = (dx.abs() + dy.abs()) * 6;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 180),
      tween: Tween(begin: 0, end: _z),
      builder: (_, elevation, child) {
        return Listener(
          onPointerMove: (e) {
            final rb = context.findRenderObject() as RenderBox?;
            if (rb == null) return;
            final local = rb.globalToLocal(e.position);
            _update(local, rb.size);
          },
          onPointerUp: (_) => _reset(),
          onPointerCancel: (_) => _reset(),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateX(_rx)
              ..rotateY(_ry)
              ..translate(0.0, 0.0, elevation),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/* ------------------------------ Quick Card -------------------------------- */

class _QuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return _Tilt3D(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 40, color: color),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------------------- Announcement tile -------------------------- */

class _AnnouncementTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AnnouncementTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Tilt3D(
      child: _GlassCard(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.campaign_rounded, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}

/* --------------------------- Horizontal Event Card ------------------------ */

class _EventCard extends StatelessWidget {
  final String title;
  final String date;
  final Color color;

  const _EventCard({
    required this.title,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: _Tilt3D(
          child: _GlassCard(
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 120,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.event_rounded, color: color, size: 22),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            date,
                            style: TextStyle(color: Colors.blueGrey.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* --------------------------------- Polls --------------------------------- */

// Poll UI kept simple and reusable; you can wire options to Firestore later.
class _PollItem extends StatelessWidget {
  final String question;
  final List<String> options;

  const _PollItem({required this.question, required this.options});

  @override
  Widget build(BuildContext context) {
    return _PollBox(question: question, options: options);
  }
}

class _PollBox extends StatefulWidget {
  final String question;
  final List<String> options;

  const _PollBox({required this.question, required this.options});

  @override
  State<_PollBox> createState() => _PollBoxState();
}

class _PollBoxState extends State<_PollBox> {
  String? selected;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.options.map((o) {
              final active = o == selected;
              return ChoiceChip(
                label: Text(o),
                selected: active,
                onSelected: (_) => setState(() => selected = o),
                selectedColor: Colors.indigo.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.indigo : Colors.black87,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: selected == null
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("You voted: $selected")),
                      );
                    },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text("Vote"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------ Birthday Row ------------------------------ */

class BirthdayRow extends StatelessWidget {
  // Accept public BirthdayUser model
  final List<BirthdayUser> users;
  const BirthdayRow({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Text(
        "No birthdays today 🎉",
        style: TextStyle(color: Colors.blueGrey.shade600),
      );
    }

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final u = users[i];
          return Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.pinkAccent.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(u.avatar),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${u.name} • ${u.year}",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.cake_rounded, color: Colors.pinkAccent),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* -------------------------------- News Card ------------------------------- */

class _NewsCard extends StatelessWidget {
  final String source;
  final String title;
  final VoidCallback onTap;

  const _NewsCard({
    required this.source,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Tilt3D(
      child: _GlassCard(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blueGrey.shade50,
            child: const Icon(Icons.newspaper_rounded),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(source),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}

/* ------------------------------ Quick Links Row --------------------------- */

class _QuickLink {
  final String label;
  final IconData icon;
  const _QuickLink(this.label, this.icon);
}

class _QuickLinksRow extends StatelessWidget {
  final List<_QuickLink> links;
  const _QuickLinksRow({required this.links});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: links.map((l) {
        return _Tilt3D(
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Opening ${l.label}")));
            },
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.blueGrey.shade50, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(l.icon, size: 18, color: Colors.blueGrey.shade700),
                  const SizedBox(width: 8),
                  Text(
                    l.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/* ------------------------------ Small bits -------------------------------- */

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget? trailing;

  const _CardTitle({
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

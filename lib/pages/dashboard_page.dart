import 'dart:math' as math;
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr =
        "${_wday(today.weekday)}, ${today.day} ${_month(today.month)} ${today.year}";

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          // soft gradient bg
          const _BackgroundBlob(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header / Greeting
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hi there 👋",
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

                  // Quick access grid (3D cards)
                  _SectionHeader(
                    title: "Quick Access",
                    trailing: TextButton(
                      onPressed: () {},
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
                        title: "Q Papers",
                        icon: Icons.description,
                        color: Colors.indigo,
                        onTap: () => _go(context, "/questions"),
                      ),
                      _QuickCard(
                        title: "Notes",
                        icon: Icons.menu_book_rounded,
                        color: Colors.green,
                        onTap: () => _go(context, "/notes"),
                      ),
                      _QuickCard(
                        title: "Syllabus",
                        icon: Icons.list_alt_rounded,
                        color: Colors.orange,
                        onTap: () => _go(context, "/syllabus"),
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
                        title: "Recorded",
                        icon: Icons.play_circle_fill_rounded,
                        color: Colors.teal,
                        onTap: () => _go(context, "/recordings"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Announcements
                  const _SectionHeader(title: "Announcements"),
                  const SizedBox(height: 12),
                  _AnnouncementTile(
                    title: "Hackathon 2025 – Registrations Live",
                    subtitle: "Register by Aug 30 • Dept. Lab",
                    color: Colors.redAccent,
                    onTap: () => _go(context, "/announcements/1"),
                  ),
                  _AnnouncementTile(
                    title: "DBMS Notes (2nd Yr) Uploaded",
                    subtitle: "Unit 1–3 added • Dr. Meera",
                    color: Colors.orange,
                    onTap: () => _go(context, "/announcements/2"),
                  ),
                  _AnnouncementTile(
                    title: "Seminar: Cloud Native 101",
                    subtitle: "Sep 10, 10 AM • Auditorium",
                    color: Colors.indigo,
                    onTap: () => _go(context, "/announcements/3"),
                  ),

                  const SizedBox(height: 24),

                  // Upcoming Events (Horizontal)
                  const _SectionHeader(title: "Upcoming Events"),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _EventCard(
                          title: "Tech Talk",
                          date: "Aug 30",
                          color: Colors.blue,
                        ),
                        _EventCard(
                          title: "Workshop",
                          date: "Sep 10",
                          color: Colors.green,
                        ),
                        _EventCard(
                          title: "Freshers Fest",
                          date: "Sep 20",
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Community (Polls + Birthday Alerts)
                  const _SectionHeader(title: "Community"),
                  const SizedBox(height: 12),
                  _Tilt3D(
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardTitle(
                            icon: Icons.poll_rounded,
                            color: Colors.deepPurple,
                            title: "Polls & Surveys",
                            trailing: TextButton(
                              onPressed: () => _go(context, "/polls"),
                              child: const Text("View all"),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const _PollItem(
                            question:
                                "Which domain should next workshop focus on?",
                            options: ["Flutter", "GenAI", "Cloud", "DSA"],
                          ),
                          const SizedBox(height: 12),
                          const _PollItem(
                            question: "Preferred hackathon duration?",
                            options: ["12h", "24h", "48h"],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Tilt3D(
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardTitle(
                            icon: Icons.cake_rounded,
                            color: Colors.pinkAccent,
                            title: "Birthdays Today",
                            trailing: TextButton(
                              onPressed: () =>
                                  _go(context, "/community/birthdays"),
                              child: const Text("Celebrate"),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const _BirthdayRow(
                            users: [
                              _BirthdayUser(
                                name: "Rohith",
                                year: "2nd Yr",
                                avatar: "assets/images/avatar_placeholder.png",
                              ),
                              _BirthdayUser(
                                name: "Aisha",
                                year: "1st Yr",
                                avatar: "assets/images/avatar_placeholder.png",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tech News Feed
                  const _SectionHeader(title: "Tech News Feed"),
                  const SizedBox(height: 12),
                  _NewsCard(
                    source: "The Verge",
                    title:
                        "Flutter 4.0: New rendering boosts performance on web",
                    onTap: () => _go(context, "/news/1"),
                  ),
                  _NewsCard(
                    source: "Hacker News",
                    title: "Open-source GenAI tooling for on-device inference",
                    onTap: () => _go(context, "/news/2"),
                  ),
                  _NewsCard(
                    source: "InfoQ",
                    title: "Serverless patterns for event-driven microservices",
                    onTap: () => _go(context, "/news/3"),
                  ),

                  const SizedBox(height: 24),

                  // Quick Links
                  const _SectionHeader(title: "Quick Links"),
                  const SizedBox(height: 10),
                  const _QuickLinksRow(
                    links: [
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

  static String _month(int m) {
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
    return mm[m];
  }

  static String _wday(int w) {
    const wd = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return wd[w];
  }

  static void _go(BuildContext context, String route) {
    // Plug your actual routes here
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Navigate → $route")));
  }
}

/* ----------------------------- Decor / Common ----------------------------- */

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
    final g1 = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEEF5FF), Color(0xFFF8FAFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, g1);

    final paint = Paint()
      ..color = const Color(0xFFCCE0FF).withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    final paint2 = Paint()
      ..color = const Color(0xFFB3E5FC).withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    canvas.drawCircle(Offset(size.width * .15, size.height * .1), 90, paint);
    canvas.drawCircle(Offset(size.width * .9, size.height * .18), 120, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing, super.key});

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

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(.75),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: child,
    );
  }
}

/// Reusable 3D tilt wrapper (subtle parallax on drag/hover)
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
      _ry = dx * 0.22; // rotate Y by x movement
      _rx = -dy * 0.22; // rotate X by y movement
      _z = (dx.abs() + dy.abs()) * 6; // small elevation on edges
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
          onPointerDown: (_) {},
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

/* ------------------------------ Quick Access ------------------------------ */

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
              colors: [color.withOpacity(.1), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(.18),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: color.withOpacity(.18)),
          ),
          child: Stack(
            children: [
              // Decorative corner arc
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(.08),
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

/* ---------------------------- Announcements list -------------------------- */

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
            backgroundColor: color.withOpacity(.12),
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
                selectedColor: Colors.indigo.withOpacity(.15),
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

/* ------------------------------ Birthday row ------------------------------ */

class _BirthdayUser {
  final String name;
  final String year;
  final String avatar;
  const _BirthdayUser({
    required this.name,
    required this.year,
    required this.avatar,
  });
}

class _BirthdayRow extends StatelessWidget {
  final List<_BirthdayUser> users;
  const _BirthdayRow({required this.users});

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
          return _Tilt3D(
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(.12),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.pinkAccent.withOpacity(.18)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: AssetImage(u.avatar),
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
            ),
          );
        },
      ),
    );
  }
}

/* ------------------------------- News cards -------------------------------- */

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

/* ------------------------------ Quick Links -------------------------------- */

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
                    color: Colors.black.withOpacity(.06),
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
          backgroundColor: color.withOpacity(.12),
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

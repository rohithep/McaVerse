import 'package:flutter/material.dart';

class AcademicsPage extends StatelessWidget {
  const AcademicsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Academics"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _FolderCard(
              title: "Q Papers",
              icon: Icons.description,
              color: Colors.blue,
              onTap: () {
                // Navigate to Q Papers list page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlaceholderPage(title: "Q Papers"),
                  ),
                );
              },
            ),
            _FolderCard(
              title: "Notes",
              icon: Icons.menu_book_rounded,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlaceholderPage(title: "Notes"),
                  ),
                );
              },
            ),
            _FolderCard(
              title: "Syllabus",
              icon: Icons.list_alt_rounded,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlaceholderPage(title: "Syllabus"),
                  ),
                );
              },
            ),
            _FolderCard(
              title: "Recorded",
              icon: Icons.play_circle_fill_rounded,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PlaceholderPage(title: "Recorded Lectures"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FolderCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          // ignore: deprecated_member_use
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder page for now — later replace with actual data (Firestore / files)
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text("Content for $title will appear here")),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_management.dart';
import 'pages/dashboard_page.dart';
import 'pages/messages_page.dart';
import 'pages/gallery_page.dart';
import 'pages/academics_page.dart';
import 'pages/splash_screen.dart';
import 'pages/faculty/faculty_homepage.dart';
import 'pages/alumini/alumni_dashboard.dart';
import 'pages/faculty/faculty_academics_page.dart';
import 'pages/faculty/faculty_dashboard_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'McaVerse',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/splash',
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/splash': (context) => McaVerseSplashScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfileManagementPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/messages': (context) => const MessagesPage(),
        '/academics': (context) => const AcademicsPage(),
        '/facultyDashboard': (context) => const FacultyDashboardPage(),
        '/alumniDashboard': (context) => const AlumniDashboardPage(),
        '/facultyacademics': (context) => const FacultyAcademicsPage(),
        '/facultyhome': (context) => const FacultyHomepage(),
        '/gallery':(context)=> const GalleryPage(),
       

        // add this
      },
    );
  }
}

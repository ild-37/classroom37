import 'package:flutter/material.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';
import '../home/join_course_page.dart';
import '../home_teacher/home_teacher.dart';
import '../home_teacher/create_course_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classroom App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/join_course': (context) => const JoinCoursePage(),
        '/home_teacher': (context) => const HomeTeacher(),
        '/create_course': (context) => const CreateCoursePage(),
      },
    );
  }
}

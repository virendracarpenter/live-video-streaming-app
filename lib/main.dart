import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streaming_app/providers/user_provider.dart';
import 'package:streaming_app/resources/auth_methods.dart';
import 'package:streaming_app/screens/home_screen.dart';
import 'package:streaming_app/screens/login_screen.dart';
import 'package:streaming_app/screens/onboarding_screen.dart';
import 'package:streaming_app/screens/signup_screen.dart';
import 'package:streaming_app/utils/colors.dart';
// import 'package:streaming_app/utils/colors.dart';
import 'package:streaming_app/widgets/loading_indicator.dart';
import 'models/user.dart' as model;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyBCJBjorhMRp1oHSPbM4RtNQ4017O9fXWY",
          authDomain: "live-streaming-app-project.firebaseapp.com",
          projectId: "live-streaming-app-project",
          storageBucket: "live-streaming-app-project.appspot.com",
          messagingSenderId: "719476651367",
          appId: "1:719476651367:web:2bd106c54e6e7d7d4bebc2"),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
    ),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Streaming',
      // theme: ThemeData.light().copyWith(
      //uncomment for light theme and change .dark() to .light()
      // scaffoldBackgroundColor: backgroundColor,
      // appBarTheme: AppBarTheme.of(context).copyWith(
      // backgroundColor: backgroundColor,
      // elevation: 20,
      // titleTextStyle: const TextStyle(
      // color: primaryColor,
      // fontSize: 18,
      // fontWeight: FontWeight.w600,
      // ),
      // centerTitle: true,
      // iconTheme: const IconThemeData(
      // color: primaryColor,
      // ),
      // ),
      // ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: Theme.of(context).colorScheme.copyWith(
              secondaryContainer: buttonColor,
            ),
      ),
      routes: {
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        SignupScreen.routeName: (context) => const SignupScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
      },
      home: FutureBuilder(
        future: AuthMethods()
            .getCurrentUser(FirebaseAuth.instance.currentUser != null
                ? FirebaseAuth.instance.currentUser!.uid
                : null)
            .then((value) {
          if (value != null) {
            Provider.of<UserProvider>(context, listen: false).setUser(
              model.User.fromMap(value),
            );
          }
          return value;
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const OnboardingScreen();
        },
      ),
    );
  }
}

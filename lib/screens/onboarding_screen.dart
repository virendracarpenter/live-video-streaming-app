import 'package:flutter/material.dart';
import 'package:streaming_app/responsive/responsive.dart';
import 'package:streaming_app/screens/login_screen.dart';
import 'package:streaming_app/screens/signup_screen.dart';
import 'package:streaming_app/widgets/custom_button.dart';

class OnboardingScreen extends StatelessWidget {
  static const routeName = '/onboarding';
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Responsive(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to\nGoLive',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: CustomButton(
                    onTap: () {
                      Navigator.pushNamed(context, LoginScreen.routeName);
                    },
                    text: "Log in"),
              ),
              CustomButton(
                  onTap: () {
                    Navigator.pushNamed(context, SignupScreen.routeName);
                  },
                  text: "Sign Up"),
            ],
          ),
        ),
      ),
    );
  }
}

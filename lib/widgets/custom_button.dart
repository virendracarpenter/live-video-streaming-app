import 'package:flutter/material.dart';
import 'package:streaming_app/utils/colors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onTap,
    required this.text,
  });
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        minimumSize: const Size(double.infinity, 50),
        foregroundColor: Colors.white,
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }
}

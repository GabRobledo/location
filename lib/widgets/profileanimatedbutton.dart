import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  AnimatedButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.lato(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        primary: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
    );
  }
}

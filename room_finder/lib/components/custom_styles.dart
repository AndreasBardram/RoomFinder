import 'package:flutter/material.dart';

/// Common InputDecoration for all TextFields.
InputDecoration customInputDecoration({required String labelText}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: const TextStyle(
      color: Color.fromARGB(255, 100, 100, 100),
      fontSize: 14,
    ),
    floatingLabelStyle: const TextStyle(
      color: Color.fromARGB(255, 100, 100, 100),
      fontSize: 14,
    ),
    border: const OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 180, 180, 180)),
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
    ),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 180, 180, 180)),
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
    ),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(255, 180, 180, 180)),
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
    ),
  );
}

/// Common ElevatedButton style.
ButtonStyle customElevatedButtonStyle() {
  return ElevatedButton.styleFrom(
    foregroundColor: Colors.black,      // Text color
    backgroundColor: Colors.white,      // Button background color
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    padding: const EdgeInsets.symmetric(vertical: 15.0),
    elevation: 2,
  );
}

/// Optional: if you frequently wrap your button in a Container,
/// you might create a helper widget that replicates the same look.
class CustomButtonContainer extends StatelessWidget {
  final Widget child;
  final double height;
  final EdgeInsets? margin;

  const CustomButtonContainer({
    super.key,
    required this.child,
    this.height = 50,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.only(left: 5.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

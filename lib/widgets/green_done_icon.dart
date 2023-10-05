import 'package:flutter/material.dart';
import '../values/values.dart';

class GreenDoneIcon extends StatelessWidget {
  const GreenDoneIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: HexColor.fromHex("78B462")),
          child: Icon(Icons.phone, color: Colors.white)),
    );
  }
}

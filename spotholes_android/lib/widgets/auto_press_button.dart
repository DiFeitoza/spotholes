import 'package:flutter/material.dart';

import '../models/spothole.dart';

class AutoPressButton extends StatefulWidget {
  final String textOnRegisterButton;
  final int timerInSeconds;
  final Function onRegister;

  const AutoPressButton(
      {super.key,
      required this.textOnRegisterButton,
      required this.onRegister,
      this.timerInSeconds = 10});

  @override
  AutoPressButtonState createState() => AutoPressButtonState();
}

class AutoPressButtonState extends State<AutoPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation _animation;

  autoRegisterSpothole() {
    widget.onRegister(Category.unitary, Type.pothole);
    Navigator.pop(context);
  }

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.timerInSeconds),
    );
    _animation = Tween(begin: 35.0, end: 100.0).animate(_animationController)
      ..addListener(
        () => setState(() {}),
      );
    _animationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        autoRegisterSpothole();
      }
    });
    _animationController.forward();
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: <Widget>[
          Container(
            width: _animation.value,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: [
                Color(int.parse("0xFF00C9FF")),
                Color(int.parse("0xFF002FE90")),
              ]),
            ),
          ),
          GestureDetector(
            onTap: () {
              autoRegisterSpothole();
            },
            child: Container(
              width: 100,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.transparent,
                border: Border.all(color: Colors.black26),
              ),
              child: Center(
                child: Text(
                  widget.textOnRegisterButton,
                  style: const TextStyle(fontWeight: FontWeight.w400),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

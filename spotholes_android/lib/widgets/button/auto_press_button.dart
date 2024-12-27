import 'package:flutter/material.dart';

class AutoPressButton extends StatefulWidget {
  final String textOnRegisterButton;
  final int timerInSeconds;
  final Function onPressButton;

  const AutoPressButton(
      {super.key,
      required this.textOnRegisterButton,
      required this.onPressButton,
      this.timerInSeconds = 10});

  @override
  AutoPressButtonState createState() => AutoPressButtonState();
}

class AutoPressButtonState extends State<AutoPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation _animation;

  pressButton() {
    // Ther order of the next two lines is important
    Navigator.pop(context);
    widget.onPressButton();
  }

  @override
  void initState() {
    super.initState();
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
        pressButton();
      }
    });
    _animationController.forward();
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
              pressButton();
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

import 'package:flutter/material.dart';

import '../../models/spothole.dart';
import '../../utilities/custom_icons.dart';
import '../auto_press_button.dart';

class RegisterSpotholeModal extends StatefulWidget {
  const RegisterSpotholeModal({
    super.key,
    required this.onRegister,
    required this.title,
    required this.textOnRegisterButton,
    this.isCountdown = true,
    this.timerInSeconds = 10,
    this.riskCategory = Category.unitary,
    this.riskType = Type.pothole,
  });

  final String title;
  final String textOnRegisterButton;
  final bool isCountdown;
  final int timerInSeconds;
  final Function onRegister;
  final Category riskCategory;
  final Type riskType;

  @override
  RegisterSpotholeModalState createState() => RegisterSpotholeModalState();
}

class RegisterSpotholeModalState extends State<RegisterSpotholeModal> {
  bool showButtons = true;
  late Category riskCategory = widget.riskCategory;
  late Type riskType = widget.riskType;

  void setRiskCategoryAndUpdateModal(Category category) {
    riskCategory = category;
    setState(() {
      showButtons = false;
    });
  }

  void registerSpotholeType(Type type) {
    widget.onRegister(riskCategory, type);
    Navigator.pop(context);
  }

  void registerSpotholeCurrentType() {
    widget.onRegister(riskCategory, riskType);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            height: 5.0,
            width: 50.0,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        if (showButtons)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOption(CustomIcons.riskCategoryUnitary, 'Buraco', () {
                setRiskCategoryAndUpdateModal(Category.unitary);
              }),
              _buildOption(CustomIcons.riskCategoryStrech, 'Trecho\nEsburacado',
                  () {
                setRiskCategoryAndUpdateModal(Category.strech);
              }),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOption(CustomIcons.riskTypePothole, 'Buraco', () {
                registerSpotholeType(Type.pothole);
              }),
              _buildOption(CustomIcons.riskTypeDeepHole, 'Buraco\nAcentuado',
                  () {
                registerSpotholeType(Type.deepHole);
              }),
              _buildOption(CustomIcons.riskTypeJagged, 'Pista\nIrregular', () {
                registerSpotholeType(Type.jagged);
              }),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (widget.isCountdown)
              AutoPressButton(
                onRegister: widget.onRegister,
                textOnRegisterButton: widget.textOnRegisterButton,
                timerInSeconds: widget.timerInSeconds,
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 40),
                ),
                onPressed: registerSpotholeCurrentType,
                child: Text(widget.textOnRegisterButton),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.red),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

Widget _buildOption(Image image, String text, VoidCallback onPressed) {
  return GestureDetector(
    onTap: onPressed,
    child: Column(
      children: [
        image,
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../models/spothole.dart';
import '../utilities/custom_icons.dart';
import '../widgets/auto_press_button.dart';

class RegisterSpotholeModal extends StatefulWidget {
  const RegisterSpotholeModal({super.key, required this.onRegister});

  final Function onRegister;

  @override
  RegisterSpotholeModalState createState() => RegisterSpotholeModalState();
}

class RegisterSpotholeModalState extends State<RegisterSpotholeModal> {
  bool showButtons = true;
  Category riskCategory = Category.unitary;
  Type riskType = Type.pothole;

  void updateOptions(Category category) {
    riskCategory = category;
    setState(() {
      showButtons = false; // Esconder os botões
    });
  }

  void registerSpotholeType(Type type) {
    widget.onRegister(riskCategory, type);
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Para alertar um risco, selecione:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                updateOptions(Category.unitary);
              }),
              _buildOption(CustomIcons.riskCategoryStrech, 'Trecho\nEsburacado',
                  () {
                updateOptions(Category.strech);
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
            AutoPressButton(onRegister: widget.onRegister),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
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

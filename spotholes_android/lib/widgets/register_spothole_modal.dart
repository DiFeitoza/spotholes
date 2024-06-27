import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotholes_android/mixins/register_spothole_mixin.dart';
import 'package:spotholes_android/widgets/auto_press_button.dart';
import 'package:spotholes_android/models/spothole.dart';

class RegisterSpotholeModal extends StatefulWidget {
  final LatLng latLng;

  const RegisterSpotholeModal({super.key, required this.latLng});

  @override
  RegisterSpotholeModalState createState() => RegisterSpotholeModalState();
}

class RegisterSpotholeModalState extends State<RegisterSpotholeModal>
    with RegisterSpothole {
  bool showButtons = true;
  Category riskCategory = Category.unitary;
  Type riskType = Type.pothole;

  Container customButton(
      {required String label, color, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void updateOptions(Category category) {
      riskCategory = category;
      setState(() {
        showButtons = false; // Esconder os botões
      });
    }

    void registerSpotholeType(Type type) {
      registerSpothole(widget.latLng, riskCategory, type);
      Navigator.pop(context);
    }

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
              _buildOption('assets/images/risks/categoria_buraco.png', 'Buraco',
                  () {
                updateOptions(Category.unitary);
              }),
              _buildOption(
                  'assets/images/risks/categoria_trecho_esburacado.png',
                  'Trecho\nEsburacado', () {
                updateOptions(Category.strech);
              }),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOption('assets/images/risks/buraco_na_pista.png', 'Buraco',
                  () {
                registerSpotholeType(Type.pothole);
              }),
              _buildOption('assets/images/risks/buraco_acentuado_na_pista.png',
                  'Buraco\nAcentuado', () {
                registerSpotholeType(Type.deepHole);
              }),
              _buildOption(
                  'assets/images/risks/pista_irregular.png', 'Pista\nIrregular',
                  () {
                registerSpotholeType(Type.jagged);
              }),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AutoPressButton(position: widget.latLng),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Cancelar
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

Widget _buildOption(String imagePath, String text, VoidCallback onPressed) {
  return GestureDetector(
    onTap: onPressed,
    child: Column(
      children: [
        Image.asset(imagePath, width: 70, height: 70), // Imagem
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center), // Texto referente à imagem
      ],
    ),
  );
}

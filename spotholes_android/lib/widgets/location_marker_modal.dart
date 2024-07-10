import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMarkerModal extends StatelessWidget {
  final LatLng position;
  final Function onRegister;

  const LocationMarkerModal(
      {super.key, required this.position, required this.onRegister});

  void _registerSpotholeModal(BuildContext context) {
    Navigator.pop(context);
    onRegister();
  }

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
                'Alfinete inserido',
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
        ListTile(
          leading: const Icon(Icons.place),
          title: const Text('Localização selecionada'),
          subtitle: Text(
            'Latitude: ${position.latitude}, Longitude: ${position.longitude}',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('Informações'),
        ),
        SizedBox(
          height: 70.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              customButton(
                  label: 'Rotas', color: Colors.green, onPressed: () {}),
              customButton(
                label: 'Alertar',
                onPressed: () => _registerSpotholeModal(context),
              ),
              customButton(label: 'Salvar', onPressed: () {}),
              customButton(label: 'Excluir', onPressed: () {}),
            ],
          ),
        )
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMarkerModal extends StatelessWidget {
  final LatLng latLng;

  const LocationMarkerModal({super.key, required this.latLng});

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
        ListTile(
          leading: const Icon(Icons.place),
          title: const Text('Localização selecionada'),
          subtitle: Text(
              'Latitude: ${latLng.latitude}, Longitude: ${latLng.longitude}'),
        ),
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('Informações'),
          // Adicione aqui o espaço para informações
        ),
        SizedBox(
          height: 70.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              // Adicione seus botões aqui
              customButton(
                  label: 'Rotas', color: Colors.green, onPressed: () {}),
              customButton(label: 'Salvar', onPressed: () {}),
              customButton(label: 'Cancelar', onPressed: () {}),
              customButton(label: 'Excluir', onPressed: () {}),
            ],
          ),
        )
      ],
    );
  }
}

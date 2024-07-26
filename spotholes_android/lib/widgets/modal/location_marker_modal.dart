import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:spotholes_android/controllers/base_map_controller.dart';
import 'package:spotholes_android/utilities/custom_snackbar.dart';

class LocationMarkerModal extends StatefulWidget {
  final LatLng position;
  final Function onRegister;

  const LocationMarkerModal(
      {super.key, required this.position, required this.onRegister});

  @override
  LocationMarkerModalState createState() => LocationMarkerModalState();
}

class LocationMarkerModalState extends State<LocationMarkerModal> {
  final _baseMapController = BaseMapController.instance;
  final title = "Alfinete inserido";
  String firstPlaceDetails = "";

  @override
  void initState() {
    getPlacemarksFromLatLng(widget.position);
    super.initState();
  }

  formmatedPlacemark(Placemark placemark) {
    final parts = [
      placemark.street,
      placemark.locality,
      placemark.subLocality,
      placemark.subAdministrativeArea,
      placemark.country,
    ].where((part) => part != '');

    String formatted = parts.join(', ');

    if (placemark.postalCode != null) {
      formatted += ' - ${placemark.postalCode}';
    }
    return formatted;
  }

  // formmatedPlacemark(Placemark placemark) {
  //   String formmated = '';
  //   if (placemark.street != null) {
  //     formmated += '${placemark.street}, ';
  //   }
  //   if (placemark.locality != null) {
  //     formmated += '${placemark.locality}, ';
  //   }
  //   if (placemark.subLocality != null) {
  //     formmated += '${placemark.subLocality}, ';
  //   }
  //   if (placemark.subAdministrativeArea != null) {
  //     formmated += '${placemark.subAdministrativeArea}, ';
  //   }
  //   if (placemark.country != null) {
  //     formmated += '${placemark.country}';
  //   }
  //   if (formmated.endsWith(', ')) {
  //     return formmated.substring(0, formmated.length - 2);
  //   }
  //   if (placemark.postalCode != null) {
  //     formmated += ' - ${placemark.postalCode}';
  //   }
  //   return formmated;
  // }

  getPlacemarksFromLatLng(LatLng latLng) async {
    try {
      await placemarkFromCoordinates(latLng.latitude, latLng.longitude).then(
        (placemarkList) {
          setState(() {
            firstPlaceDetails =
                'Próximo à ${formmatedPlacemark(placemarkList.first)}';
          });
          // for (var placemark in placemarkList) {
          //   placesDetails += '${formmatedPlaceMark(placemark)}\n';
          // }
        },
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        CustomSnackbar.show(
            context: context,
            message:
                'Não foi possível carregar as informações, verifique a conexão com a internet');
      });
    }
  }

  void _registerSpotholeModal(BuildContext context) {
    Navigator.pop(context);
    widget.onRegister();
  }

  _loadRoute(destinationLocation) {
    _baseMapController.removeMarkerByKey('selectedPlace');
    _baseMapController.loadRoute(destinationLocation);
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
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
          leading: const Icon(Icons.info),
          title: Text(
            'Informações',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(firstPlaceDetails),
        ),
        ListTile(
          leading: const Icon(Icons.place),
          title: Text(
            'Localização selecionada',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Text(
            'Latitude: ${widget.position.latitude}\n'
            'Longitude: ${widget.position.longitude}',
          ),
        ),
        SizedBox(
          height: 70.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              customButton(
                label: 'Rotas',
                color: Colors.green,
                onPressed: () => _loadRoute(widget.position),
              ),
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

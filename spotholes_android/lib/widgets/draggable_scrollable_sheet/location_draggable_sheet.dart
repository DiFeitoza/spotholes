import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../../controllers/base_map_controller.dart';
import '../../utilities/custom_snackbar.dart';
import '../custom_button.dart';

class LocationDraggableSheetController {
  Function(String)? updateData;

  void dispose() {
    updateData = null;
  }
}

class LocationDraggableSheet extends StatefulWidget {
  const LocationDraggableSheet({
    super.key,
    required this.controller,
    required this.onRegister,
    required this.position,
  });

  final LatLng position;
  final Function onRegister;
  final LocationDraggableSheetController controller;

  @override
  LocationDraggableSheetState createState() => LocationDraggableSheetState();
}

class LocationDraggableSheetState extends State<LocationDraggableSheet> {
  late LocationDraggableSheetController controller;
  final scrollController = ScrollController();
  final _baseMapController = BaseMapController.instance;

  @override
  void initState() {
    super.initState();
  }

  String title = "Alfinete inserido";
  String firstPlaceDetails = "";
  // String placesDetails = "";

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
                'Não foi possível carregar informações, verifique a conexão com a internet');
      });
    }
  }

  _loadRoute(destinationLocation) {
    _baseMapController.removeMarkerByKey('selectedPlace');
    _baseMapController.loadRoute(destinationLocation);
  }

  void _registerSpotholeModal(BuildContext context) {
    widget.onRegister();
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

  List<Widget> _horizontalListButtons(BuildContext context, position) {
    return [
      CustomButton(
        label: 'Rota',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => _loadRoute(position),
      ),
      CustomButton(
        label: 'Alertar',
        onPressed: () => _registerSpotholeModal(context),
      ),
      CustomButton(
        label: 'Salvar',
        onPressed: () {},
      ),
      CustomButton(
        label: 'Excluir',
        onPressed: () {},
      ),
    ];
  }

  void closeDraggable() {
    _baseMapController.closeDraggableSheet('longPressed');
  }

  @override
  Widget build(BuildContext context) {
    final change = signal(widget.position);
    effect(() {
      getPlacemarksFromLatLng(change.value);
    });

    return DraggableScrollableSheet(
      maxChildSize: 0.8,
      minChildSize: 0.25,
      initialChildSize: 0.25,
      snap: true,
      snapSizes: const [0.25, 0.5],
      builder: (BuildContext context, scrollController) {
        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).hintColor,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                      ),
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                SliverAppBar(
                  title: Text(title),
                  primary: false,
                  pinned: true,
                  centerTitle: false,
                  toolbarHeight: 80,
                  leadingWidth: 50,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(16),
                    child: Container(
                      color: Colors.white,
                      child: Text(
                        firstPlaceDetails,
                        // maxLines: 1,
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.place),
                    onPressed: () {},
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: closeDraggable,
                    ),
                  ],
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 60.0,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _horizontalListButtons(
                                  context, widget.position),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Divider(),
                ),
                const SliverAppBar(
                  title: Text("Mais Informações"),
                  centerTitle: true,
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      ListTile(
                        leading: const Icon(Icons.place),
                        title: Text(
                          'Localização Geográfica',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: 'Latitude:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              TextSpan(text: '${widget.position.latitude}\n'),
                              TextSpan(
                                text: 'Longitude:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              TextSpan(text: '${widget.position.longitude}\n'),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

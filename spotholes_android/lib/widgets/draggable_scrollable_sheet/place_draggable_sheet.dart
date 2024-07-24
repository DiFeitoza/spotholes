import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotholes_android/package/google_places_flutter/model/place_details.dart';

import '../../controllers/base_map_controller.dart';
import '../custom_button.dart';

class PlaceDraggableSheetController {
  Function(String)? updateData;

  void dispose() {
    updateData = null;
  }
}

class PlaceDraggableSheet extends StatefulWidget {
  const PlaceDraggableSheet(
      {super.key,
      required this.controller,
      required this.destinationLocation,
      required this.placeDetails});

  final PlaceDraggableSheetController controller;
  final LatLng destinationLocation;
  final PlaceDetails placeDetails;

  @override
  PlaceDraggableSheetState createState() => PlaceDraggableSheetState();
}

class PlaceDraggableSheetState extends State<PlaceDraggableSheet> {
  late ScrollController scrollController;
  late PlaceDraggableSheetController placeDraggableSheetController;
  final _baseMapController = BaseMapController.instance;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  _loadRoute(destinationLocation) {
    _baseMapController.removeMarkerByKey('selectedPlace');
    _baseMapController.loadRoute(destinationLocation);
  }

  List<Widget> _horizontalListButtons(
      BuildContext context, destinationLocation) {
    return [
      CustomButton(
        label: 'Rota',
        color: Colors.green,
        onPressed: () => _loadRoute(destinationLocation),
      ),
      CustomButton(
        label: 'Alertar',
        onPressed: () => _baseMapController.registerSpotholeModal(context,
            position: destinationLocation),
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
    _baseMapController.closePlaceDraggableSheet();
  }

  @override
  Widget build(BuildContext context) {
    Result placeDetailsResult = widget.placeDetails.result!;

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
                  title: Text(placeDetailsResult.name!),
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
                        placeDetailsResult.formattedAddress!,
                        // maxLines: 1,
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: Image.network(
                      placeDetailsResult.icon!,
                      fit: BoxFit.contain,
                    ),
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
                                  context, widget.destinationLocation),
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
                  delegate: SliverChildListDelegate([
                    if (placeDetailsResult.website != null &&
                        placeDetailsResult.url != null)
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text(
                          'Web',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            children: [
                              if (placeDetailsResult.website != null) ...[
                                const TextSpan(
                                  text: 'Site: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                    text: '${placeDetailsResult.website!}\n'),
                              ],
                              if (placeDetailsResult.url != null) ...[
                                const TextSpan(
                                  text: 'Gmaps: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: placeDetailsResult.url!)
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (placeDetailsResult.geometry?.location != null)
                      ListTile(
                        leading: const Icon(Icons.place),
                        title: const Text(
                          'Localização Geográfica',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Latitude: ${placeDetailsResult.geometry!.location!.lat}\n'
                          'Longitude: ${placeDetailsResult.geometry!.location!.lng}',
                        ),
                      ),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

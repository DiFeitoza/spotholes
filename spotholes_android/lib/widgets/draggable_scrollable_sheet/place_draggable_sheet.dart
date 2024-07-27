import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotholes_android/package/google_places_flutter/model/place_details.dart';

import '../../controllers/base_map_controller.dart';
import '../button/custom_button.dart';

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
      required this.position,
      required this.placeDetails});

  final PlaceDraggableSheetController controller;
  final LatLng position;
  final PlaceDetails placeDetails;

  @override
  PlaceDraggableSheetState createState() => PlaceDraggableSheetState();
}

class PlaceDraggableSheetState extends State<PlaceDraggableSheet> {
  final ScrollController scrollController = ScrollController();
  // late PlaceDraggableSheetController placeDraggableSheetController;
  final _baseMapController = BaseMapController.instance;
  late final _canvasColor = Theme.of(context).canvasColor;

  @override
  void initState() {
    super.initState();
  }

  _loadRoute(position) {
    _baseMapController.removeMarkerByKey('selectedPlace');
    _baseMapController.loadRoute(position);
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
        onPressed: () => _baseMapController.registerSpotholeModal(context,
            position: position),
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
    _baseMapController.closeDraggableSheet('selectedPlace');
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
            color: _canvasColor,
            border: Border.all(width: 0.5),
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
                  backgroundColor: _canvasColor,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(16),
                    child: Text(
                      placeDetailsResult.formattedAddress!,
                      // maxLines: 1,
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
                      if (placeDetailsResult.website != null &&
                          placeDetailsResult.url != null)
                        ListTile(
                          leading: const Icon(Icons.info),
                          title: Text(
                            'Web',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              children: [
                                if (placeDetailsResult.website != null) ...[
                                  TextSpan(
                                    text: 'Site: ',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  TextSpan(
                                      text: '${placeDetailsResult.website!}\n'),
                                ],
                                if (placeDetailsResult.url != null) ...[
                                  TextSpan(
                                    text: 'Gmaps: ',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
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
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                TextSpan(
                                    text:
                                        '${placeDetailsResult.geometry!.location!.lat}\n'),
                                TextSpan(
                                  text: 'Longitude:',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                TextSpan(
                                    text:
                                        '${placeDetailsResult.geometry!.location!.lng}\n'),
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

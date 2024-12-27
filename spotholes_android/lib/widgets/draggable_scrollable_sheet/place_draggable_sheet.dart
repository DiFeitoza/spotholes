import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/base_map_controller.dart';
import '../../main.dart';
import '../../package/google_places_flutter/model/place_details.dart';
import '../../utilities/app_routes.dart';
import '../button/custom_button.dart';

class PlaceDraggableSheetController {
  Function(String)? updateData;

  void dispose() {
    updateData = null;
  }
}

class PlaceDraggableSheet extends StatefulWidget {
  final LatLng position;
  final PlaceDetails placeDetails;

  final BaseMapController baseMapController;

  const PlaceDraggableSheet({
    super.key,
    required this.position,
    required this.placeDetails,
    required this.baseMapController,
  });

  @override
  PlaceDraggableSheetState createState() => PlaceDraggableSheetState();
}

class PlaceDraggableSheetState extends State<PlaceDraggableSheet> {
  final ScrollController scrollController = ScrollController();
  late final baseMapController = widget.baseMapController;

  late final _canvasColor = Theme.of(context).canvasColor;

  _loadRoute(position) {
    MyApp.navigatorKey.currentState?.pushNamed(
      AppRoutes.route,
      arguments: [baseMapController.currentLocationLatLng, position],
    );
  }

  List<Widget> _horizontalListButtons() {
    return [
      CustomButton(
        label: 'Rota',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => _loadRoute(widget.position),
      ),
      CustomButton(
        label: 'Alertar',
        onPressed: () =>
            baseMapController.registerSpotholeModal(position: widget.position),
      ),
    ];
  }

  void closeDraggable() {
    baseMapController.closeDraggableSheet('selectedPlace');
  }

  @override
  Widget build(BuildContext context) {
    Result placeDetailsResult = widget.placeDetails.result!;
    return DraggableScrollableSheet(
      maxChildSize: 0.6,
      minChildSize: 0.26,
      initialChildSize: 0.26,
      snap: true,
      snapSizes: const [0.26, 0.6],
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
                  centerTitle: true,
                  toolbarHeight: 80,
                  leadingWidth: 50,
                  backgroundColor: _canvasColor,
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
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(35),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text(
                        placeDetailsResult.formattedAddress!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
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
                              children: _horizontalListButtons(),
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
                SliverAppBar(
                  title: const Text("Mais Informações"),
                  backgroundColor: _canvasColor,
                  centerTitle: true,
                  leading: const Icon(Icons.info),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      if (placeDetailsResult.website != null &&
                          placeDetailsResult.url != null)
                        ListTile(
                          leading: const Icon(Icons.web),
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
                                  text: 'Latitude: ',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                TextSpan(
                                    text:
                                        '${placeDetailsResult.geometry!.location!.lat}\n'),
                                TextSpan(
                                  text: 'Longitude: ',
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

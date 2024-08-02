import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotholes_android/controllers/route_controller.dart';
import 'package:spotholes_android/package/google_places_flutter/model/place_details.dart';

import '../button/custom_button.dart';

class RouteDraggableSheetController {
  Function(String)? updateData;

  void dispose() {
    updateData = null;
  }
}

class RouteDraggableSheet extends StatefulWidget {
  const RouteDraggableSheet(
      {super.key,
      required this.controller,
      required this.destinationLocation,
      this.placeDetails,
      this.formattedPlacemark});

  final RouteDraggableSheetController controller;
  final PlaceDetails? placeDetails;
  final String? formattedPlacemark;
  final LatLng destinationLocation;

  @override
  RouteDraggableSheetState createState() => RouteDraggableSheetState();
}

class RouteDraggableSheetState extends State<RouteDraggableSheet> {
  final _routeController = RouteController.instance;
  late final _polylineResponse = _routeController.polylineResponseSignal.value;
  late final distance = _polylineResponse.distance;
  late final duration = _polylineResponse.duration;
  late final startAddress = _polylineResponse.startAddress;
  late final endAddress = _polylineResponse.endAddress;
  late final overviewPolyline = _polylineResponse.overviewPolyline;

  final ScrollController scrollController = ScrollController();
  late final _canvasColor = Theme.of(context).canvasColor;
  late final Result placeDetailsResult = widget.placeDetails!.result!;

  @override
  void initState() {
    super.initState();
  }

  List<Widget> _horizontalListButtons(BuildContext context, position) {
    return [
      CustomButton(
        label: 'Iniciar viagem',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => {},
      ),
      CustomButton(
        label: 'Voltar',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => {},
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      maxChildSize: 0.6,
      minChildSize: 0.28,
      initialChildSize: 0.28,
      snap: true,
      snapSizes: const [0.28, 0.6],
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
                  title: const Text('Detalhes da Rota'),
                  // title: Text(placeDetailsResult.name!),
                  primary: false,
                  pinned: true,
                  centerTitle: true,
                  toolbarHeight: 80,
                  backgroundColor: _canvasColor,
                  // leadingWidth: 50,
                  // leading: IconButton(
                  //   icon: Image.network(
                  //     placeDetailsResult.icon!,
                  //     fit: BoxFit.contain,
                  //   ),
                  //   onPressed: () {},
                  // ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(35),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Text(
                        '$duration ($distance)',
                        // placeDetailsResult.formattedAddress!,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.left,
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
                              children: _horizontalListButtons(
                                  context, widget.destinationLocation),
                            ),
                          )
                        ],
                      ),
                      Text(
                        'Origem: $startAddress\n➞\nDestino: $endAddress',
                        style: Theme.of(context).textTheme.bodyLarge,
                        // '- Overview Polyline: $overviewPolyline\n',
                      ),
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

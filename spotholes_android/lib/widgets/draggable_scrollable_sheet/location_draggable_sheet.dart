import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spotholes_android/utilities/app_routes.dart';

import '../../controllers/base_map_controller.dart';
import '../button/custom_button.dart';

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
    required this.formattedPlacemark,
  });

  final LatLng position;
  final Function onRegister;
  final LocationDraggableSheetController controller;
  final String formattedPlacemark;

  @override
  LocationDraggableSheetState createState() => LocationDraggableSheetState();
}

class LocationDraggableSheetState extends State<LocationDraggableSheet> {
  late LocationDraggableSheetController controller;
  final scrollController = ScrollController();
  final _baseMapController = BaseMapController.instance;
  late final _canvasColor = Theme.of(context).canvasColor;

  @override
  void initState() {
    super.initState();
  }

  void _registerSpotholeModal(BuildContext context) {
    widget.onRegister();
  }

  List<Widget> _horizontalListButtons(BuildContext context, position) {
    return [
      CustomButton(
        label: 'Rota',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => Navigator.of(context).pushNamed(
          AppRoutes.route,
          arguments: [_baseMapController.currentLocationLatLng, position],
        ),
      ),
      CustomButton(
        label: 'Alertar',
        onPressed: () => _registerSpotholeModal(context),
      ),
    ];
  }

  void closeDraggable() {
    _baseMapController.closeDraggableSheet('longPressed');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      maxChildSize: 0.5,
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
                  title: const Text('Alfinete Inserido'),
                  primary: false,
                  pinned: true,
                  centerTitle: true,
                  toolbarHeight: 80,
                  leadingWidth: 50,
                  backgroundColor: _canvasColor,
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
                  bottom: (widget.formattedPlacemark.isNotEmpty)
                      ? PreferredSize(
                          preferredSize: const Size.fromHeight(24),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              widget.formattedPlacemark,
                              style: Theme.of(context).textTheme.bodyLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      : null,
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
                SliverAppBar(
                  title: const Text("Mais Informações"),
                  backgroundColor: _canvasColor,
                  centerTitle: true,
                  leading: const Icon(Icons.info),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      ListTile(
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
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              TextSpan(text: '${widget.position.latitude}\n'),
                              TextSpan(
                                text: 'Longitude: ',
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

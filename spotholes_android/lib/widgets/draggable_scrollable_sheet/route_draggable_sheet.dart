import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/base_map_controller.dart';
import '../button/custom_button.dart';

class RouteDraggableSheetController {
  Function(String)? updateData;

  void dispose() {
    updateData = null;
  }
}

class RouteDraggableSheet extends StatefulWidget {
  const RouteDraggableSheet(
      {super.key, required this.controller, required this.destinationLocation});

  final RouteDraggableSheetController controller;
  final LatLng destinationLocation;

  @override
  RouteDraggableSheetState createState() => RouteDraggableSheetState();
}

class RouteDraggableSheetState extends State<RouteDraggableSheet> {
  late ScrollController scrollController;
  late RouteDraggableSheetController routeDraggableSheetController;
  final _baseMapController = BaseMapController.instance;
  late final _canvasColor = Theme.of(context).canvasColor;
  String _data = "";

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    widget.controller.updateData = _updateData;
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
        label: 'Rotas',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => _loadRoute(destinationLocation),
      ),
      CustomButton(
        label: 'Alertar',
        onPressed: () => _baseMapController.registerSpotholeModal(context),
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

  void _updateData(String data) {
    setState(() {
      _data = data;
    });
  }

  void closeDraggable() {
    //TODO implementar close Route DraggableSheet
    // _baseMapController.closeRouteDraggableSheet();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      maxChildSize: 0.8,
      minChildSize: 0.15,
      initialChildSize: 0.15,
      snap: true,
      snapSizes: const [0.15, 0.5],
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
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).hintColor,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              SliverAppBar(
                title: const Text('Destino'),
                primary: false,
                pinned: true,
                centerTitle: false,
                backgroundColor: _canvasColor,
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
              SliverToBoxAdapter(
                child: Text(_data),
              ),
            ],
          ),
        );
      },
    );
  }
}

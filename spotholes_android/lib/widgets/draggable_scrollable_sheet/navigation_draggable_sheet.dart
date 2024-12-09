import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/controllers/route_controller.dart';
import 'package:spotholes_android/widgets/bullet_list.dart';

import '../button/custom_button.dart';

class NavigationDraggableSheet extends StatefulWidget {
  const NavigationDraggableSheet({
    super.key,
    required this.routeController,
    required this.destinationLocation,
  });

  final LatLng destinationLocation;
  final RouteController routeController;

  @override
  NavigationDraggableSheetState createState() =>
      NavigationDraggableSheetState();
}

class NavigationDraggableSheetState extends State<NavigationDraggableSheet> {
  late final _routeController = widget.routeController;
  final scrollController = ScrollController();

  final _draggableController = DraggableScrollableController();
  final _draggableExtentNotifier = signal(0.0);
  final _minDraggableChildSize = 0.25;
  final _intermediateDraggableChildSize = 0.4;
  final _maxDraggableChildSize = 1.0;
  // int? _selectedIndex;

  late final _canvasColor = Theme.of(context).canvasColor;

  late final _directionResult = _routeController.directionResult.value;
  late final _route = _directionResult.routes![0];
  late final _leg = _route.legs![0];
  // late final _steps = _leg.steps!;

  // late final _spotholesInRouteListSignal =
  //     _routeController.spotholesInRouteList;

  @override
  void initState() {
    super.initState();
    _draggableController.addListener(_updateExtent);
    if (_haveWarnings()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWarningsDialog();
      });
    }
  }

  bool _haveWarnings() => _route.warnings?.isNotEmpty == true ? true : false;

  void _showWarningsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning),
              SizedBox(
                width: 12,
              ),
              Text(
                'Alertas na Rota',
              ),
            ],
          ),
          content: BulletList(
            items: _route.warnings!,
          ),
          actions: [
            TextButton(
              child: const Text(
                'OK',
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateExtent() {
    _draggableExtentNotifier.value = _draggableController.size;
  }

  void changeSizeDraggableScrollableSheet(double size) =>
      _draggableController.animateTo(
        size,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );

  @override
  void dispose() {
    _draggableController.removeListener(_updateExtent);
    _draggableController.dispose();
    _draggableExtentNotifier.dispose();
    super.dispose();
  }

  List<Widget> _horizontalListButtons(BuildContext context, position) {
    return [
      // CustomButton(
      //   label: 'Alertar Risco',
      //   bgColor: Colors.tealAccent.shade400,
      //   // onPressed: () => ,
      // ),
      CustomButton(
        label: 'Centralizar',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => {
          _routeController.centerViewRoute(),
          changeSizeDraggableScrollableSheet(_minDraggableChildSize),
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Watch(
      (context) => Column(
        children: [
          Expanded(
            child: DraggableScrollableSheet(
              controller: _draggableController,
              maxChildSize: _maxDraggableChildSize,
              minChildSize: _minDraggableChildSize,
              initialChildSize: _minDraggableChildSize,
              snap: true,
              snapSizes: [
                _minDraggableChildSize,
                _intermediateDraggableChildSize,
                _maxDraggableChildSize
              ],
              builder: (context, scrollController) => Container(
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
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            height: 4,
                            width: 40,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      SliverAppBar(
                        title: Text(
                          '${_leg.distance!.text} (${_leg.duration!.text})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        primary: false,
                        pinned: true,
                        centerTitle: true,
                        // toolbarHeight: 80,
                        // leadingWidth: 50,
                        backgroundColor: _canvasColor,
                        leading: Watch.builder(
                          builder: (context) => IconButton(
                            icon: Icon(
                              _draggableExtentNotifier.value <
                                      _maxDraggableChildSize
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                            onPressed: () {
                              if (_draggableExtentNotifier.value <
                                  _maxDraggableChildSize) {
                                changeSizeDraggableScrollableSheet(
                                    _maxDraggableChildSize);
                              } else {
                                changeSizeDraggableScrollableSheet(
                                    _minDraggableChildSize);
                              }
                            },
                          ),
                        ),
                        actions: [
                          if (_haveWarnings())
                            IconButton(
                              icon: const Icon(Icons.warning),
                              onPressed: _showWarningsDialog,
                            ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                        // bottom: PreferredSize(
                        //   preferredSize: const Size.fromHeight(35),
                        //   child: Padding(
                        //     padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        //     child: Text(
                        //       'TESTE TESTE TESTE TESTE',
                        //       style: Theme.of(context).textTheme.bodyLarge,
                        //       maxLines: 2,
                        //       overflow: TextOverflow.ellipsis,
                        //     ),
                        //   ),
                        // ),
                      ),
                      SliverFillRemaining(
                          child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            color: Theme.of(context).focusColor,
                            child: Column(
                              children: [
                                Text(
                                  'Via: ${_route.summary!}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ))
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            child: SizedBox(
              height: 60.0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    _horizontalListButtons(context, widget.destinationLocation),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:spotholes_android/controllers/route_controller.dart';
import 'package:spotholes_android/widgets/bullet_list.dart';

import '../../main.dart';
import '../button/custom_button.dart';

class NavigationDraggableSheet extends StatefulWidget {
  const NavigationDraggableSheet({
    super.key,
    required this.routeController,
  });

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

  late final _canvasColor = Theme.of(context).canvasColor;

  late final _route = _routeController.route;
  late final _leg = _routeController.leg;

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

  bool _haveWarnings() =>
      _route.value.warnings?.isNotEmpty == true ? true : false;

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
            items: _route.value.warnings!,
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

  List<Widget> _horizontalListButtons() {
    return [
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
                          '${_leg.value.distance!.text} (${_leg.value.duration!.text})',
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
                            onPressed: () =>
                                MyApp.navigatorKey.currentState?.pop(true),
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
                                  'Via: ${_route.value.summary!}',
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
                children: _horizontalListButtons(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

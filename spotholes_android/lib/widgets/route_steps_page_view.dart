import 'dart:async';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_html/flutter_html.dart';
import 'package:google_directions_api/google_directions_api.dart';

import '../controllers/route_controller.dart';
import '../utilities/custom_icons.dart';
import '../utilities/maneuver_icons.dart';

class RouteStepsPageView extends StatefulWidget {
  const RouteStepsPageView({
    super.key,
    required this.route,
    required this.pageController,
  });

  final DirectionsRoute route;
  final PageController pageController;

  @override
  RouteStepsStatePageView createState() => RouteStepsStatePageView();
}

class RouteStepsStatePageView extends State<RouteStepsPageView> {
  late final PageController _pageController = widget.pageController;
  int _currentPage = 0;

  final _routeController = RouteController.instance;
  late final _leg = widget.route.legs![0];
  late final _steps = _leg.steps!;

  // Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateOnce();
      // _startRepeatingAnimation(times: 3, interval: 5);
    });
    _pageController.addListener(() {
      int newPage = _pageController.page!.round();
      if (newPage != _currentPage) {
        if (mounted) {
          setState(() {
            _currentPage = newPage;
          });
          if (_currentPage == 0) {
            _routeController.updateCamera(_leg.startLocation!);
          } else if (_currentPage == _steps.length + 1) {
            _routeController.updateCamera(_leg.endLocation!);
          } else {
            final step = _steps[_currentPage - 1];
            final maneuver = step.maneuver ?? 'straight';
            maneuver == 'straight'
                ? _routeController.newCameraLatLngBoundsFromStep(step)
                : _routeController.updateCamera(step.startLocation!);
          }
        }
      }
    });
  }

  void _animateOnce() {
    if (_pageController.hasClients) {
      _pageController.animateTo(
        _pageController.position.pixels +
            MediaQuery.of(context).size.width / 3.5,
        duration: const Duration(milliseconds: 500),
        curve: Curves.linear,
      );
      Future.delayed(
        const Duration(milliseconds: 600),
        () {
          if (_pageController.hasClients) {
            _pageController.animateTo(
              _pageController.position.pixels -
                  MediaQuery.of(context).size.width / 3.5,
              duration: const Duration(milliseconds: 500),
              curve: Curves.linear,
            );
          }
        },
      );
    }
  }

  // void _startRepeatingAnimation({required int times, required int interval}) {
  //   _animateOnce();
  //   times--;
  //   _timer = Timer.periodic(
  //     Duration(seconds: interval),
  //     (timer) {
  //       if (times > 0) {
  //         _animateOnce();
  //         times--;
  //       } else {
  //         _stopAnimation();
  //       }
  //     },
  //   );
  // }

  // void _stopAnimation() {
  //   _timer?.cancel();
  //   _timer = null;
  // }

  // @override
  // void dispose() {
  //   // _stopAnimation();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        // child: GestureDetector(
        // onTapDown: (details) {
        //   _stopAnimation();
        // },
        // onLongPressStart: (details) {
        //   _stopAnimation();
        // },
        // onPanStart: (details) {
        //   _stopAnimation();
        // },
        child: ExpandablePageView.builder(
          controller: _pageController,
          itemCount: _steps.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(
                      'Partida: ${_leg.startAddress!}',
                    ),
                    leading: SizedBox(
                      height: 35,
                      width: 35,
                      child: CustomIcons.sourceIconAsset,
                    ),
                    onTap: () => {
                      _routeController.updateCamera(_leg.startLocation!),
                    },
                  ),
                ),
              );
            } else if (index == _steps.length + 1) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    onTap: () => {
                      _routeController.updateCamera(_leg.endLocation!),
                    },
                    title: Text(
                      'Destino: ${_leg.endAddress!}',
                    ),
                    leading: SizedBox(
                      height: 35,
                      width: 35,
                      child: CustomIcons.destinationIconAsset,
                    ),
                  ),
                ),
              );
            } else {
              final step = _steps[index - 1];
              final maneuver = step.maneuver ?? 'straight';
              final icon = maneuverIcons[maneuver] ?? Icons.directions;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    onTap: () => {
                      maneuver == 'straight'
                          ? _routeController.newCameraLatLngBoundsFromStep(step)
                          : _routeController.updateCamera(step.startLocation!),
                    },
                    leading: Icon(
                      icon,
                      size: 35,
                    ),
                    title: Html(
                      data: step.instructions!,
                      style: {
                        "body": Style(
                          fontStyle:
                              Theme.of(context).textTheme.bodyLarge!.fontStyle,
                          margin: Margins.zero,
                        ),
                      },
                    ),
                    subtitle: Html(
                      data: 'Distância: ${step.distance!.text}',
                      style: {
                        "body": Style(
                          fontStyle:
                              Theme.of(context).textTheme.bodyLarge!.fontStyle,
                          margin: Margins.zero,
                        ),
                      },
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
      // ),
    );
  }
}

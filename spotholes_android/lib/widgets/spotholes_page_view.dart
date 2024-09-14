import 'dart:async';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart' hide Step;

import '../controllers/route_controller.dart';
import '../models/spothole.dart';

class SpotholesPageView extends StatefulWidget {
  const SpotholesPageView({
    super.key,
    required this.pageController,
  });

  final PageController pageController;

  @override
  SpotholesStatePageView createState() => SpotholesStatePageView();
}

class SpotholesStatePageView extends State<SpotholesPageView> {
  late final PageController _pageController = widget.pageController;
  int _currentPage = 0;

  final _routeController = RouteController.instance;

  late final _spotholesInRouteList =
      _routeController.spotholesInRouteList.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animateOnce();
    });
    _pageController.addListener(
      () {
        int newPage = _pageController.page!.round();
        if (newPage != _currentPage) {
          _currentPage = newPage;
          _routeController
              .updateCameraLatLng(_spotholesInRouteList[newPage].position);
        }
      },
    );
  }

  void _initialSpotholeCamera() {
    final initialPage = _pageController.initialPage;
    _routeController
        .updateCameraLatLng(_spotholesInRouteList[initialPage].position);
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

  @override
  void dispose() {
    _initialSpotholeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        child: ExpandablePageView.builder(
          controller: _pageController,
          itemCount: _spotholesInRouteList.length,
          itemBuilder: (context, index) {
            final spothole = _spotholesInRouteList[index];
            final deepHole = spothole.type == Type.deepHole;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    '${spothole.type.text}\n'
                    '${(spothole.distance! / 1000).toStringAsFixed(1)} km de distância\n'
                    '${Spothole.getFormattedTimeFromLastUpdate(spothole.dateOfUpdate)}',
                  ),
                  leading: Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: deepHole ? Colors.red : Colors.yellow,
                          width: 3),
                    ),
                    child: Spothole.getImageRiskByType(spothole.type),
                  ),
                  onTap: () => {
                    _routeController.updateCameraLatLng(spothole.position),
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

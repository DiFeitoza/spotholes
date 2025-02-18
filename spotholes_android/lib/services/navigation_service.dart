import 'package:flutter/material.dart' hide Step;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mtk;
import 'package:signals/signals_flutter.dart';

import '../controllers/route_controller.dart';
import '../utilities/constants.dart';
import '../utilities/point_on_route_haversine.dart';

class NavigationService {
  final RouteController _routeController;
  final PageController _pageController;
  final Signal<bool> _isTrackingLocation;
  final Signal<bool> _isPageViewUpdateCamera;

  NavigationService(
    this._routeController,
    this._pageController,
    this._isTrackingLocation,
    this._isPageViewUpdateCamera,
  );

  late final _routePolylineCoordinatesSignal =
      _routeController.routePolylineCoordinatesSignal;
  late final _auxRoutePolylineCoordinatesSignal =
      _routeController.auxRoutePolylineCoordinatesSignal;

  late final _stepsIndexes = _routeController.stepsIndexes;
  late final _routeStepsLatLng = _routeController.routeStepsLatLng;

  late final _discardedPointsCounter = _routeController.discardedPointsCounter;

  int _countOutOfRoute = 0;
  int _countRecalculatedRoute = 0;
  List<mtk.LatLng> _routePointsMtk = [];

  late final spotholesInRoute = _routeController.spotholesInRouteList;
  late final accumulatedDistancesByRouteSegment =
      _routeController.accumulatedDistancesByRouteSegment;

  late final _currentSpotholeIndex = _routeController.currentSpotholeIndex;
  late final _currentSpotholeDistance =
      _routeController.currentSpotholeDistance;

  void updateCurrentSpothole(double currentOffsetDifference) {
    if (spotholesInRoute.value.isNotEmpty &&
        _currentSpotholeIndex.value < spotholesInRoute.value.length) {
      for (int i = _currentSpotholeIndex.value;
          i < spotholesInRoute.value.length;
          i++) {
        final currentSpotholeAccumulatedDistance =
            spotholesInRoute.value[_currentSpotholeIndex.value].distance!;
        final currentRouteSegmentAccumulatedDistance =
            accumulatedDistancesByRouteSegment
                .value[_discardedPointsCounter.value];
        if (currentSpotholeAccumulatedDistance <
            (currentRouteSegmentAccumulatedDistance +
                currentOffsetDifference)) {
          _currentSpotholeIndex.value++;
        } else {
          return;
        }
      }
    }
  }

  void updateDistanceToSpothole(double currentOffsetDifference) {
    updateCurrentSpothole(currentOffsetDifference);
    if (spotholesInRoute.value.isNotEmpty &&
        _currentSpotholeIndex.value < spotholesInRoute.value.length) {
      final currentSpotholeAccumulatedDistance =
          spotholesInRoute.value[_currentSpotholeIndex.value].distance!;
      final currentRouteSegmentAccumulatedDistance =
          accumulatedDistancesByRouteSegment
              .value[_discardedPointsCounter.value];
      final spotholeDistance = (currentSpotholeAccumulatedDistance -
              currentRouteSegmentAccumulatedDistance) -
          currentOffsetDifference;
      _currentSpotholeDistance.set(spotholeDistance, force: true);
    } else {
      _currentSpotholeDistance.set(double.infinity, force: true);
    }
  }

  void updateCurrentLocationOnRouteProgress(
      LatLng currentLocation, mtk.LatLng currentLocationMkt) {
    // TODO BUG Tratar exceção quando a rota é 1 ponto, sim o usuário pode formar uma rota curta!
    final currentLocationProjectionPoint = projectionPointOnSegment(
      currentLocation,
      _routePolylineCoordinatesSignal.value[0],
      _routePolylineCoordinatesSignal.value[1],
    );

    /// Calculates the current offset difference between the current location projection
    /// and the in-progress current route point using the Haversine formula.
    final currentOffsetDifference = haversine(
      currentLocationProjectionPoint,
      _auxRoutePolylineCoordinatesSignal.value[_discardedPointsCounter.value],
    );

    /// Set the initial position to the current location and update the polyline
    _routePointsMtk[0] = currentLocationMkt;
    _routePolylineCoordinatesSignal.value[0] = currentLocationProjectionPoint;
    _routeController.updateRoutePolyline();

    updateDistanceToSpothole(currentOffsetDifference);
  }

  List<mtk.LatLng> convertGmapsToMtkList(List<LatLng> originalList) {
    return originalList.map((LatLng point) {
      return mtk.LatLng(point.latitude, point.longitude);
    }).toList();
  }

  LatLng locationToLatLng(location) =>
      LatLng(location.latitude!, location.longitude!);

  mtk.LatLng locationToMtkLatLng(location) =>
      mtk.LatLng(location.latitude!, location.longitude!);

  int locationIndexOnPath(
      mtk.LatLng currentPosition, List<mtk.LatLng> routePoints) {
    return mtk.PolygonUtil.locationIndexOnPath(
      currentPosition,
      routePoints,
      true,
      tolerance: routeDeviationTolerance,
    );
  }

  int verifyStep() {
    for (int i = 0; i < _stepsIndexes.length; i++) {
      if (_discardedPointsCounter.value <= _stepsIndexes[i]) {
        return i;
      }
    }
    return -1;
  }

  void updateRouteStatus(LatLng currentLocation) async {
    // TODO Check if there are other end-of-route situations
    /// Checks if the route is empty, for example: route completed.
    if (_routeStepsLatLng.value.isEmpty) {
      return;
    }
    _routePointsMtk =
        convertGmapsToMtkList(_routePolylineCoordinatesSignal.value);
    mtk.LatLng currentLocationMtk = locationToMtkLatLng(currentLocation);
    int index = locationIndexOnPath(currentLocationMtk, _routePointsMtk);

    /// If the current location advences on the polyline, then the points are discarded
    if (index > 0) {
      _countOutOfRoute = 0;

      /// Remove the initial points up to the current position
      _routePointsMtk.removeRange(0, index);
      _routePolylineCoordinatesSignal.value.removeRange(0, index);

      updateCurrentLocationOnRouteProgress(currentLocation, currentLocationMtk);

      /// Update the discarded points counter
      _discardedPointsCounter.value += index;

      /// Check the current step on the route
      int currentStepIndex = verifyStep();

      /// If the step has advanced, the pageview is updated
      if (currentStepIndex > 0 && _pageController.hasClients) {
        /// Update the polyline that represents the maneuver arrow on the map. Needs to be done before removing the steps
        if (_isTrackingLocation.value || _pageController.page == 1) {
          _routeController.plotManeuverPolyline(
            currentStepIndex,
            updateCamera: false,
          );
        }

        /// Remove the steps that have passed
        _stepsIndexes.removeRange(0, currentStepIndex);
        _routeStepsLatLng.value.removeRange(0, currentStepIndex);

        final stepsLength = _routeStepsLatLng.value.length;
        final totalRemovedSteps = currentStepIndex;
        final page = _pageController.page!.toInt();

        /// Check if the pageView return movement ends at most on page 01 (step 0)
        /// if the current page is between page 01 and the penultimate page (within the steps list)
        if (totalRemovedSteps < page && page > 1 && page < stepsLength + 2) {
          _isPageViewUpdateCamera.value = false;
          _pageController.jumpToPage(page - totalRemovedSteps);
        } else {
          /// It is necessary to update to force the widget to render, however, this avoids duplication of the update because the jumpToPage invokes a method that updates the list
          _routeStepsLatLng.value = [..._routeStepsLatLng.value];
        }
      }

      /// If it is between position 0 and 1 of the polyline (index == 0), then the polyline is updated
    } else if (index == 0) {
      _countOutOfRoute = 0;
      updateCurrentLocationOnRouteProgress(currentLocation, currentLocationMtk);

      /// If it is the last step and has less than 3 points, then discard the last step, points and complete the route
    } else if (_routeStepsLatLng.value.length == 1 &&
        _routePolylineCoordinatesSignal.value.length < 3) {
      _countOutOfRoute = 0;
      _routeController.finishNavigationRoute();
    } else {
      _countOutOfRoute += 1;

      /// Recalculate the route after 5 consecutive movements off the route (considering the tolerance margin in meters)
      /// Only recalculate the route 3 times automatically, avoiding failures that generate many recalculations
      // TODO Create Snackbar to warn that the limit of 3 times has been exceeded, asking if you want to recalculate manually, if yes, 3 more automatic recalculations
      if (_countOutOfRoute > 5 && _countRecalculatedRoute <= 3) {
        _countOutOfRoute = 0;
        _discardedPointsCounter.value = 0;
        _currentSpotholeIndex.value = 0;
        _currentSpotholeDistance.value = double.infinity;
        _routeController.recalculateRoute(currentLocation);
        _countRecalculatedRoute += 1;
      }
    }
  }
}

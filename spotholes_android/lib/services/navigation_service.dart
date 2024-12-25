import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mtk;
import 'package:signals/signals_flutter.dart';

import '../controllers/route_controller.dart';
import '../utilities/constants.dart';

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

  late final Signal<List<LatLng>> _routePolylineCoordinatesSignal =
      _routeController.routePolylineCoordinatesSignal;
  late final List<int> _stepsIndexes = _routeController.stepsIndexes;

  int _discardedPointsCounter = 0;
  int _countOutOfRoute = 0;
  int _countRecalculatedRoute = 0;
  List<mtk.LatLng> routePointsMtk = [];

  Timer? _exitRouteTimer;

  void startNavigation() {
    routePointsMtk =
        convertGmapsToMtkList(_routePolylineCoordinatesSignal.value);
  }

  void stopNavigation() {
    _discardedPointsCounter = 0;
    if (_exitRouteTimer != null) {
      _exitRouteTimer!.cancel();
    }
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
      if (_discardedPointsCounter <= _stepsIndexes[i]) {
        return i;
      }
    }
    return -1;
  }

  void updateRouteStatus(LatLng currentLocation) async {
    // TODO Verificar se há outras situações de fim da rota
    // Verifica se a rota está vazia, por exemplo: trajeto concluído.
    if (_routeController.routeStepsLatLng.value.isEmpty) {
      return;
    }
    routePointsMtk =
        convertGmapsToMtkList(_routePolylineCoordinatesSignal.value);
    mtk.LatLng currentLocationMtk = locationToMtkLatLng(currentLocation);
    int index = locationIndexOnPath(currentLocationMtk, routePointsMtk);
    debugPrint('----index on polyline: $index');
    // Se a localização atual está na rota
    if (index > 0) {
      _countOutOfRoute = 0;
      // Define a posição inicial para a localização atual
      routePointsMtk[index] = currentLocationMtk;
      // Remove os pontos iniciais até a posição atual
      routePointsMtk.removeRange(0, index + 1);
      _routePolylineCoordinatesSignal.value.removeRange(0, index + 1);
      _routePolylineCoordinatesSignal.value[0] = currentLocation;
      _routeController.updateRoutePolyline();
      // Atualiza o contador de pontos descartados
      _discardedPointsCounter += index + 1;
      debugPrint('Pontos a descartar $_discardedPointsCounter');
      // Verifica o step atual na rota
      int currentStepIndex = verifyStep();
      // Se o step avançou, o pageview é atualizado
      if (currentStepIndex > 0 && _pageController.hasClients) {
        // Atualiza a polyline que representa a seta de manobra no mapa. Precisa ser feito antes de remover os steps
        if (_isTrackingLocation.value || _pageController.page == 1) {
          _routeController.plotManeuverPolyline(currentStepIndex,
              updateCamera: false);
        }
        // Remove os steps que já passaram
        _stepsIndexes.removeRange(0, currentStepIndex);
        _routeController.routeStepsLatLng.value
            .removeRange(0, currentStepIndex);

        final stepsLength = _routeController.routeStepsLatLng.value.length;
        final totalRemovedSteps = currentStepIndex;
        final page = _pageController.page!.toInt();
        // Verifica se o movimento de retorno do pageView termina no máximo na página 01 (step 0), se a página atual está entre a página 01 e a penúltima página (dentro da lista de steps)
        if (totalRemovedSteps < page && page > 1 && page < stepsLength + 2) {
          _isPageViewUpdateCamera.value = false;
          _pageController.jumpToPage(page - totalRemovedSteps);
        } else {
          // É necessário atualizar para forçar a renderização do widget, porém assim evita duplicação do update porque o jumpToPage invoca um método que faz update da lista
          _routeController.routeStepsLatLng.value = [
            ..._routeController.routeStepsLatLng.value
          ];
        }
        debugPrint('---pages: ${_pageController.page} $currentStepIndex');
      }
      // Caso esteja entre a posição 0 e 1 da polyline (index == 0), então a polyline é atualizada
    } else if (index == 0) {
      _countOutOfRoute = 0;
      _routePolylineCoordinatesSignal.value[0] = currentLocation;
      _routeController.updateRoutePolyline();
      // Caso seja o último step e tenha menos que 3 pontos, então descarta o último step, pontos e conclui a rota
    } else if (_routeController.routeStepsLatLng.value.length == 1 &&
        _routePolylineCoordinatesSignal.value.length < 3) {
      _countOutOfRoute = 0;
      debugPrint('---Cheguei no final');
      _stepsIndexes.clear();
      _routeController.routeStepsLatLng.value.clear();
      _routePolylineCoordinatesSignal.value.clear();
      _routeController.clearManeuverPolyline();
      // Força update dos steps
      _routeController.routeStepsLatLng.value = [
        ..._routeController.routeStepsLatLng.value
      ];
    } else {
      _countOutOfRoute += 1;
      // Recalcula a rota após 5 movimentos consecutivos fora da rota (considerando a margem de tolerâcia em metros)
      // Apenas recalcula a rota 3 vezes de forma automática, evitando falhas que gerem muitos recálculos
      // TODO Criar Snackbar para avisar que ultrapassou o limite de 3 vezes, perguntando se quer recalcular de forma manual, caso sim, mais 3 automáticos
      if (_countOutOfRoute > 5 && _countRecalculatedRoute <= 3) {
        _countOutOfRoute = 0;
        _routeController.recalculateRoute(currentLocation);
        _countRecalculatedRoute += 1;
      }
    }
    debugPrint(
        '----[Após descarte] points ${_routePolylineCoordinatesSignal.value.length} steps:${_routeController.routeStepsLatLng.value.length}');
  }
}

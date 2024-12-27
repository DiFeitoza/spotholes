import 'package:flutter/material.dart';

import '../config/environment_config.dart';
import '../controllers/base_map_controller.dart';
import '../package/google_places_flutter/google_places_flutter.dart';
import '../package/google_places_flutter/model/place_details.dart';
import '../package/google_places_flutter/model/prediction.dart';
import '../services/location_service.dart';

class CustomHeader extends StatelessWidget {
  final BaseMapController baseMapController;
  const CustomHeader({super.key, required this.baseMapController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CustomSearchContainer(
          baseMapController: baseMapController,
        ),
        // CustomSearchCategories(),
      ],
    );
  }
}

class CustomSearchContainer extends StatelessWidget {
  final BaseMapController baseMapController;
  const CustomSearchContainer({super.key, required this.baseMapController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(width: 0.5),
        ),
        child: Row(
          children: <Widget>[
            CustomTextField(
              baseMapController: baseMapController,
            ),
            // const Icon(Icons.mic),
            // const SizedBox(width: 16),
            // const CustomUserAvatar(),
            // const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final BaseMapController baseMapController;
  final _locationService = LocationService.instance;
  late final _textEditingController = baseMapController.textEditingController;
  late final _searchBarfocusNode = baseMapController.searchBarFocusNode;

  CustomTextField({super.key, required this.baseMapController});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: _textEditingController,
        googleAPIKey: EnvironmentConfig.googleApiKey!,
        currentLocationLatLngURLPattern:
            _locationService.currentLocationLatLngURLPattern,
        boxDecoration: const BoxDecoration(),
        inputDecoration: const InputDecoration(
          prefixIcon: Padding(
            padding: EdgeInsets.all(0.0),
            child: Icon(Icons.search),
          ),
          hintText: "Pesquise aqui",
          border: InputBorder.none,
          focusColor: Colors.blue,
        ),
        // debounceTime: 800, // default 600 ms,
        countries: const ["br"],
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (PlaceDetails placeDetails) {
          baseMapController.loadPlaceLocation(context, placeDetails);
        }, // this callback is called when isLatLngRequired is true
        itemClick: (Prediction prediction) {
          _textEditingController.text = prediction.description!;
          _textEditingController.selection = TextSelection.fromPosition(
            TextPosition(offset: prediction.description!.length),
          );
        },
        // if we want to make custom list item builder
        itemBuilder: (context, index, Prediction prediction) {
          return Container(
            padding: const EdgeInsets.all(10),
            // decoration: BoxDecoration(
            //   borderRadius: BorderRadius.circular(10),
            //   color: Colors.grey[200],
            // ),
            child: Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(
                  width: 7,
                ),
                Expanded(
                  child: Text("${prediction.description}"),
                )
              ],
            ),
          );
        },
        textInputAction: TextInputAction.search,
        focusNode: _searchBarfocusNode,
        // if you want to add seperator between list items
        seperatedBuilder: const Divider(),
        // want to show close icon
        isCrossBtnShown: true,
        // place type
        // placeType: PlaceType.geocode,
        language: "pt-BR",
      ),
    );
  }
}

class CustomUserAvatar extends StatelessWidget {
  const CustomUserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 32,
      decoration: BoxDecoration(
        color: Colors.grey[500],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class CustomSearchCategories extends StatelessWidget {
  const CustomSearchCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 12),
          CustomCategoryChip(Icons.history, "Recentes"),
          SizedBox(width: 12),
          CustomCategoryChip(Icons.bookmark, "Salvos"),
          SizedBox(width: 12),
        ],
      ),
    );
  }
}

class CustomCategoryChip extends StatelessWidget {
  final IconData iconData;
  final String title;

  const CustomCategoryChip(this.iconData, this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Row(
        children: <Widget>[
          Icon(iconData, size: 16),
          const SizedBox(width: 8),
          Text(title)
        ],
      ),
      backgroundColor: Colors.grey[50],
      side: const BorderSide(width: 0.5),
    );
  }
}

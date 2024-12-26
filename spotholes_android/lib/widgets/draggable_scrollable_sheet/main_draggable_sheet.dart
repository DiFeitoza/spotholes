import 'package:flutter/material.dart';

import '../../controllers/base_map_controller.dart';
import '../button/custom_button.dart';

class MainDraggableSheetController {
  Function(String)? updateData;

  void dispose() {
    updateData = null;
  }
}

class MainDraggableSheet extends StatefulWidget {
  const MainDraggableSheet({super.key, required this.controller});

  final MainDraggableSheetController controller;

  @override
  MainDraggableSheetState createState() => MainDraggableSheetState();
}

class MainDraggableSheetState extends State<MainDraggableSheet> {
  late ScrollController scrollController;
  late MainDraggableSheetController mainDraggableSheetController;
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

  List<Widget> _horizontalListButtons() {
    return [
      CustomButton(
        label: 'Buscar',
        bgColor: Colors.tealAccent.shade400,
        onPressed: () => FocusScope.of(context)
            .requestFocus(_baseMapController.searchBarFocusNode),
      ),
      CustomButton(
        label: 'Alertar',
        onPressed: () => _baseMapController.registerSpotholeModal(),
      ),
    ];
  }

  void _updateData(String data) {
    setState(() {
      _data = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      maxChildSize: 0.5,
      minChildSize: 0.18,
      initialChildSize: 0.18,
      snap: true,
      snapSizes: const [0.18, 0.5],
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
                title: const Text('Para onde vamos?'),
                primary: false,
                pinned: true,
                centerTitle: false,
                backgroundColor: _canvasColor,
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
                            children: _horizontalListButtons(),
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

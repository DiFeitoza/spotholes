import 'package:flutter/material.dart';

import '../../controllers/base_map_controller.dart';
import '../custom_button.dart';

class MainDraggableSheetController {
  // Function(Widget)? updateHorizontalListButtons;
  // Function(Widget)? updateSliverListContent;
  Function(String)? updateData;

  void dispose() {
    // updateSliverListContent = null;
    // updateHorizontalListButtons = null;
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
  String _data = "";

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    // widget.controller.updateSliverListContent = _updateSliverListContent;
    // widget.controller.updateHorizontalListButtons =
    // _updateHorizontalListButtons;
    widget.controller.updateData = _updateData;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  List<Widget> _horizontalListButtons(BuildContext context) {
    return [
      CustomButton(
        label: 'Buscar',
        color: Colors.green,
        onPressed: () => FocusScope.of(context)
            .requestFocus(_baseMapController.searchBarFocusNode),
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

//   void _updateHorizontalListButtons(Widget dynamicContent) {
//     setState(() {
//       // Atualize o conteúdo conforme necessário
//       _horizontalListButtons = [dynamicContent];
//     });
//   }

// // Método para atualizar o conteúdo do SliverList
//   void _updateSliverListContent(Widget dynamicContent) {
//     setState(() {
//       // Atualize o conteúdo conforme necessário
//       _horizontalListButtons = [dynamicContent];
//     });
//   }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      maxChildSize: 0.8,
      minChildSize: 0.18,
      initialChildSize: 0.18,
      snap: true,
      snapSizes: const [0.18, 0.5],
      builder: (BuildContext context, scrollController) {
        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Theme.of(context).canvasColor,
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
              const SliverAppBar(
                title: Text('Para onde vamos?'),
                primary: false,
                pinned: true,
                centerTitle: false,
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
                            children: _horizontalListButtons(context),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Text(_data), // Substitua pelo seu conteúdo de texto
              ),
            ],
          ),
        );
      },
    );
  }
}

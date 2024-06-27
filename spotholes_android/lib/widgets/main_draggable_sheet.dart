import 'package:flutter/material.dart';
import 'package:spotholes_android/widgets/custom_button.dart';

class MainDraggableSheet extends StatefulWidget {
  const MainDraggableSheet({super.key});

  @override
  MainDraggableSheetState createState() => MainDraggableSheetState();
}

class MainDraggableSheetState extends State<MainDraggableSheet> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      minChildSize: 0.15,
      initialChildSize: 0.15,
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
              // const SliverAppBar(
              //   title: Text('Opções'),
              //   primary: false,
              //   pinned: true,
              //   centerTitle: false,
              // ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      SizedBox(
                        height: 60.0,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: <Widget>[
                            // Adicione seus botões aqui
                            CustomButton(
                                label: 'Rotas',
                                color: Colors.green,
                                onPressed: () {}),
                            CustomButton(label: 'Salvar', onPressed: () {}),
                            CustomButton(label: 'Cancelar', onPressed: () {}),
                            CustomButton(label: 'Excluir', onPressed: () {}),
                          ],
                        ),
                      )
                    ]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

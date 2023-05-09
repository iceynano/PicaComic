import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/eh_network/get_gallery_id.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/network/new_download_model.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/tools/ui_mode.dart';
import 'package:pica_comic/views/downloading_page.dart';
import 'package:pica_comic/views/eh_views/eh_gallery_page.dart';
import 'package:pica_comic/views/jm_views/jm_comic_page.dart';
import 'package:pica_comic/views/pic_views/comic_page.dart';
import 'package:pica_comic/views/reader/comic_reading_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import 'package:pica_comic/views/widgets/widgets.dart';

class DownloadPageLogic extends GetxController {
  ///是否正在加载
  bool loading = true;

  ///是否处于选择状态
  bool selecting = false;

  ///已选择的数量
  int selectedNum = 0;

  ///已选择的漫画
  var selected = <List<bool>>[[], [], []];

  ///已下载的漫画
  var comics = <DownloadedComic>[];

  ///已下载的禁漫漫画
  var jmComics = <DownloadedJmComic>[];

  ///已下载的画廊
  var galleries = <DownloadedGallery>[];

  void change() {
    loading = !loading;
    update();
  }

  void fresh() {
    selecting = false;
    selectedNum = 0;
    selected[0].clear();
    selected[1].clear();
    selected[2].clear();
    comics.clear();
    jmComics.clear();
    galleries.clear();
    change();
  }
}

class DownloadPage extends StatelessWidget {
  const DownloadPage({this.noNetwork = false, Key? key}) : super(key: key);

  ///无网络时直接跳过漫画详情页的加载
  final bool noNetwork;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DownloadPageLogic>(
        init: DownloadPageLogic(),
        builder: (logic) {
          if (logic.loading) {
            getComics(logic).then((v) {
              for (var i = 0; i < logic.comics.length; i++) {
                logic.selected[0].add(false);
              }
              for (var i = 0; i < logic.galleries.length; i++) {
                logic.selected[1].add(false);
              }
              for (var i = 0; i < logic.jmComics.length; i++) {
                logic.selected[2].add(false);
              }
              logic.change();
            });
            return showLoading(context, withScaffold: true);
          } else {
            return Scaffold(
              appBar: AppBar(
                leading: logic.selecting
                    ? IconButton(
                        onPressed: () {
                          logic.selecting = false;
                          logic.selectedNum = 0;
                          for (int i = 0; i < logic.selected[0].length; i++) {
                            logic.selected[0][i] = false;
                          }
                          for (int i = 0; i < logic.selected[1].length; i++) {
                            logic.selected[1][i] = false;
                          }
                          logic.update();
                        },
                        icon: const Icon(Icons.close))
                    : IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back)),
                backgroundColor:
                    logic.selecting ? Theme.of(context).colorScheme.secondaryContainer : null,
                title: logic.selecting ? Text("已选择${logic.selectedNum}个项目") : const Text("已下载"),
                actions: [
                  if (!logic.selecting)
                    Tooltip(
                      message: "下载管理器",
                      child: IconButton(
                        icon: const Icon(Icons.download_for_offline),
                        onPressed: () {
                          Get.to(() => const DownloadingPage());
                        },
                      ),
                    )
                  else
                    Tooltip(
                      message: "更多",
                      child: IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () {
                          showMenu(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                  MediaQuery.of(context).size.width - 60,
                                  50,
                                  MediaQuery.of(context).size.width - 60,
                                  50),
                              items: [
                                PopupMenuItem(
                                  child: const Text("全选"),
                                  onTap: () {
                                    for (int i = 0; i < logic.selected[0].length; i++) {
                                      logic.selected[0][i] = true;
                                      logic.selectedNum++;
                                    }
                                    for (int i = 0; i < logic.selected[1].length; i++) {
                                      logic.selected[1][i] = true;
                                      logic.selectedNum++;
                                    }
                                    for (int i = 0; i < logic.selected[2].length; i++) {
                                      logic.selected[2][i] = true;
                                      logic.selectedNum++;
                                    }
                                    logic.update();
                                  },
                                ),
                                PopupMenuItem(
                                  child: const Text("导出"),
                                  onTap: () {
                                    if (logic.selectedNum == 0) {
                                      showMessage(context, "请选择漫画");
                                    } else if (logic.selectedNum > 1) {
                                      showMessage(context, "一次只能导出一部漫画");
                                    } else {
                                      Future<void>.delayed(
                                        const Duration(milliseconds: 200),
                                        () => showDialog(
                                          context: context,
                                          barrierColor: Colors.black26,
                                          barrierDismissible: false,
                                          builder: (context) => SimpleDialog(
                                            children: [
                                              SizedBox(
                                                width: 200,
                                                height: 200,
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 50,
                                                    height: 75,
                                                    child: Column(
                                                      children: const [
                                                        SizedBox(height: 10,),
                                                        CircularProgressIndicator(),
                                                        SizedBox(height: 9,),
                                                        Text("打包中")
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                      Future<void>.delayed(
                                          const Duration(milliseconds: 500), () => export(logic));
                                    }
                                  },
                                ),
                                PopupMenuItem(
                                  child: const Text("查看漫画详情"),
                                  onTap: () => toComicInfoPage(logic),
                                ),
                              ]);
                        },
                      ),
                    ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                heroTag: UniqueKey(),
                onPressed: () {
                  if (!logic.selecting) {
                    logic.selecting = true;
                    logic.update();
                  } else {
                    if (logic.selectedNum == 0) return;
                    showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text("删除"),
                            content: Text("要删除已选择的${logic.selectedNum}项吗? 此操作无法撤销"),
                            actions: [
                              TextButton(onPressed: () => Get.back(), child: const Text("取消")),
                              TextButton(
                                  onPressed: () async {
                                    Get.back();
                                    var comics = <String>[];
                                    for (int i = 0; i < logic.selected[0].length; i++) {
                                      if (logic.selected[0][i]) {
                                        comics.add(logic.comics[i].comicItem.id);
                                      }
                                    }
                                    for (int i = 0; i < logic.selected[1].length; i++) {
                                      if (logic.selected[1][i]) {
                                        comics.add(getGalleryId(logic.galleries[i].gallery.link));
                                      }
                                    }
                                    for (int i = 0; i < logic.selected[2].length; i++) {
                                      if (logic.selected[2][i]) {
                                        comics.add("jm${logic.jmComics[i].comic.id}");
                                      }
                                    }
                                    await downloadManager.delete(comics);
                                    logic.fresh();
                                  },
                                  child: const Text("确认")),
                            ],
                          );
                        });
                  }
                },
                child: logic.selecting
                    ? const Icon(Icons.delete_forever_outlined)
                    : const Icon(Icons.checklist_outlined),
              ),
              body: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(splashBorderRadius: BorderRadius.all(Radius.circular(10)), tabs: [
                      Tab(
                        text: "Picacg",
                      ),
                      Tab(
                        text: "E-Hentai",
                      ),
                      Tab(
                        text: "JmComic",
                      )
                    ]),
                    Expanded(
                      child: TabBarView(
                        children: [
                          CustomScrollView(
                            slivers: [
                              SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                    childCount: logic.comics.length, (context, index) {
                                  var size = logic.comics[index].size;
                                  String? s;
                                  if (size != null) {
                                    s = size.toStringAsFixed(2);
                                  }
                                  return buildItem(
                                      context,
                                      logic.comics[index].comicItem.id,
                                      0,
                                      index,
                                      logic,
                                      logic.comics[index].comicItem.title,
                                      logic.comics[index].comicItem.author,
                                      s ?? "未知");
                                }),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: comicTileMaxWidth,
                                  childAspectRatio: comicTileAspectRatio,
                                ),
                              )
                            ],
                          ),
                          CustomScrollView(
                            slivers: [
                              SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                    childCount: logic.galleries.length, (context, index) {
                                  var size = logic.galleries[index].size;
                                  String? s;
                                  if (size != null) {
                                    s = size.toStringAsFixed(2);
                                  }
                                  return buildItem(
                                      context,
                                      getGalleryId(logic.galleries[index].gallery.link),
                                      1,
                                      index,
                                      logic,
                                      logic.galleries[index].gallery.title,
                                      logic.galleries[index].gallery.uploader,
                                      s ?? "未知");
                                }),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: comicTileMaxWidth,
                                  childAspectRatio: comicTileAspectRatio,
                                ),
                              )
                            ],
                          ),
                          CustomScrollView(
                            slivers: [
                              SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                    childCount: logic.jmComics.length, (context, index) {
                                  var size = logic.jmComics[index].size;
                                  String? s;
                                  if (size != null) {
                                    s = size.toStringAsFixed(2);
                                  }
                                  return buildItem(
                                      context,
                                      "jm${logic.jmComics[index].comic.id}",
                                      2,
                                      index,
                                      logic,
                                      logic.jmComics[index].comic.name,
                                      logic.jmComics[index].comic.author[0],
                                      s ?? "未知");
                                }),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: comicTileMaxWidth,
                                  childAspectRatio: comicTileAspectRatio,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        });
  }

  Future<void> getComics(DownloadPageLogic logic) async {
    try{
      for (var comic in (downloadManager.downloaded)) {
        logic.comics.add(await downloadManager.getComicFromId(comic));
      }

      for (var gallery in (downloadManager.downloadedGalleries)) {
        logic.galleries.add(await downloadManager.getGalleryFormId(gallery));
      }

      for (var comic in (downloadManager.downloadedJmComics)) {
        logic.jmComics.add(await downloadManager.getJmComicFormId(comic));
      }
    }
    catch(e){
      logic.jmComics.clear();
      logic.galleries.clear();
      logic.comics.clear();
      await getComics(logic);
    }
  }

  Future<void> export(DownloadPageLogic logic) async {
    for (int i0 = 0; i0 < logic.selected.length; i0++) {
      for (int i1 = 0; i1 < logic.selected[i0].length; i1++) {
        if (logic.selected[i0][i1]) {
          if (i0 == 0 || i0 == 1) {
            exportComic(logic.comics[i1].comicItem.id);
            return;
          } else if (i0 == 1) {
            exportComic(getGalleryId(logic.galleries[i1].gallery.link));
            return;
          } else if(i0 == 2){
            exportComic("jm${logic.jmComics[i1].comic.id}");
          }
        }
      }
    }
  }

  Widget buildItem(BuildContext context, String id, int index0, int index1, DownloadPageLogic logic,
      String title, String subTitle, String size) {
    bool selected = logic.selected[index0][index1];
    return GestureDetector(
        onSecondaryTapUp: (details) {
          showMenu(
              context: context,
              position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy,
                  details.globalPosition.dx, details.globalPosition.dy),
              items: [
                PopupMenuItem(
                  onTap: () {
                    downloadManager.delete([id]);
                    if (index0 == 0) {
                      logic.comics.removeAt(index1);
                    } else if (index0 == 1) {
                      logic.galleries.removeAt(index1);
                    } else if (index0 == 2) {
                      logic.jmComics.removeAt(index1);
                    }
                    logic.selected[index0].removeAt(index1);
                    logic.update();
                  },
                  child: const Text("删除"),
                ),
                PopupMenuItem(
                  child: const Text("导出"),
                  onTap: () {
                    Future<void>.delayed(
                      const Duration(milliseconds: 200),
                      () => showDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.black26,
                        builder: (context) => SimpleDialog(
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: Center(
                                child: SizedBox(
                                  width: 50,
                                  height: 80,
                                  child: Column(
                                    children: const [
                                      SizedBox(height: 10,),
                                      CircularProgressIndicator(),
                                      SizedBox(height: 9,),
                                      Text("打包中")
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                    Future<void>.delayed(const Duration(milliseconds: 500), () {
                      exportComic(id);
                    });
                  },
                ),
                PopupMenuItem(
                  child: const Text("查看漫画详情"),
                  onTap: () {
                    var i = index0;
                    var j = index1;
                    Future.delayed(const Duration(milliseconds: 300), (){
                      switch(i){
                        case 0: Get.to(()=>ComicPage(logic.comics[j].comicItem.toBrief()));break;
                        case 1: Get.to(()=>EhGalleryPage(logic.galleries[j].gallery.toBrief()));break;
                        case 2: Get.to(()=>JmComicPage(logic.jmComics[j].comic.id));break;
                      }
                    });
                  },
                ),
              ]);
        },
        child: Container(
          decoration: BoxDecoration(
              color: selected ? const Color.fromARGB(100, 121, 125, 127) : Colors.transparent),
          child: ComicTile(
            ComicItemBrief(title, subTitle, 0, "", id),
            downloaded: true,
            onTap: () async {
              if (logic.selecting) {
                logic.selected[index0][index1] = !logic.selected[index0][index1];
                logic.selected[index0][index1] ? logic.selectedNum++ : logic.selectedNum--;
                if (logic.selectedNum == 0) {
                  logic.selecting = false;
                }
                logic.update();
              } else {
                //TODO
                if (index0 == 0) {
                  showInfo(index0, index1, logic, context);
                } else if (index0 == 1) {
                  readEhGallery(
                      logic.galleries[index1].gallery.link, logic.galleries[index1].gallery);
                } else if (index0 == 2) {
                  readJmComic(logic.jmComics[index1].comic.id, logic.jmComics[index1].comic.name,
                      logic.jmComics[index1].comic.series.values.toList());
                }
              }
            },
            size: size,
            onLongTap: () {
              if (logic.selecting) return;
              logic.selected[index0][index1] = true;
              logic.selectedNum++;
              logic.selecting = true;
              logic.update();
            },
          ),
        ));
  }

  void toComicInfoPage(DownloadPageLogic logic){
    if(logic.selectedNum != 1){
      showMessage(Get.context, "请选择一个漫画");
    }else{
      for(int i = 0;i<logic.selected.length;i++){
        for(int j = 0;j<logic.selected[i].length;j++){
          if(logic.selected[i][j]){
            Future.delayed(const Duration(milliseconds: 300), (){
              switch(i){
                case 0: Get.to(()=>ComicPage(logic.comics[j].comicItem.toBrief()));break;
                case 1: Get.to(()=>EhGalleryPage(logic.galleries[j].gallery.toBrief()));break;
                case 2: Get.to(()=>JmComicPage(logic.jmComics[j].comic.id));break;
              }
            });
          }
        }
      }
    }
  }

  void showInfo(int index0, int index1, DownloadPageLogic logic, BuildContext context){
    if(UiMode.m1(context)){
      showModalBottomSheet(context: context, builder: (context){
        return DownloadedComicInfoView(index0, index1, logic);
      });
    }else{
      showSideBar(context, DownloadedComicInfoView(index0, index1, logic),useSurfaceTintColor: true);
    }
  }
}

class DownloadedComicInfoView extends StatefulWidget {
  const DownloadedComicInfoView(this.index0, this.index1, this.logic, {Key? key}) : super(key: key);
  final int index0;
  final int index1;
  final DownloadPageLogic logic;

  @override
  State<DownloadedComicInfoView> createState() => _DownloadedComicInfoViewState();
}

class _DownloadedComicInfoViewState extends State<DownloadedComicInfoView> {
  String name = "";
  List<String> eps = [];
  List<int> downloadedEps = [];

  @override
  Widget build(BuildContext context) {
    getInfo();
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            child: Text(name, style: const TextStyle(fontSize: 22),),
          ),
          Expanded(child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              childAspectRatio: 4,
            ),
            itemBuilder: (BuildContext context, int i) {
              return Padding(padding: const EdgeInsets.all(4),child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: AnimatedContainer(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    color: downloadedEps.contains(i)?Theme.of(context).colorScheme.primaryContainer:Theme.of(context).colorScheme.surfaceVariant,
                  ),
                  duration: const Duration(milliseconds: 200),

                  child: Row(
                    children: [
                      const SizedBox(width: 16,),
                      Expanded(child: Text(eps[i],),),
                      const SizedBox(width: 4,),
                      if(downloadedEps.contains(i))
                        const Icon(Icons.download_done),
                      const SizedBox(width: 16,),
                    ],
                  ),
                ),
                onTap: () => readSpecifiedEps(i),
              ),);
            },
            itemCount: eps.length,
          ),),
          SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(child: FilledButton(onPressed: (){}, child: const Text("删除")),),
                  const SizedBox(width: 16,),
                  Expanded(child: FilledButton(onPressed: () => read(), child: const Text("阅读")),),
                ],
              )
          )
        ],
      ),
    );
  }

  void getInfo(){
    switch(widget.index0){
      case 0:
        name = widget.logic.comics[widget.index1].comicItem.title;
        eps = widget.logic.comics[widget.index1].chapters.sublist(1);
        downloadedEps = widget.logic.comics[widget.index1].downloadedChapters;
        break;
    }
  }

  void read(){
    var index0 = widget.index0;
    var index1 = widget.index1;
    if (index0 == 0) {
      readPicacgComic(widget.logic.comics[index1].comicItem.id, name, widget.logic.comics[index1].chapters);
    } else if (index0 == 1) {
      readEhGallery(
          widget.logic.galleries[index1].gallery.link, widget.logic.galleries[index1].gallery);
    } else if (index0 == 2) {
      readJmComic(widget.logic.jmComics[index1].comic.id, widget.logic.jmComics[index1].comic.name,
          widget.logic.jmComics[index1].comic.series.values.toList());
    }
  }

  void readSpecifiedEps(int i){
    var index0 = widget.index0;
    var index1 = widget.index1;
    if(index0 == 0){
      Get.to(() =>
          ComicReadingPage.picacg(widget.logic.comics[index1].comicItem.id, i+1, widget.logic.comics[index1].chapters, widget.logic.comics[index1].comicItem.title));
    }
  }
}


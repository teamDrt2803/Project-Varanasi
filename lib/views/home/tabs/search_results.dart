import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:varanasi/controllers/song_controller.dart';
import 'package:varanasi/widgets/cust_appbar.dart';
import 'package:varanasi/widgets/instrument_display_widget.dart';
import 'package:varanasi/widgets/item_list.dart';
import 'package:varanasi/widgets/loader.dart';
import 'package:varanasi/widgets/nav_bar.dart';

class SearchResultPage extends GetView<SongController> {
  const SearchResultPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustAppBar(
        title:
            '${controller.searchQuery} -(${describeEnum(Get.arguments).capitalize!}s)',
        onBackPressed: controller.clear,
      ),
      body: Obx(
        () {
          var list = controller.getsearchResultsValue(Get.arguments);
          return list.isEmpty && controller.isFetchingSearchResult
              ? const Loader()
              : buildVerticalItemsList(
                  context,
                  list,
                  null,
                  (d) =>
                      CommonListingWidget(d, scrollDirection: Axis.horizontal),
                  isPaginated: controller.hasMorePaginationData,
                  onLoadMorePressed: () => controller.nextPage(Get.arguments),
                  showPaginationLoader: controller.isFetchingSearchResult,
                );
        },
      ),
      bottomNavigationBar: const CustNavigationBar(),
    );
  }
}
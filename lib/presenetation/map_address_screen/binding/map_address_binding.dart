import 'package:get/get.dart';
import '../controller/map_address_controller.dart';

class MapAddressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MapAddressController());
  }
}

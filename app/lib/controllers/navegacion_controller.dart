import 'package:get/get.dart';

class NavegacionController extends GetxController {
  final RxInt indice = 0.obs;

  void ir(int i) => indice.value = i;
}

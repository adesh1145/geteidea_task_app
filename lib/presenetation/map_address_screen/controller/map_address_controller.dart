import 'dart:ui' as ui;
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../models/address_list_model.dart';
import '../../../models/polyline_response.dart';
import '../../../models/selected_location_model.dart';
import '../../../services/permission_handler_service.dart';
import '../../login_screen/login_screen.dart';

class MapAddressController extends GetxController {
  //!  Map Address Screen Data

  // 25.174316, 82.798938
  final arguments = Get.arguments;
  RxBool isLoading = false.obs;
  final initialCameraPosition =
      const CameraPosition(target: LatLng(29.000082, 77.760616), zoom: 12);
  final Completer<GoogleMapController> googleMapController = Completer();
  late final CameraPosition cameraPosition;
  final markers = <Marker>[].obs;
  var selectedPickupAddress = Prediction().obs;
  RxString pickupAddress = ''.obs;
  LatLng selectedPickLatlng = const LatLng(0.0, 0.0);
  var selectedDropAddress = Prediction().obs;
  RxString dropAddress = ''.obs;
  LatLng selectedDropLatlng = const LatLng(0.0, 0.0);

  RxList legs = [].obs;
  RxString polylineData = "".obs;
  RxList<PointLatLng> points = <PointLatLng>[].obs;
  RxList<LatLng> latLngPoints = <LatLng>[].obs;
  @override
  void onInit() async {
    isLoading(true);
    markers.add(const Marker(
      markerId: MarkerId('pickup_location'),
      draggable: false,
      visible: true,
      position: LatLng(0, 0),
      infoWindow: InfoWindow(title: 'Pickup Address'),
    ));
    markers.add(const Marker(
      markerId: MarkerId('drop_location'),
      draggable: false,
      visible: true,
      position: LatLng(0, 0),
      infoWindow: InfoWindow(title: 'Drop Address'),
    ));
    await getCurrentLocation();
    isLoading(false);
    super.onInit();
  }

  Future<void> getCurrentLocation() async {
    await MyLocation.fetchCurrentLocation().then((value) {
      if (value != null && value.latitude != null && value.longitude != null) {
        _updateCameraPosition(LatLng(value.latitude!, value.longitude!));
      } else {
        print("Location Not Fetching....");
      }
    });
  }

  Future<void> _updateMarkers(LatLng latLng, {isDropLocation = false}) async {
    markers[0] = markers[0].copyWith(
        positionParam: selectedPickLatlng,
        visibleParam: true,
        onDragEndParam: onMapActivity);
    markers[1] = markers[1].copyWith(
        positionParam: selectedDropLatlng,
        visibleParam: true,
        onDragEndParam: onMapActivity);
  }

  Future<void> _updateCameraPosition(LatLng latLng,
      {bool isDropLocation = false}) async {
    try {
      final controller = await googleMapController.future;
      if (isDropLocation) {
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            selectedPickLatlng.latitude < selectedDropLatlng.latitude
                ? selectedPickLatlng.latitude
                : selectedDropLatlng.latitude,
            selectedPickLatlng.longitude < selectedDropLatlng.longitude
                ? selectedPickLatlng.longitude
                : selectedDropLatlng.longitude,
          ),
          northeast: LatLng(
            selectedPickLatlng.latitude > selectedDropLatlng.latitude
                ? selectedPickLatlng.latitude
                : selectedDropLatlng.latitude,
            selectedPickLatlng.longitude > selectedDropLatlng.longitude
                ? selectedPickLatlng.longitude
                : selectedDropLatlng.longitude,
          ),
        );
        await getPolyPoint();
        controller.moveCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      } else {
        controller.moveCamera(CameraUpdate.newLatLngZoom(latLng, 18));
      }
    } catch (e) {
      throw e.toString();
    }
  }

  void onMapActivity(LatLng latLng) async {
    _updateMarkers(latLng);
  }

  Future<void> getSelectedLatLong(Prediction prediction,
      {bool isDropLocation = false}) async {
    String apiURL =
        "https://maps.googleapis.com/maps/api/place/details/json?placeid=${prediction.placeId}&key=AIzaSyDlyvDZQbwT6O9iNNA5wdKp8z62o2cxEzs";
    if (prediction.description!.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your pickup location");
      return;
    }
    try {
      var response = await Dio().get(apiURL);
      Map<String, dynamic> jsonBodyMap = response.data;

      if (response.statusCode == 200) {
        var data = SelectedLocationModel.fromJson(jsonBodyMap);

        var selectedLocation = LatLng(
            data.result?.geometry?.location?.lat ?? 0.0,
            data.result?.geometry?.location?.lng ?? 0.0);
        isDropLocation == true
            ? selectedDropLatlng = selectedLocation
            : selectedPickLatlng = selectedLocation;
        _updateCameraPosition(selectedLocation, isDropLocation: isDropLocation);
        _updateMarkers(selectedLocation, isDropLocation: isDropLocation);
      } else {
        Fluttertoast.showToast(msg: "error while fetching geo-coding data");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Internal Server Error!");
      throw e.toString();
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<List<Prediction>> loadAutoComplete(String location) async {
    if (location.isEmpty) return [];
    try {
      final url =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$location&key=AIzaSyDlyvDZQbwT6O9iNNA5wdKp8z62o2cxEzs" +
              "&components=country:in";
      final response =
          await Dio(BaseOptions(headers: {'Accept': 'application/json'}))
              .get(url);
      Map<String, dynamic> jsonBodyMap = response.data;
      if (response.statusCode == 200) {
        return AddressListModel.fromJson(jsonBodyMap).predictions ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<void> getPolyPoint() async {
    try {
      final url =
          "https://maps.googleapis.com/maps/api/directions/json?key=AIzaSyDlyvDZQbwT6O9iNNA5wdKp8z62o2cxEzs&units=metric&origin="
          "${selectedPickLatlng.latitude},${selectedPickLatlng.longitude}&destination=${selectedDropLatlng.latitude},${selectedDropLatlng.longitude}&mode+=driving"; //&alternatives=false
      final response =
          await Dio(BaseOptions(headers: {'Accept': 'application/json'}))
              .get(url);
      if (response.statusCode == 200) {
        var polylineResponseModel =
            PolylineResponseModel.fromJson(response.data);
        polylineData.value = polylineResponseModel
            .routes![0].overviewPolyline!.points
            .toString();
        points.value = PolylinePoints().decodePolyline(polylineData.value);

        latLngPoints.value = points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        update();
        String distance = (double.parse(polylineResponseModel
                    .routes![0].legs![0].distance!.value
                    .toString()) /
                1000)
            .toStringAsFixed(2);
        // .round();
      } else {}
    } catch (e) {}
  }

  Future<bool> signOutFromGoogle() async {
    isLoading(true);
    try {
      await FirebaseAuth.instance.signOut();
      isLoading(false);
      Get.off(() => const LoginScreen());
      return true;
    } on Exception catch (_) {
      isLoading(false);
      return false;
    }
  }
}

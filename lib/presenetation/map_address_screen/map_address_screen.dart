import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/address_list_model.dart';
import 'controller/map_address_controller.dart';

class MapAddressScreen extends StatelessWidget {
  const MapAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MapAddressController>(
        init: MapAddressController(),
        builder: (controller) {
          return Obx(
            () => Scaffold(
              appBar: AppBar(
                title: const Text("Map Screeen"),
                actions: [
                  IconButton(
                      onPressed: () {
                        controller.signOutFromGoogle();
                      },
                      icon: Icon(Icons.logout))
                ],
              ),
              body: Container(
                  width: double.maxFinite,
                  margin: const EdgeInsets.only(top: 5),
                  child: Stack(children: [
                    GoogleMap(
                      initialCameraPosition: controller.initialCameraPosition,
                      onMapCreated:
                          (GoogleMapController googleMapController) async {
                        // googleMapController.showMarkerInfoWindow(
                        //   const MarkerId("pickup_location"),
                        // );

                        // if (!controller.googleMapController.isCompleted) {
                        controller.googleMapController
                            .complete(googleMapController);
                        // }
                      },
                      polylines: Set<Polyline>.from([
                        Polyline(
                          polylineId: const PolylineId('location'),
                          points: controller.latLngPoints,
                          color: Colors.blue,
                          width: 3,
                        ),
                      ]),
                      mapType: MapType.normal,
                      compassEnabled: true,
                      zoomControlsEnabled: true,
                      zoomGesturesEnabled: true,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: true,
                      mapToolbarEnabled: false,
                      rotateGesturesEnabled: true,
                      // onTap: controller.onMapActivity,
                      markers: Set.from(controller.markers),

                      // padding: EdgeInsets.symmetric(horizontal: 30),
                      minMaxZoomPreference: const MinMaxZoomPreference(6, 28),
                    ),
                    Column(
                      children: [
                        const SizedBox(
                          height: 5,
                        ),
                        Autocomplete<Prediction>(
                          initialValue: TextEditingValue(
                            text: controller.pickupAddress.value,
                          ),
                          optionsBuilder:
                              (TextEditingValue textEditingValue) async {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<Prediction>.empty();
                            } else {
                              return await controller.loadAutoComplete(
                                  textEditingValue.text.trim());
                            }
                          },
                          displayStringForOption: (value) =>
                              value.description ?? "N/A",
                          onSelected: (value) {
                            controller.selectedPickupAddress.value = value;
                            controller.getSelectedLatLong(value);
                            // controller.currentAddress.value = value.toString();
                          },
                          fieldViewBuilder: (context, textEditingController,
                              focusNode, onFieldSubmitted) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 16, top: 16),
                              child: TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                    labelText: "Enter your pick up location",
                                    hintText: "Enter your pick up location",
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    border: OutlineInputBorder()),
                              ),
                            );
                          },
                          optionsViewBuilder: (BuildContext context,
                              Function onSelected,
                              Iterable<Prediction> options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                color: Colors.white,
                                child: ListView.builder(
                                  itemCount: options.length,
                                  shrinkWrap: true,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    Prediction prediction =
                                        options.elementAt(index);
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 3),
                                      child: ListTile(
                                        onTap: () async {
                                          controller.pickupAddress.value =
                                              prediction.description!
                                                  .toString();
                                          onSelected(prediction);
                                          // controller.isAddressNotEmpty
                                          //     .value = false;
                                          // await controller
                                          //     .getSelectedLatLong(
                                          //         prediction);
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                        },
                                        leading: const Icon(Icons.location_on),
                                        title: Text(
                                          prediction
                                              .structuredFormatting!.mainText!,
                                        ),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 3),
                                          child: Text(
                                            prediction.description!,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        Autocomplete<Prediction>(
                          initialValue: TextEditingValue(
                            text: controller.dropAddress.value,
                          ),
                          optionsBuilder:
                              (TextEditingValue textEditingValue) async {
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<Prediction>.empty();
                            } else {
                              return await controller.loadAutoComplete(
                                  textEditingValue.text.trim());
                            }
                          },
                          displayStringForOption: (value) =>
                              value.description ?? "N/A",
                          onSelected: (value) {
                            controller.selectedDropAddress.value = value;
                            controller.getSelectedLatLong(value,
                                isDropLocation: true);
                          },
                          fieldViewBuilder: (context, textEditingController,
                              focusNode, onFieldSubmitted) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 16, top: 16),
                              child: TextFormField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                    labelText: "Enter your Drop location",
                                    hintText: "Enter your Drop location",
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    border: OutlineInputBorder()),
                              ),
                            );
                          },
                          optionsViewBuilder: (BuildContext context,
                              Function onSelected,
                              Iterable<Prediction> options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                color: Colors.white,
                                child: ListView.builder(
                                  itemCount: options.length,
                                  shrinkWrap: true,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    Prediction prediction =
                                        options.elementAt(index);
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 3),
                                      child: ListTile(
                                        onTap: () async {
                                          controller.pickupAddress.value =
                                              prediction.description!
                                                  .toString();
                                          onSelected(prediction);
                                          // controller.isAddressNotEmpty
                                          //     .value = false;
                                          // await controller
                                          //     .getSelectedLatLong(
                                          //         prediction);
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();
                                        },
                                        leading: const Icon(Icons.location_on),
                                        title: Text(
                                          prediction
                                              .structuredFormatting!.mainText!,
                                        ),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 3),
                                          child: Text(
                                            prediction.description!,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: InkWell(
                        onTap: () async {
                          // controller.isLoading(true);
                          await controller.getCurrentLocation();
                          // controller.isLoading(false);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.background,
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.only(
                              top: 6, bottom: 6, left: 12, right: 12),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on),
                              Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    "Use my current location",
                                  ))
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (controller.isLoading.value)
                      const Opacity(
                        opacity: 0.5,
                        child: ModalBarrier(
                          barrierSemanticsDismissible: false,
                        ),
                      ),
                    if (controller.isLoading.value)
                      const Center(child: CircularProgressIndicator())
                  ])),
              bottomNavigationBar: Obx(
                () => Visibility(
                  visible: controller.isLoading.value ? false : true,
                  child: Container(
                    color: Theme.of(context).colorScheme.background,
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, bottom: 12, top: 12),
                    child: ElevatedButton(
                        onPressed: () {
                          // if (controller.selectedLocation != null) {
                          // } else {
                          //   Fluttertoast.showToast(
                          //       msg: "Please Slect Location");
                          // }
                        },
                        child: const Text("Draw PolyLine")),
                  ),
                ),
              ),
            ),
          );
        });
  }
}

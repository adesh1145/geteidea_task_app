import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:geteidea_task_app/presenetation/login_screen/controller/login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Screeen"),
      ),
      body: GetBuilder(
        init: LoginController(),
        builder: (controller) {
          return Form(
              key: controller.formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.phoneController,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10)
                      ],
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          hintText: "Mobile Number",
                          labelText: "Mobile Number",
                          border: OutlineInputBorder()),
                      validator: (value) => value != null && value.length != 10
                          ? "Enter 10 digit mobile number"
                          : null,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Obx(() => controller.isOtpFieldVisible.value
                        ? TextFormField(
                            controller: controller.otpController,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6)
                            ],
                            validator: (value) =>
                                controller.isOtpFieldVisible.value &&
                                        value != null &&
                                        value.length != 6
                                    ? "Please enter 6 digit OTP"
                                    : null,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                                hintText: "OTP",
                                labelText: "OTP",
                                border: OutlineInputBorder()),
                          )
                        : const SizedBox()),
                    const SizedBox(
                      height: 20,
                    ),
                    Obx(() => controller.isLoading.value
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () {
                              if (controller.formKey.currentState?.validate() ??
                                  false) {
                                if (controller.isOtpFieldVisible.value) {
                                  controller.verifyOTPCode();
                                } else {
                                  controller.verifyUserPhoneNumber();
                                }
                              }
                            },
                            child: const Text("Login "))),
                    const SizedBox(
                      height: 50,
                    ),
                    ElevatedButton(
                        onPressed: () {
                          controller.signInWithGoogle();
                        },
                        child: const Text("Google"))
                  ],
                ),
              ));
        },
      ),
    );
  }
}

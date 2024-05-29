import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:geteidea_task_app/presenetation/map_address_screen/map_address_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController extends GetxController {
  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
  }

  final formKey = GlobalKey<FormState>();
  RxBool isLoading = false.obs;
  RxBool isOtpFieldVisible = false.obs;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  RxnString verificationId = RxnString();
  Future<void> verifyUserPhoneNumber() async {
    isLoading(true);
    try {
      await auth.verifyPhoneNumber(
        phoneNumber: "+91${phoneController.text}",
        verificationCompleted: (PhoneAuthCredential credential) async {
          await auth.signInWithCredential(credential).then(
            (value) {
              isLoading(false);

              Get.offAll(() => const MapAddressScreen());
              Fluttertoast.showToast(msg: "Login Successfull");
            },
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          isLoading(false);
          Fluttertoast.showToast(msg: e.toString());
        },
        codeSent: (String verificationId, int? resendToken) {
          this.verificationId.value = verificationId;
          isOtpFieldVisible(true);
          isLoading(false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          isLoading(false);
          Fluttertoast.showToast(msg: "Time Out ");
        },
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> verifyOTPCode() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value ?? "",
        smsCode: otpController.text,
      );
      await auth.signInWithCredential(credential).then((value) {
        Fluttertoast.showToast(msg: "Login Successfull");

        Get.offAll(() => const MapAddressScreen());
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<dynamic> signInWithGoogle() async {
    try {
      isLoading(true);
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      var userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        print(userCredential.user!.email.toString());

        Fluttertoast.showToast(msg: "Login Successfull");
        Get.offAll(() => const MapAddressScreen());
      } else {
        Fluttertoast.showToast(msg: "Login Failed");
      }
      isLoading(false);
    } on Exception catch (e) {
      print('exception->$e');
    }
  }
}

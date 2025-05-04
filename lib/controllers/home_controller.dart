import 'dart:io';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shroom_card/constants/strings.dart';
import 'package:shroom_card/models/category_model.dart';
import 'package:shroom_card/models/mushroom_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class HomeController extends GetxController {
  File? selectedImage;
  bool isBrowse = true;
  List<MushroomModel> mushroomList = [];
  List<MushroomModel> allMushroomList = Get.arguments;
  TextEditingController searchController = TextEditingController();

  String? predictionResult; // storing prediction

  @override
  void onInit() {
    getCurrentMushroomList();
    super.onInit();
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        selectedImage = File(pickedFile.path);
        update();
        await predictMushroom(); // get the prediction
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> predictMushroom() async {
    if (selectedImage == null) return;

    final uri = Uri.parse('http://192.168.1.23:8000/api/predict');

    final request = http.MultipartRequest('POST', uri);

    // Manually specify the content type
    final imageFile = await http.MultipartFile.fromPath(
      'file',
      selectedImage!.path,
      contentType: MediaType('image', 'jpeg'),
    );

    request.files.add(imageFile);

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = json.decode(responseBody);
        final prediction = result['prediction'];
        final probs = result['probabilities'];

        predictionResult = prediction;
        update();

        Get.snackbar('Prediction', 'Detected: $prediction');
      } else {
        print('Server error: $responseBody');
        Get.snackbar('Error', 'Server error: $responseBody');
      }
    } catch (e) {
      print('Error sending image: $e');
      Get.snackbar('Error', 'Failed to connect to the server');
    }
  }

  List<CategoryModel> categories = [
    CategoryModel(AppStrings.allText, isSelected: true),
    CategoryModel(AppStrings.poisonousText, isSelected: false),
    CategoryModel(AppStrings.nonPoisonousText, isSelected: false),
    CategoryModel(AppStrings.edibleText, isSelected: false),
    CategoryModel(AppStrings.nonEdibleText, isSelected: false),
  ];

  void getCurrentMushroomList() {
    String selectedCategory =
        categories.firstWhere((element) => element.isSelected).title;
    if (selectedCategory == AppStrings.poisonousText) {
      mushroomList =
          allMushroomList
              .where((element) => element.category == AppStrings.poisonousText)
              .toList();
    } else if (selectedCategory == AppStrings.nonPoisonousText) {
      mushroomList =
          allMushroomList
              .where(
                (element) => element.category == AppStrings.nonPoisonousText,
              )
              .toList();
    } else if (selectedCategory == AppStrings.edibleText) {
      mushroomList =
          allMushroomList
              .where((element) => element.category == AppStrings.poisonousText)
              .toList();
    } else if (selectedCategory == AppStrings.nonEdibleText) {
      mushroomList =
          allMushroomList
              .where(
                (element) => element.category == AppStrings.nonPoisonousText,
              )
              .toList();
    } else {
      mushroomList = allMushroomList;
    }
    update();
  }
}

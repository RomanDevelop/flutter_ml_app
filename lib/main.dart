import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Classifier',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _image; // Переменная для хранения выбранного изображения
  String _result = ''; // Переменная для хранения результата классификации

  Future<void> uploadImage(XFile image) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://127.0.0.1:8000/predict/'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final result = json.decode(respStr);
      setState(() {
        _result =
            'Результат: ${result['target']}\nВероятности: ${result['targetProbability']}';
      });
      print("Результат классификации: $_result");
    } else {
      setState(() {
        _result = "Ошибка: ${response.statusCode}";
      });
      print("Ошибка: ${response.statusCode}");
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path); // Сохранение выбранного изображения
      });
      await uploadImage(image);
    }
  }

  // Функция для сброса состояния
  void reset() {
    setState(() {
      _image = null; // Сброс изображения
      _result = ''; // Сброс результата
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image Classifier")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Отображение выбранного изображения
            _image != null
                ? Image.file(
                    _image!,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                  )
                : Text("Выберите изображение", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              child: Text("Выбрать изображение"),
            ),
            SizedBox(height: 20),
            // Отображение результатов классификации
            Text(
              _result.isNotEmpty
                  ? _result
                  : "Результат классификации появится здесь",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Кнопка сброса состояния
            ElevatedButton(
              onPressed: reset,
              child: Text("Сбросить"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red), // Красная кнопка
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authentication App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  String? _userId;
  String? _jwtToken;
  String? _refreshToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                loginUser(_emailController.text);
              },
              child: Text('Login'),
            ),
            if (_userId != null)
              Column(
                children: [
                  SizedBox(height: 16.0),
                  Text('Авторизован'),
                  Text('ID пользователя: $_userId'),
                  Text('JWT: $_jwtToken'),
                  Text('Refresh Token: $_refreshToken'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> loginUser(String email) async {
    if (!isValidEmail(email)) {
      // Вывод предупреждения пользователю о некорректном email
      return;
    }

    final response = await http.post(
      Uri.parse('https://d5dsstfjsletfcftjn3b.apigw.yandexcloud.net/login'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{'email': email}),
    );

    if (response.statusCode == 200) {
      // Получение одноразового кода для авторизации
      final Map<String, dynamic> data = jsonDecode(response.body);
      final code = data['code'];
      
      // Обмен одноразового кода на RT и JWT
      final authResponse = await confirmCodeAndGetTokens(email, code);
      if (authResponse.statusCode == 200) {
        final Map<String, dynamic> authData = jsonDecode(authResponse.body);
        final userId = authData['user_id'];
        final jwtToken = authData['jwt'];
        final refreshToken = authData['refresh_token'];
        setState(() {
          _userId = userId;
          _jwtToken = jwtToken;
          _refreshToken = refreshToken;
        });
        // Сохранение RT и JWT в безопасном хранилище
        await saveTokens(jwtToken, refreshToken);
      } else {
        // Handle error
        // Например, вывод сообщения об ошибке
      }
    } else {
      // Handle error
      // Например, вывод сообщения об ошибке
    }
  }

  Future<http.Response> confirmCodeAndGetTokens(String email, int code) async {
    return await http.post(
      Uri.parse('https://d5dsstfjsletfcftjn3b.apigw.yandexcloud.net/confirm_code'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{'email': email, 'code': code}),
    );
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> saveTokens(String jwtToken, String refreshToken) async {
    await storage.write(key: 'jwt_token', value: jwtToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
  }
}

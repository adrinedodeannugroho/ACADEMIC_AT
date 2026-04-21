import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {

  static Future getData() async {

    final response = await http.get(
      Uri.parse("https://jsonplaceholder.typicode.com/posts")
    );

    return jsonDecode(response.body);

  }

}
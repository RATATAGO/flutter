import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:path/path.dart' as p;

/*import 'package:first_project/assets/images//image_item.dart'; // Import the ImageItem class
import './details_screen.dart';
// Import the ImageItem class*/

void main() {
  runApp(
    const MyApp(
      child: MainScreen(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.child});

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 24),
    displayMedium: TextStyle(fontSize: 20),
    bodyLarge: TextStyle(fontSize: 16),
  );

  static final ThemeData theme = ThemeData(
    primaryColor: Colors.blue,
    textTheme: _textTheme,
  );

  static MaterialApp _materialApp({required Widget child}) {
    return MaterialApp(
      title: 'Image App',
      theme: MyApp.theme,
      home: child,
    );
  }

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MyApp._materialApp(child: child);
  }
}


class ImageItem {
  final int? id;
  final String? prompt;
  final String? imageUrl;
  final DateTime date;

  ImageItem({
    required this.id,
    required this.prompt,
    required this.imageUrl,
    required this.date,
  });

  factory ImageItem.fromJson(Map<String, dynamic> json) {
    return ImageItem(
      id: json['id'],
      prompt: json['prompt'],
      imageUrl: json['https://rscouncil.org/wp-content/uploads/2020/01/purple-background-png-png-group-romolagaraiorg-1920_1080.png'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prompt': prompt,
      'imageUrl': imageUrl,
      'date': date.toIso8601String(),
    };
  }
}

class MainScreen extends StatefulWidget {
  final http.Client? httpClient;

  const MainScreen({super.key, this.httpClient});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final _searchController = TextEditingController();
  List<ImageItem> _imageItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImageItems();
  }

  Future<void> _loadImageItems() async {
    final db = await _initializeDatabase();
    final cachedImageItems = await _fetchCachedImageItems(db);
    setState(() {
      _imageItems = cachedImageItems;
    });
  }

  Future<sqlite.Database> _initializeDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'images.db');
    return await sqlite.openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE image_items(id INTEGER PRIMARY KEY, prompt TEXT, date TEXT, imageUrl TEXT)');
    });
  }

  Future<List<ImageItem>> _fetchCachedImageItems(sqlite.Database db) async {
    final maps = await db.query('image_items');
    return List.generate(maps.length, (i) {
      final map = maps[i];
      return ImageItem(
        id: map['id'] as int?,
        prompt: map['prompt'] as String?,
        date: DateTime.parse(map['date'] as String),
        imageUrl: map['imageUrl'] as String?,
      );
    });
  }

  Future<void> _createImage(String? prompt) async {
    if (prompt == null || prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://rscouncil.org/wp-content/uploads/2020/01/purple-background-png-png-group-romolagaraiorg-1920_1080.png'),
        body: {'prompt': prompt},
      );

      if (response.statusCode == 201) {
        final newImage = ImageItem.fromJson(jsonDecode(response.body));
        setState(() {
          _imageItems.insert(0, newImage);
          _isLoading = false;
        });

        final db = await _initializeDatabase();
        await db.insert('image_items', newImage.toMap());
      } else {
        throw Exception('Failed to create image');
      }
    } catch (e) {
      showErrorSnackBar(e.toString());
    }
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Image Generator'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: _imageItems.length,
        itemBuilder: (context, index) {
          final imageItem = _imageItems[index];
          return ListTile(
            leading: Image.network(imageItem.imageUrl ?? "https://example.com/placeholder.jpg"),
            title: Text(imageItem.prompt ?? ""),
            subtitle: Text(imageItem.date.toString()),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsScreen(imageItem),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final prompt = _searchController.text;
          _searchController.clear();

          if (prompt.isNotEmpty) {
            try {
              await _createImage(prompt);
            } catch (e) {
              showErrorSnackBar(e.toString());

            }
          }
        },
        tooltip: 'Create Image',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class DetailsScreen extends StatefulWidget {
  final ImageItem imageItem;

  const DetailsScreen(this.imageItem, {super.key});

  @override
  DetailsScreenState createState() => DetailsScreenState();
}

class DetailsScreenState extends State<DetailsScreen> {
  late ImageItem imageItem;

  @override
  void initState() {
    super.initState();
    imageItem = widget.imageItem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Details'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(imageItem.imageUrl ?? ""),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Prompt: ${imageItem.prompt ?? ""}'),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Date: ${imageItem.date.toString()}'),
          ),
        ],
      ),
    );
  }
}



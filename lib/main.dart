import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class TranslationResponse {
  final String text;

  const TranslationResponse({required this.text});

  factory TranslationResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'text': String text,
      } =>
        TranslationResponse(
          text: text,
        ),
      _ => throw const FormatException('Failed to load album.'),
    };
  }
}

Future<TranslationResponse> translate(
    String text, String srcLang, String trgLang) async {
  final queryParameters = {
    'text': text,
    'src_lang': srcLang,
    'trg_lang': trgLang
  };

  const url = 'http://localhost:1308/translation/translate';

  try {
    final response = await http.get(
        Uri.parse(url).replace(queryParameters: queryParameters),
        headers: {
          "Access-Control-Allow-Origin": "*",
          'Content-Type': 'application/json',
          'Accept': '*/*'
        });
    return TranslationResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  } catch (err) {
    throw Exception('Failed to load album');
  }
}

void main() {
  runApp(const TranslatorApp());
}

class TranslatorApp extends StatelessWidget {
  const TranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Translator Extension',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TranslatorAppPage(title: 'Машинный перевод'),
    );
  }
}

class TranslatorAppPage extends StatefulWidget {
  const TranslatorAppPage({super.key, required this.title});

  final String title;

  @override
  State<TranslatorAppPage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<TranslatorAppPage>
    with TickerProviderStateMixin {
  final srcTextController = TextEditingController();
  final trgTextController = TextEditingController();

  late TabController srcTabController;
  late TabController trgTabController;

  late String srcLang;
  late String trgLang;

  late String message = 'Переводим...';

  Map<String, String> langToId = {
    'Немецкий': 'de_DE',
    'Английский': 'en_XX',
    'Хинди': 'hi_IN',
    'Французский': 'fr_XX',
    'Русский': 'ru_RU',
    'Китайский': 'zh_CN',
  };

  late List<String> langList;

  @override
  void initState() {
    super.initState();
    srcTabController = TabController(
        length: langToId.keys.length, vsync: this, initialIndex: 1);
    trgTabController = TabController(
        length: langToId.keys.length, vsync: this, initialIndex: 4);
    langList = langList = langToId.keys.toList();
    srcLang = 'Английский';
    trgLang = 'Русский';
  }

  @override
  void dispose() {
    srcTextController.dispose();
    trgTextController.dispose();
    srcTabController.dispose();
    trgTabController.dispose();
    super.dispose();
  }

  void _selectSrcLang(int id) {
    setState(() {
      srcLang = langList[id].toString();
    });
  }

  void _selectTrgLang(int id) {
    setState(() {
      trgLang = langList[id].toString();
    });
  }

  void _getTranslation(String text, String srcLang, String trgLang) {
    trgTextController.text = message;
    translate(text, srcLang, trgLang).then((value) => trgTextController.text = value.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16),
            child: Column(
              children: [
                TabBar(
                  controller: srcTabController,
                  tabs: [
                    for (var name in langList)
                      Tab(
                          child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                      ))
                  ],
                  onTap: (int id) => _selectSrcLang(id),
                ),
                TextField(
                  controller: srcTextController,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(), hintText: srcLang),
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: trgTabController,
                  tabs: [
                    for (var name in langList)
                      Tab(
                          child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                      ))
                  ],
                  onTap: (int id) => _selectTrgLang(id),
                ),
                TextField(
                  controller: trgTextController,
                  readOnly: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: trgLang),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: trgTextController.text))
                        .then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Скопировано в буфер обмена!')));
                    });
                  },
                  child: const Text('Копировать'),
                ),
              ],
            )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          _getTranslation(
              srcTextController.text,
              langToId[langList[srcTabController.index]]!,
              langToId[langList[trgTabController.index]]!),
        },
        tooltip: 'Перевести',
        child: const Icon(Icons.translate),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';
import '../provider/darkThemeProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _search;
  int _offset = 0;
  late ScrollController _scrollController;
  bool isShowTrending = false;
  IconData floatingIcon = Icons.trending_up;

  Future<Map> _getGifs() async {
    http.Response response;
      response = await http.get(
          Uri.parse('https://api.giphy.com/v1/gifs/search?api_key=A7075FUisBJcmNOlLeBXjV5sDy7Rdfnz&q=$_search&limit=100&offset=$_offset&rating=g&lang=pt'));
    return json.decode(response.body);
  }

  Future<Map> _getTrendingGifs() async {
    http.Response response;
    response = await http.get(
        Uri.parse('https://api.giphy.com/v1/gifs/trending?api_key=A7075FUisBJcmNOlLeBXjV5sDy7Rdfnz&limit=10&rating=g'));
    return json.decode(response.body);
  }

  _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() {
          print("RUNNING LOAD MORE");
          _offset += 5;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getGifs();
    _scrollController = ScrollController(initialScrollOffset: 5.0)
      ..addListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Giphy", style: TextStyle(color: Theme.of(context).primaryColor)),
              Checkbox(
                  value: themeProvider.darkTheme,
                  onChanged: (bool? value) {
                    themeProvider.darkTheme = value!;
                  })
            ],
          )
      ),
      floatingActionButton: FloatingActionButton(
        child: Center(child: Icon(floatingIcon)),
        onPressed: () {
          setState(() {
            if(!isShowTrending) {
              isShowTrending = true;
              floatingIcon = Icons.search;
            } else {
              isShowTrending = false;
              floatingIcon = Icons.trending_up;
            }
          });
        },
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search gif:',
                labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                border: const OutlineInputBorder(),
              ),
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              onSubmitted: (text) {
                setState(() {
                  _search = text;
                  _offset = 0;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder(
                future: isShowTrending? _getTrendingGifs() : _getGifs(),
                builder: (context, snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                    case ConnectionState.none:
                      return Container(
                        width: 200,
                        height: 200,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                          strokeWidth: 5.0,
                        ),
                      );
                    default:
                      if (snapshot.hasError) {
                        return Container();
                      } else {
                        return _createGifTable(context, snapshot);
                      }
                  }
                }
            ),
          ),
        ],
      ),
    );
  }

  int _getCount(List data) {
    if (_search == null || _search.isEmpty) {
      return data.length;
    } else {
      return data.length + 1;
    }
  }

  Widget _createGifTable(BuildContext context, AsyncSnapshot snapshot) {
    return GridView.builder(
      controller: _scrollController,
        padding: const EdgeInsets.all(10.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        itemCount: _getCount(snapshot.data['data']),
        itemBuilder: (context, index) {
          if (_search == null || index < snapshot.data['data'].length) {
            return GestureDetector(
              child: FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: snapshot.data
                  ['data'][index]['images']['fixed_height']['url'],
                  height: 300.0,
                  fit: BoxFit.cover),
              onTap: () {
              },
            );
          }
        }
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
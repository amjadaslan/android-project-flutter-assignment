import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:ui';

import 'package:english_words/english_words.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hello_me/auth.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'login.dart';
import 'auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return ChangeNotifierProvider(
              create: (context) => AuthRepository.instance(),
              child: const MyApp());
        }
        return Container(
          width: 500,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
          ),
          padding: const EdgeInsets.all(20),
          child: Center(),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Startup Name Generator',
      theme: ThemeData(
        // Add the 5 lines from here...
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          //foregroundColor: Colors.black,
        ),
      ),
      home: Scaffold(body: RandomWords()),
    );
  }
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};

  final _biggerFont = const TextStyle(fontSize: 18);
  bool swiped_up = false;
  double blur_fil = 0.0;
  final snappingSheetController = SnappingSheetController();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRepository>(
      builder: (context, AuthRepository user, _) {
        String? s = user.user?.email;
        return Scaffold(
          // Add from here...
          appBar: AppBar(
            title: const Text('Startup Name Generator'),
            actions: [
              IconButton(
                icon: const Icon(Icons.star),
                onPressed: () => _pushSaved(user),
                tooltip: 'Saved Suggestions',
              ),
              user.status == Status.Authenticated
                  ? IconButton(
                      icon: const Icon(Icons.exit_to_app),
                      onPressed: () {
                        _uploadToCloud();
                        user.signOut();
                        setState(() {
                          _saved.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Successfully logged out.')));
                      },
                      tooltip: 'Logout',
                    )
                  : IconButton(
                      icon: const Icon(Icons.login),
                      onPressed: _loginPage,
                      tooltip: 'Login',
                    )
            ],
          ),
          body: user.isAuthenticated
              ? SnappingSheet(
                  controller: snappingSheetController,
                  child: Stack(children: [
                    _buildSuggestions(),
                    if (blur_fil == 5.0)
                      Positioned.fill(
                          child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: blur_fil,
                                sigmaY: blur_fil,
                              ),
                              child: Container(color: Colors.transparent)))
                  ]),
                  initialSnappingPosition:
                      const SnappingPosition.pixels(positionPixels: 30),
                  snappingPositions: [
                    swiped_up
                        ? const SnappingPosition.pixels(
                            positionPixels: 120,
                            snappingCurve: Curves.easeOutExpo,
                            snappingDuration: Duration(seconds: 1),
                            grabbingContentOffset: GrabbingContentOffset.top,
                          )
                        : const SnappingPosition.factor(
                            positionFactor: 0.0,
                            snappingCurve: Curves.easeOutExpo,
                            snappingDuration: Duration(seconds: 1),
                            grabbingContentOffset: GrabbingContentOffset.top,
                          )
                  ],
                  grabbingHeight: 60,
                  grabbing: GestureDetector(
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AutoSizeText('Welcome back, $s', maxLines: 1),
                                swiped_up
                                    ? const Icon(
                                        Icons.keyboard_arrow_down_rounded)
                                    : const Icon(
                                        Icons.keyboard_arrow_up_rounded)
                              ])),
                      onTap: () {
                        setState(() {
                          swiped_up
                              ? snappingSheetController
                                  .setSnappingSheetPosition(30)
                              : snappingSheetController
                                  .setSnappingSheetPosition(150);
                          swiped_up ? blur_fil = 0.0 : blur_fil = 5.0;
                          swiped_up = !swiped_up;
                        });
                      }),
                  sheetBelow: SnappingSheetContent(
                    child: _showProfile(user),
                  ))
              : _buildSuggestions(),
        );
      },
    );
  }

  Widget _showProfile(AuthRepository user) {
    String _imageURL = 'https://cdn-icons-png.flaticon.com/512/847/847969.png';
    String? s = user.user?.email;

    return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FutureBuilder(
              future: user.getDLink(),
              builder: (context, AsyncSnapshot<String> snapshot) {
                _imageURL = snapshot.data ??
                    'https://cdn-icons-png.flaticon.com/512/847/847969.png';
                return CircleAvatar(
                    backgroundImage: NetworkImage(_imageURL), radius: 40);
              }),
          const SizedBox(width: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AutoSizeText('$s',
                style: const TextStyle(fontSize: 20), maxLines: 1),
            const SizedBox(height: 8),
            TextButton(
                child: const AutoSizeText("Change avatar",
                    style: TextStyle(fontSize: 10), maxLines: 1),
                style: TextButton.styleFrom(
                    primary: Colors.white,
                    fixedSize: const Size(120, 10),
                    backgroundColor: Colors.lightBlue),
                onPressed: () => _imagePicker(user))
          ])
        ]));
  }

  void _imagePicker(AuthRepository user) async {
    final picker = ImagePicker();
    XFile? pickedImage;

    pickedImage =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);

    if (pickedImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No image selected')));
      return;
    }

    File imageFile = File(pickedImage.path);

    // Uploading the selected image
    String? userID = user.user?.uid;
    await FirebaseStorage.instance.ref('$userID/profilePic').putFile(imageFile);
  }

  void _loginPage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Login()))
        .then((value) {
      _updateSaved();
      _uploadToCloud();
    });
  }

  void _removeFromCloud(WordPair pair) {
    final user = AuthRepository.instance();
    if (user.isAuthenticated) {
      FirebaseFirestore.instance
          .collection("userSaved")
          .doc(user.user!.uid.toString())
          .collection("favorites")
          .doc(pair.toString())
          .delete();
    }
  }

  void _uploadToCloud() {
    final user = AuthRepository.instance();
    if (user.isAuthenticated) {
      _saved.forEach((e) async {
        await FirebaseFirestore.instance
            .collection("userSaved")
            .doc(user.user!.uid.toString())
            .collection("favorites")
            .doc(e.toString())
            .set({"first": e.first, "second": e.second});
      });
    }
  }

  void _updateSaved() async {
    final user = AuthRepository.instance();
    if (user.isAuthenticated) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("userSaved")
          .doc(user.user?.uid.toString())
          .collection("favorites")
          .get();
      List<QueryDocumentSnapshot> favs = snapshot.docs;

      Set<WordPair> addToSaved = new HashSet();
      favs.forEach(
          (e) => {addToSaved.add(WordPair(e.get('first'), e.get('second')))});
      _saved.addAll(addToSaved);
    }
  }

  void _pushSaved(AuthRepository user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          var tiles = _saved.map(
            (pair) {
              return _getDismissible(pair);
            },
          );

          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
                  context: context,
                  tiles: tiles,
                ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(key: UniqueKey(), children: divided),
          );
        },
      ),
    );
  }

  Widget _getDismissible(WordPair pair) {
    String capPair = pair.asPascalCase;
    return Dismissible(
      key: UniqueKey(),
      child: ListTile(
          key: UniqueKey(),
          title: Text(
            capPair,
            style: _biggerFont,
          )),
      confirmDismiss: (direction) async {
        bool flag = await _getDialog(pair);
        if (flag) _removePair(pair);
        return flag;
      },
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        color: Colors.deepPurple,
        alignment: Alignment.centerLeft,
        child: Row(children: const [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(width: 5),
          Text('Delete Suggestion', style: TextStyle(color: Colors.white))
        ]),
      ),
    );
  }

  Future<bool> _getDialog(WordPair pair) async {
    String capPair = pair.asPascalCase;
    bool flag = false;
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Delete Suggestion"),
            content: Text(
                "Are you sure you want to delete $capPair from your saved suggestions?"),
            actions: [
              TextButton(
                child: Text("Yes"),
                style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    backgroundColor:
                        MaterialStateProperty.all(Colors.deepPurple)),
                onPressed: () {
                  setState(() {
                    flag = true;
                    Navigator.pop(context);
                  });
                },
              ),
              TextButton(
                child: Text("No"),
                style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    backgroundColor:
                        MaterialStateProperty.all(Colors.deepPurple)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
    return flag;
  }

  void _removePair(pair) {
    setState(() {
      _saved.remove(pair);
      _removeFromCloud(pair);
    });
  }

  Widget _buildSuggestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // The itemBuilder callback is called once per suggested
      // word pairing, and places each suggestion into a ListTile
      // row. For even rows, the function adds a ListTile row for
      // the word pairing. For odd rows, the function adds a
      // Divider widget to visually separate the entries. Note that
      // the divider may be difficult to see on smaller devices.
      itemBuilder: (context, i) {
        _updateSaved();
        // Add a one-pixel-high divider widget before each row
        // in the ListView.
        if (i.isOdd) {
          return const Divider();
        }

        // The syntax "i ~/ 2" divides i by 2 and returns an
        // integer result.
        // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
        // This calculates the actual number of word pairings
        // in the ListView,minus the divider widgets.
        final index = i ~/ 2;
        // If you've reached the end of the available word
        // pairings...
        if (index >= _suggestions.length) {
          // ...then generate 10 more and add them to the
          // suggestions list.
          _suggestions.addAll(generateWordPairs().take(10));
        }
        return _buildRow(_suggestions[index]);
      },
    );
  }

  Widget _buildRow(WordPair pair) {
    var alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.star : Icons.star_border,
        color: alreadySaved ? Colors.deepPurple : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
            _removeFromCloud(pair);
          } else {
            _saved.add(pair);
            _uploadToCloud();
          }
        });
      },
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

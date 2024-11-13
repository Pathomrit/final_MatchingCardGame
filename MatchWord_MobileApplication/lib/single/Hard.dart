import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:match_word/repository/firestore.dart';
import 'package:match_word/setting/DataSinglePlayer.dart';
import 'package:match_word/single/Level.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join, getDatabasesPath;
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class DatabaseHelper {
  static Database? _database;
  static const String dbName = 'Vword3.sqlite';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), dbName);
    print('Database path: $path');
    await _copyDatabase(dbName);
    return await openDatabase(path, version: 1);
  }

  Future<void> _copyDatabase(String dbName) async {
    String path = join(await getDatabasesPath(), dbName);
    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
      ByteData data = await rootBundle.load('assets/$dbName');
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }
  }
}

class CardData {
  String word;
  String imageData;

  CardData({required this.word, required this.imageData});
}

class Hard extends StatefulWidget {
  @override
  _Hard createState() => _Hard();
}

class _Hard extends State<Hard> {
  Future<List<Map<String, dynamic>>> fetchRandomData() async {
    final data = await getAppData("hard");

    List<int> indices = List<int>.generate(data.length, (int index) => index);
    indices.shuffle();
    List<String> randomWords = [];
    List<String> randomPicImages = [];
    List<String> randomWordImages = [];
    List<String> randomMeanings = [];

    for (int i = 0;
        i < DataCountCardHard.countCard.first.count_card ~/ 2;
        i++) {
      int currentIndex = indices[i];
      randomWords.add(data[currentIndex].word);
      randomPicImages.add(data[currentIndex].image);
      randomWordImages.add(data[currentIndex].wordImage);
      randomMeanings.add(data[currentIndex].meaning);
    }
    List<Map<String, dynamic>> randomData = [];
    for (int i = 0;
        i < DataCountCardHard.countCard.first.count_card ~/ 2;
        i++) {
      randomData.add({
        'Word': randomWords[i],
        'picImages': randomPicImages[i],
        'wordImages': randomWordImages[i],
        'Meaning': randomMeanings[i],
      });
    }

    return randomData;
  }

  String selectedBgImage = '';

  void RandomBg() {
    List<String> bgImages = [
      'assets/images/BgGame.png',
      'assets/images/BgGame1.png',
      'assets/images/GbGame2.png',
    ];
    Random randomBg = Random();
    int bgIndex = randomBg.nextInt(bgImages.length);
    selectedBgImage = bgImages[bgIndex];
  }

  List<int> selectedCards = [];
  List<String> picImages = [];
  List<String> wordImages = [];
  List<String> playedWords = [];
  List<String> word = [];
  List<String> meaning = [];
  List<bool> isFlipped = [];
  int maxTime = 60;
  int timeLeft = 0;
  int flips = 0;
  int matchedCard = 0;
  bool disableDeck = false;
  bool isPlaying = false;
  String cardOne = "";
  String cardTwo = "";
  Timer? timer;
  List<String> picGame = [];

  @override
  void initState() {
    super.initState();
    timeLeft = maxTime;
    matchedCard = 0;
    disableDeck = false;
    isResultDialogShowing = false;
    shuffleCard();
    RandomBg();
  }

  void shuffleCard() {
    fetchRandomData().then((data) async {
      final dir = await getApplicationDocumentsDirectory();

      List<String> fetchedWords = [];
      List<String> fetchedPicImages = [];
      List<String> fetchedWordImages = [];
      List<String> fetchedMeaning = [];
      data.forEach((item) {
        fetchedWords.add(item['Word']);
        fetchedPicImages.add("${dir.path}/assets/AppData/${item['picImages']}");
        fetchedWordImages.add("${dir.path}/assets/AppData/${item['wordImages']}");
        fetchedMeaning.add(item['Meaning']);
        word.add(item['Word']);
        meaning.add(item['Meaning']);
      });
      List<int> indices =
          List<int>.generate(fetchedWords.length, (int index) => index);
      indices.shuffle();
      List<String> shuffledWords = [];
      List<String> shuffledPicImages = [];
      List<String> shuffledWordImages = [];
      for (int i = 0; i < indices.length; i++) {
        shuffledWords.add(fetchedWords[indices[i]]);
        shuffledPicImages.add(fetchedPicImages[indices[i]]);
        shuffledWordImages.add(fetchedWordImages[indices[i]]);
      }
      setState(() {
        timeLeft = maxTime;
        picImages = shuffledPicImages
            .take(DataCountCardHard.countCard.first.count_card ~/ 2)
            .toList();
        wordImages = shuffledWordImages
            .take(DataCountCardHard.countCard.first.count_card ~/ 2)
            .toList();
        List<CardData> combinedData = [];
        for (int i = 0; i < picImages.length; i++) {
          combinedData.add(CardData(
              word: shuffledWords[i], imageData: shuffledPicImages[i]));
          combinedData.add(CardData(
              word: shuffledWords[i], imageData: shuffledWordImages[i]));
        }
        combinedData.shuffle();
        picGame = combinedData.map((data) => data.imageData).toList();
        playedWords = combinedData.map((data) => data.word).toList();
        isFlipped = List<bool>.filled(picGame.length, false);
        timer?.cancel();
        isPlaying = false;
        flips = 0;
        matchedCard = 0;
      });
    });
  }

  void showResultDialog(bool isWin) async {
    bool showWords = false;
    double dialogHeight = MediaQuery.of(context).size.height * 0.25;
    if (word.isEmpty || meaning.isEmpty) {
      await fetchRandomData();
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: dialogHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        child: Image.asset(
                          'assets/images/kid_ontheground.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              matchedCard ==
                                      DataCountCardHard
                                              .countCard.first.count_card ~/
                                          2
                                  ? "You Win"
                                  : "You Lose",
                              style: TextStyle(
                                fontSize: 30,
                                color: matchedCard ==
                                        DataCountCardHard
                                                .countCard.first.count_card ~/
                                            2
                                    ? Colors.green
                                    : Colors.red,
                                fontFamily: 'TonphaiThin',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Total Flips : ${flips ~/ 2}\nCard opened successfully : ${matchedCard}",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              fontFamily: 'TonphaiThin',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          Expanded(
                            child: showWords
                                ? ListView.builder(
                                    itemCount: word.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      return ListTile(
                                        title: Text(
                                          '${word[index]} - ${meaning[index]}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                            fontFamily: 'PandaThin',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : SizedBox(),
                          ),
                          showWords ? SizedBox(height: 20) : SizedBox(),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Visibility(
                              visible: !showWords,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showWords = true;
                                    dialogHeight =
                                        MediaQuery.of(context).size.height *
                                            0.6;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black, backgroundColor: Color(0xFFE4F8BA),
                                  side: BorderSide(color: Colors.green, width: 2),
                                ),
                                child: Text(
                                  "Words",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontFamily: 'TonphaiThin',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  isResultDialogShowing = false;
                                  timeLeft = maxTime;
                                  timerValueNotifier.value = timeLeft;
                                  RandomBg();
                                });
                                word.clear();
                                meaning.clear();
                                shuffleCard();
                                startTimer();
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black, backgroundColor: Color(0xFFE4F8BA),
                                side: BorderSide(color: Colors.green, width: 2),
                              ),
                              child: Text(
                                "Retry",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontFamily: 'TonphaiThin',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  isResultDialogShowing = false;
                                });
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Level()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black, backgroundColor: Color(0xFFE4F8BA),
                                side: BorderSide(color: Colors.green, width: 2),
                              ),
                              child: Text(
                                "Back",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontFamily: 'TonphaiThin',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      initTimer();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  bool isResultDialogShowing = false;
  ValueNotifier<int> timerValueNotifier = ValueNotifier<int>(60);

  void initTimer() {
    if (!mounted) return;
    if (timeLeft <= 0 ||
        matchedCard == DataCountCardHard.countCard.first.count_card ~/ 2) {
      timer?.cancel();
      if (mounted && !isResultDialogShowing) {
        isResultDialogShowing = true;
        if (matchedCard == DataCountCardHard.countCard.first.count_card ~/ 2) {
          showResultDialog(true);
        } else {
          disableDeck = true;
          showResultDialog(false);
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              disableDeck = false;
              isResultDialogShowing = false;
            }
          });
        }
      }
      return;
    }
    timeLeft--;
    timerValueNotifier.value = timeLeft;
  }

  void pauseTimer() {
    timer?.cancel();
  }

  void resumeTimer() {
    startTimer();
  }

  void showEnlargedImage(String image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Image.file(
              File(image),
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  void onTapCard(int index) async {
    if (!disableDeck &&
        !isFlipped[index] &&
        index >= 0 &&
        index < picGame.length &&
        timeLeft > 0) {
      if (!isPlaying) {
        isPlaying = true;
        timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
          initTimer();
        });
      }

      setState(() {
        flips += 1;
        isFlipped[index] = true;
        selectedCards.add(index);
      });

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Image.file(
                    File(picGame[index]),
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 10),
                IconButton(
                  icon: Image.asset(
                    'assets/images/Close.png',
                    width: 60,
                    height: 60,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      );

      if (cardOne.isEmpty) {
        cardOne = playedWords[index];
      } else if (cardTwo.isEmpty) {
        cardTwo = playedWords[index];
        print("Card One: $cardOne");
        print("Card Two: $cardTwo");

        if (cardOne != cardTwo) {
          await Future.delayed(Duration(milliseconds: 300));
          setState(() {
            for (int selectedIndex in selectedCards) {
              isFlipped[selectedIndex] = false;
            }
          });
        } else {
          matchedCard += 1;
          print(matchedCard);
          if (matchedCard ==
              DataCountCardHard.countCard.first.count_card ~/ 2) {
            if (!isResultDialogShowing) {
              isResultDialogShowing = true;
              await Future.delayed(Duration(milliseconds: 300));
              showResultDialog(true);
            }
          }
        }
        await Future.delayed(Duration(milliseconds: 300));
        setState(() {
          cardOne = "";
          cardTwo = "";
          selectedCards.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              selectedBgImage,
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Color(0xFFF9F7C9),
                    border: Border.all(color: Colors.black, width: 5.0),
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: timerValueNotifier,
                    builder: (context, value, child) {
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Time: ',
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: 'TonphaiThin',
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: '$value',
                              style: TextStyle(
                                fontSize: 30,
                                fontFamily: 'TonphaiThin',
                                fontWeight: FontWeight.bold,
                                color: value < 6 ? Colors.red : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  margin: EdgeInsets.all(20.0),
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF6B7AA1).withOpacity(0.1), width: 5.0),
                    borderRadius: BorderRadius.circular(30.0),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6B7AA1).withOpacity(0.50),
                        spreadRadius: 0,
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: DataColumCardHard.count.first.column_card,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 30,
                    ),
                    itemCount: picGame.length,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          onTapCard(index);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: isFlipped[index]
                              ? Image.file(
                                  File(picGame[index]),
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/BgCard/bgCard.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 10),
              IconButton(
                padding: EdgeInsets.only(top: 30),
                icon: Image.asset(
                  'assets/images/pause.png',
                  width: 40,
                  height: 40,
                ),
                onPressed: () {
                  pauseTimer();
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30.0)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image:
                                  AssetImage('assets/images/kid_colorful.png'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius:
                                BorderRadius.all(Radius.circular(30.0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  "Menu",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 50.0,
                                    fontFamily: 'DANKI',
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    resumeTimer();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black, backgroundColor: Color(0xFFE4F8BA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24.0, vertical: 12.0),
                                  ),
                                  child: Text(
                                    'Resume',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                      fontFamily: 'PandaThin',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    resumeTimer();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Level()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black, backgroundColor: Color(0xFFE4F8BA),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 24.0, vertical: 12.0),
                                  ),
                                  child: Text(
                                    'Back To Menu',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20.0,
                                      fontFamily: 'PandaThin',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(width: 60),
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Text(
                  'Hard Mode',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 40.0,
                    fontFamily: 'DANKI',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
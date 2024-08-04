import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const DarkModeApp());
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
}


final List<TutorialStep> tutorialSteps = [
  TutorialStep(
    message: 'Welcome to Go! This is your game board.',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
  ),
  TutorialStep(
    message: 'Stones are placed on the intersections of the lines.',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
  ),
  TutorialStep(
    message: 'Let\'s start by placing a black stone here.',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
    autoMove: true,
    move: [8, 0],
  ),
  TutorialStep(
    message: 'Now, White will place a stone here.',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
    autoMove: true,
    move: [8, 1],
  ),
  TutorialStep(
    message: 'Black makes another move here.',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
    autoMove: true,
    move: [6, 4],
  ),
  TutorialStep(
    message: 'Now, White captures the black stone by placing a stone here.',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
    autoMove: true,
    move: [7, 0],
  ),
  TutorialStep(
    message: 'Avoid making suicide moves, which are moves that have no liberties.',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
    autoMove: true,
    move: [8, 0],
  ),
  TutorialStep(
    message: 'You can pass your turn if you don\'t want to place a stone.',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
  ),
  TutorialStep(
    message: 'The game ends when both players pass consecutively.',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
  ),
  TutorialStep(
    message: 'Territories are empty points surrounded by a single player\'s stones.',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
  ),
  TutorialStep(
    message: 'Komi is added to White\'s score to balance Black\'s first move advantage.',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
  ),
  TutorialStep(
    message: 'The player with the most territory and captured stones wins the game. Good luck!',
    highlightPosition: Offset(0, 0),
    highlightSize: Size(461, 455),
  ),
];

class TutorialStep {
  final String message;
  final Offset highlightPosition;
  final Size highlightSize;
  final bool autoMove;
  final List<int>? move;

  TutorialStep({
    required this.message,
    required this.highlightPosition,
    required this.highlightSize,
    this.autoMove = false,
    this.move,
  });
}

class TutorialManager {
  final List<TutorialStep> _steps;
  int _currentStepIndex = 0;
  bool _isTutorialActive = true;

  TutorialManager(this._steps);

  TutorialStep get currentStep => _steps[_currentStepIndex];

  bool get isLastStep => _currentStepIndex == _steps.length - 1;

  bool get isTutorialActive => _isTutorialActive;

  void nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
    }
  }

  void endTutorial() {
    _isTutorialActive = false;
  }
}

class MCTSNode {
  MCTSNode? parent;
  List<MCTSNode> children = [];
  int visits = 0;
  double value = 0.0;
  late List<List<String>> boardState;
  late String player;
  List<int>? move;

  MCTSNode(this.boardState, this.player, {this.parent, this.move});

  bool isLeaf() => children.isEmpty;

  MCTSNode expand() {
    var emptyCells = [];
    for (int x = 0; x < boardState.length; x++) {
      for (int y = 0; y < boardState[x].length; y++) {
        if (boardState[x][y] == '') emptyCells.add([x, y]);
      }
    }
    if (emptyCells.isEmpty) return this;

    var newMove = emptyCells[Random().nextInt(emptyCells.length)];
    var newBoard = _cloneBoard(boardState);
    newBoard[newMove[0]][newMove[1]] = player;
    var newPlayer = player == 'B' ? 'W' : 'B';
    var newChild = MCTSNode(newBoard, newPlayer, parent: this, move: newMove);
    children.add(newChild);
    return newChild;
  }

  void update(double simulationResult) {
    visits++;
    value += simulationResult;
  }

  double uctValue() {
    if (visits == 0) return double.infinity;
    return value / visits + sqrt(2) * sqrt(log(parent!.visits) / visits);
  }

  List<List<String>> _cloneBoard(List<List<String>> originalBoard) {
    return originalBoard.map((row) => List<String>.from(row)).toList();
  }
}

class MCTSBot {
  int simulations = 1000;

  List<List<String>> _cloneBoard(List<List<String>> board) {
    return board.map((row) => List<String>.from(row)).toList();
  }

  MCTSNode _select(MCTSNode node) {
    while (!node.isLeaf()) {
      node = node.children.reduce((a, b) => a.uctValue() > b.uctValue() ? a : b);
    }
    return node;
  }

  double _simulate(MCTSNode node) {
    var board = _cloneBoard(node.boardState);
    var currentPlayer = node.player;
    Random random = Random();
    while (true) {
      var emptyCells = [];
      for (int x = 0; x < board.length; x++) {
        for (int y = 0; x < board[x].length; y++) {
          if (board[x][y] == '') emptyCells.add([x, y]);
        }
      }
      if (emptyCells.isEmpty) break;
      var move = emptyCells[random.nextInt(emptyCells.length)];
      board[move[0]][move[1]] = currentPlayer;
      currentPlayer = currentPlayer == 'B' ? 'W' : 'B';
    }
    return _evaluateBoard(board, node.player);
  }

  double _evaluateBoard(List<List<String>> board, String player) {
    int score = 0;
    for (var row in board) {
      for (var cell in row) {
        if (cell == player) {
          score++;
        } else if (cell != '') {
          score--;
        }
      }
    }
    return score.toDouble();
  }

  void _backpropagate(MCTSNode node, double result) {
    while (node.parent != null) {
      node.update(result);
      node = node.parent!;
    }
  }

  List<int> getBestMove(List<List<String>> board, String player) {
    var root = MCTSNode(board, player);
    for (int i = 0; i < simulations; i++) {
      var leaf = _select(root);
      var child = leaf.expand();
      var result = _simulate(child);
      _backpropagate(child, result);
    }
    return root.children.reduce((a, b) => a.visits > b.visits ? a : b).move!;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go(wéiqí)',
      routes: {
        '/multiplayer': (context) => const MultiplayerGame(),
      },
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: _isDarkMode ? _darkTheme() : _lightTheme(),
      home: GoGame(onThemeToggle: _toggleTheme),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      primarySwatch: Colors.blueGrey,
      scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: Colors.deepPurpleAccent, fontSize: 20),
        bodyMedium: TextStyle(color: Colors.deepPurpleAccent),
        titleMedium: TextStyle(color: Colors.deepPurple),
      ),
      iconTheme: const IconThemeData(color: Colors.deepPurple),
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.deepPurple,
        textTheme: ButtonTextTheme.primary,
      ),
      appBarTheme: const AppBarTheme(
        color: Color.fromARGB(255, 255, 255, 255),
        titleTextStyle: TextStyle(
          color: Colors.deepPurpleAccent,
          fontSize: 20,
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blueGrey,
      scaffoldBackgroundColor: const Color.fromARGB(255, 48, 48, 48),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(color: Colors.white, fontSize: 20),
        bodyMedium: TextStyle(color: Colors.white70),
        titleMedium: TextStyle(color: Colors.white),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.blueGrey,
        textTheme: ButtonTextTheme.primary,
      ),
      appBarTheme: const AppBarTheme(
        color: Color.fromARGB(255, 48, 48, 48),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
    );
  }
}

class MultiplayerGame extends StatefulWidget {
  const MultiplayerGame({super.key});

  @override
  _MultiplayerGameState createState() => _MultiplayerGameState();
}

class _MultiplayerGameState extends State<MultiplayerGame> with TickerProviderStateMixin {
  int boardSize = 9;
  late List<List<String>> board;
  late List<List<AnimationController>> controllers;
  late List<List<Animation<double>>> animations;
  bool isBlackTurn = true;
  int blackCaptures = 0;
  int whiteCaptures = 0;
  bool gameEnded = false;
  bool moveInProgress = false;
  bool playerPassed = false;
  bool isMuted = false;
  bool isConnected = false;
  String playerName = '';
  String opponentName = '';
  String gameId = '';
  int playerCount = 0; // Track the number of players

  late TutorialManager _tutorialManager;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    isConnected = false;
    _initializeBoard();
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _connectToPlayer();
    });
    _tutorialManager = TutorialManager(tutorialSteps);

    if (!isMuted) {
      _audioPlayer.setAsset('move_sound.mp3').then((_) => _audioPlayer.play());
    }
  }

  List<String> _flattenBoard(List<List<String>> board) {
    return board.expand((row) => row).toList();
  }

  List<List<String>> _reconstructBoard(List<String> flatBoard, int size) {
    return List.generate(size, (index) => flatBoard.sublist(index * size, (index + 1) * size));
  }


  @override
  void dispose() {
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeBoard() {
    board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
    controllers = List.generate(boardSize, (x) => List.generate(boardSize, (y) {
      return AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }));
    animations = List.generate(boardSize, (x) => List.generate(boardSize, (y) {
      return CurvedAnimation(
        parent: controllers[x][y],
        curve: Curves.easeIn,
      );
    }));
  }

  Future<DocumentReference> _createOrJoinGame() async {
    QuerySnapshot gamesQuery = await _firestore.collection('games').where('playerCount', isLessThan: 2).get();
    if (gamesQuery.docs.isNotEmpty) {
      DocumentReference gameRef = gamesQuery.docs.first.reference;
      gameRef.update({
        'playerCount': FieldValue.increment(1),
        'player2': playerName,
      });
      return gameRef;
    } else {
      DocumentReference newGameRef = await _firestore.collection('games').add({
        'player1': playerName,
        'player2': '',
        'playerCount': 1,
        'board': _flattenBoard(board),
        'isBlackTurn': true,
        'blackCaptures': 0,
        'whiteCaptures': 0,
        'gameEnded': false,
      });
      return newGameRef;
    }
  }


  void _connectToPlayer() async {
    _showTurnNotification('Looking for a player...');

    setState(() {
      isConnected = false;
    });

    await Future.delayed(const Duration(seconds: 3));

    DocumentReference gameRef = await _createOrJoinGame();
    print('Game Reference ID: ${gameRef.id}');

    gameRef.get().then((snapshot) {
      setState(() {
        playerCount = snapshot['playerCount'];
      });
    });

    setState(() {
      playerName = _generateRandomName();
      opponentName = _generateRandomName();
      gameId = gameRef.id;
      isConnected = true;
    });

    _showTurnNotification('Player connected!');

    gameRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          board = _reconstructBoard(List<String>.from(data['board']), boardSize);
          isBlackTurn = data['isBlackTurn'];
          blackCaptures = data['blackCaptures'];
          whiteCaptures = data['whiteCaptures'];
          gameEnded = data['gameEnded'];
          playerCount = data['playerCount'];
        });
        print('Board state updated');
      }
    });
  }


  void _updateGameState() {
    _firestore.collection('games').doc(gameId).update({
      'board': _flattenBoard(board),
      'isBlackTurn': isBlackTurn,
      'blackCaptures': blackCaptures,
      'whiteCaptures': whiteCaptures,
      'gameEnded': gameEnded,
    });
  }

  String _generateRandomName() {
    final random = Random();
    final randomDigits = random.nextInt(90000) + 10000;
    return 'Player$randomDigits';
  }

  void _showTurnNotification(String message) {
    final scaffoldMessenger = scaffoldMessengerKey.currentState;
    if (scaffoldMessenger != null) {
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleTap(int x, int y) {
    if (board[x][y] == '' && !gameEnded && !moveInProgress && isConnected) {
      setState(() {
        moveInProgress = true;
        board[x][y] = isBlackTurn ? 'B' : 'W';
        if (_isSuicideMove(x, y)) {
          _showTurnNotification("Suicide move. Try a different move.");
          board[x][y] = '';
          moveInProgress = false;
          return;
        }
        controllers[x][y].reset();
        controllers[x][y].forward();
        if (!isMuted) {
          _audioPlayer.setAsset('move_sound.mp3').then((_) => _audioPlayer.play());
        }
        _checkCaptures(x, y);
        isBlackTurn = !isBlackTurn;
        _updateGameState();
        if (_isBoardFull()) {
          _declareWinner();
        } else {
          moveInProgress = false;
          _showTurnNotification('Player\'s turn: ${isBlackTurn ? 'Black' : 'White'}');
        }
      });
    }
  }

  bool _isSuicideMove(int x, int y) {
    String currentPlayer = board[x][y];
    bool hasLiberties = _hasLiberties(x, y, currentPlayer, {});
    if (!hasLiberties) {
      board[x][y] = '';
    }
    return !hasLiberties;
  }

  bool _hasLiberties(int x, int y, String player, Set<String> visited) {
    if (x < 0 || x >= boardSize || y < 0 || y >= boardSize) return false;
    if (board[x][y] == '') return true;
    if (board[x][y] != player) return false;

    String currentPos = '$x,$y';
    if (visited.contains(currentPos)) return false;

    visited.add(currentPos);
    List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [0, -1],
      [-1, 0],
    ];

    for (List<int> direction in directions) {
      int newX = x + direction[0];
      int newY = y + direction[1];
      if (_hasLiberties(newX, newY, player, visited)) {
        return true;
      }
    }
    return false;
  }

  void _checkCaptures(int x, int y) {
    List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [0, -1],
      [-1, 0],
    ];
    String opponent = board[x][y] == 'B' ? 'W' : 'B';
    for (List<int> direction in directions) {
      int newX = x + direction[0];
      int newY = y + direction[1];
      if (newX >= 0 && newX < boardSize && newY >= 0 && newY < boardSize) {
        if (board[newX][newY] == opponent && _isCaptured(newX, newY, opponent)) {
          _captureStones(newX, newY, opponent);
        }
      }
    }
  }

  bool _isCaptured(int x, int y, String player) {
    Set<String> visited = {};
    List<List<int>> stack = [[x, y]];
    bool captured = true;

    while (stack.isNotEmpty) {
      List<int> current = stack.removeLast();
      int currentX = current[0];
      int currentY = current[1];

      if (currentX < 0 || currentX >= boardSize || currentY < 0 || currentY >= boardSize) continue;
      if (board[currentX][currentY] == '') return false;
      if (board[currentX][currentY] != player) continue;

      String currentPos = '$currentX,$currentY';
      if (visited.contains(currentPos)) continue;

      visited.add(currentPos);

      stack.add([currentX + 1, currentY]);
      stack.add([currentX - 1, currentY]);
      stack.add([currentX, currentY + 1]);
      stack.add([currentX, currentY - 1]);
    }

    return captured;
  }

  void _captureStones(int x, int y, String player) {
    Set<String> visited = {};
    List<List<int>> stack = [[x, y]];

    while (stack.isNotEmpty) {
      List<int> current = stack.removeLast();
      int currentX = current[0];
      int currentY = current[1];

      if (currentX < 0 || currentX >= boardSize || currentY < 0 || currentY >= boardSize) continue;
      if (board[currentX][currentY] != player) continue;

      String currentPos = '$currentX,$currentY';
      if (visited.contains(currentPos)) continue;

      board[currentX][currentY] = '';
      visited.add(currentPos);

      stack.add([currentX + 1, currentY]);
      stack.add([currentX - 1, currentY]);
      stack.add([currentX, currentY + 1]);
      stack.add([currentX, currentY - 1]);
    }

    if (player == 'B') {
      whiteCaptures += visited.length;
    } else {
      blackCaptures += visited.length;
    }
  }

  bool _isBoardFull() {
    for (var row in board) {
      for (var cell in row) {
        if (cell == '') {
          return false;
        }
      }
    }
    return true;
  }

  void _declareWinner() {
    int blackCount = 0;
    int whiteCount = 0;

    for (var row in board) {
      for (var cell in row) {
        if (cell == 'B') {
          blackCount++;
        } else if (cell == 'W') {
          whiteCount++;
        }
      }
    }

    blackCount += blackCaptures;
    whiteCount += whiteCaptures;

    String winner;
    if (blackCount > whiteCount) {
      winner = 'Black';
    } else if (whiteCount > blackCount) {
      winner = 'White';
    } else {
      winner = 'No one, it\'s a tie';
    }

    setState(() {
      gameEnded = true;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text('The winner is: $winner\nBlack: $blackCount\nWhite: $whiteCount'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _passTurn() {
    setState(() {
      if (playerPassed) {
        _declareWinner();
      } else {
        playerPassed = true;
        isBlackTurn = !isBlackTurn;
        _showTurnNotification('Player\'s turn: ${isBlackTurn ? 'Black' : 'White'}');
      }
    });
  }

  void _showEndGameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Game'),
          content: const Text('Are you sure you want to end the game and count territories?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _declareWinner();
              },
            ),
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBoard(double maxWidth) {
    double cellSize = (maxWidth - 30) / boardSize;
    bool highlightPassButton = _tutorialManager.isTutorialActive && _tutorialManager.currentStep.message.contains('pass your turn');

    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0.1),
        border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(boardSize, (x) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(boardSize, (y) {
                  return GestureDetector(
                    onTap: () => _handleTap(x, y),
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 0.2),
                      ),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: animations[x][y],
                          builder: (context, child) {
                            return board[x][y] == ''
                                ? const SizedBox.shrink()
                                : FadeTransition(
                                    opacity: animations[x][y],
                                    child: Container(
                                      width: cellSize - 10,
                                      height: cellSize - 10,
                                      decoration: BoxDecoration(
                                        color: board[x][y] == 'B' ? Colors.black : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.5),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                          },
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
          if (_tutorialManager.isTutorialActive)
            Positioned(
              left: _tutorialManager.currentStep.highlightPosition.dx,
              top: _tutorialManager.currentStep.highlightPosition.dy,
              child: Container(
                width: _tutorialManager.currentStep.highlightSize.width,
                height: _tutorialManager.currentStep.highlightSize.height,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurpleAccent, width: 2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  children: [
                    Text(
                      _tutorialManager.currentStep.message,
                      style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 16),
                    ),
                    ElevatedButton(
                      onPressed: _skipTutorial,
                      child: const Text('Skip'),
                    ),
                    if (!_tutorialManager.isLastStep)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _tutorialManager.nextStep();
                            if (_tutorialManager.currentStep.autoMove && _tutorialManager.currentStep.move != null) {
                              Future.delayed(const Duration(milliseconds: 500), () {
                                _autoMove(_tutorialManager.currentStep.move![0], _tutorialManager.currentStep.move![1]);
                              });
                            }
                          });
                        },
                        child: const Text('Next'),
                      ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 20,
            child: ElevatedButton(
              onPressed: _passTurn,
              style: highlightPassButton ? ElevatedButton.styleFrom(backgroundColor: Colors.yellow) : null,
              child: const Text('Pass Turn'),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: ElevatedButton(
              onPressed: _showEndGameDialog,
              child: const Text('End Game'),
            ),
          ),
        ],
      ),
    );
  }

  void _autoMove(int x, int y) {
    setState(() {
      if (_isSuicideMove(x, y)) {
        _showTurnNotification("Suicide move avoided.");
        return;
      }
      board[x][y] = isBlackTurn ? 'B' : 'W';
      controllers[x][y].reset();
      controllers[x][y].forward();
      if (!isMuted) {
        _audioPlayer.setAsset('move_sound.mp3').then((_) => _audioPlayer.play());
      }
      _checkCaptures(x, y);
      isBlackTurn = !isBlackTurn;
      moveInProgress = false;
      _updateGameState();
      _showTurnNotification('Player\'s turn: ${isBlackTurn ? 'Black' : 'White'}');
    });
  }

  void _resetGame() {
    setState(() {
      _initializeBoard();
      isBlackTurn = true;
      blackCaptures = 0;
      whiteCaptures = 0;
      gameEnded = false;
      playerPassed = false;
      moveInProgress = false;
    });
    _showTurnNotification('Multiplayer mode');
  }

  void _skipTutorial() {
    setState(() {
      _tutorialManager.endTutorial();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer Go(wéiqí)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
          IconButton(
            icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: () {
              setState(() {
                isMuted = !isMuted;
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth;
          return isConnected
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Turn: ${isBlackTurn ? 'Black' : 'White'}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Black Captures: $blackCaptures  |  White Captures: $whiteCaptures',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Player: $playerName  |  Opponent: $opponentName',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Players in the room: $playerCount',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      _buildBoard(maxWidth),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _passTurn,
                        child: const Text('Pass Turn'),
                      ),
                      ElevatedButton(
                        onPressed: _showEndGameDialog,
                        child: const Text('End Game'),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        'Waiting for players to join...',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Players in the room: $playerCount',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                );
        },
      ),
    );
  }
}

class GoGame extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const GoGame({required this.onThemeToggle, super.key});

  @override
  _GoGameState createState() => _GoGameState();
}

class _GoGameState extends State<GoGame> with TickerProviderStateMixin {
  int boardSize = 9;
  late List<List<String>> board;
  late List<List<AnimationController>> controllers;
  late List<List<Animation<double>>> animations;
  bool isBlackTurn = true;
  int blackCaptures = 0;
  int whiteCaptures = 0;
  bool gameEnded = false;
  bool playWithBot = false;
  String botDifficulty = 'Random Bot';
  String playerColor = 'B';
  final Random _random = Random();
  bool botPlaying = false;
  bool moveInProgress = false;
  List<List<List<String>>> previousStates = [];
  bool playerPassed = false;
  bool isMuted = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  late TutorialManager _tutorialManager;

  @override
  void initState() {
    super.initState();
    
    _initializeBoard();
    _tutorialManager = TutorialManager(tutorialSteps);

    
    if (!isMuted) {
      _audioPlayer.setAsset('move_sound.mp3').then((_) => _audioPlayer.play());
    }

    // Check if the player is white and trigger the bot's move if necessary
    if (playWithBot && playerColor == 'W') {
      Future.delayed(const Duration(milliseconds: 500), () {
        _makeBotMove();
      });
    }
  }

  @override
  void dispose() {
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeBoard() {
    board = List.generate(boardSize, (_) => List.filled(boardSize, ''));
    controllers = List.generate(boardSize, (x) => List.generate(boardSize, (y) {
      return AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
    }));
    animations = List.generate(boardSize, (x) => List.generate(boardSize, (y) {
      return CurvedAnimation(
        parent: controllers[x][y],
        curve: Curves.easeIn,
      );
    }));
  }

  void _showTurnNotification(String message) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _handleTap(int x, int y) {
    if (botPlaying || board[x][y] != '' || gameEnded || moveInProgress) {
      return;
    }

    if (_tutorialManager.isTutorialActive && _tutorialManager.currentStep.autoMove) {
      _showTurnNotification('Follow the tutorial instructions');
      return;
    }

    if (_isKo(x, y)) {
      _showTurnNotification("Ko rule violation. Try a different move.");
      return;
    }

    setState(() {
      moveInProgress = true;
      board[x][y] = isBlackTurn ? 'B' : 'W';
      if (_isSuicideMove(x, y)) {
        _showTurnNotification("Suicide move. Try a different move.");
        board[x][y] = '';
        moveInProgress = false;
        return;
      }
      controllers[x][y].reset();
      controllers[x][y].forward();
      if (!isMuted) {
        _audioPlayer.setAsset('move_sound.mp3').then((_) => _audioPlayer.play());
      }
      _checkCaptures(x, y);
      isBlackTurn = !isBlackTurn;
      if (_isBoardFull()) {
        _declareWinner();
      } else if (playWithBot && isBlackTurn != (playerColor == 'B')) {
        _makeBotMove();
      } else {
        moveInProgress = false;
        _showTurnNotification('Player\'s turn: ${isBlackTurn ? 'Black' : 'White'}');
      }

      if (_tutorialManager.isTutorialActive) {
        if (_tutorialManager.isLastStep) {
          _tutorialManager.endTutorial();
        } else {
          _tutorialManager.nextStep();
          if (_tutorialManager.currentStep.autoMove && _tutorialManager.currentStep.move != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _autoMove(_tutorialManager.currentStep.move![0], _tutorialManager.currentStep.move![1]);
            });
          }
        }
      }
    });
  }

  void _autoMove(int x, int y) {
    setState(() {
      if (_isSuicideMove(x, y)) {
        _showTurnNotification("Suicide move avoided.");
        return;
      }
      board[x][y] = isBlackTurn ? 'B' : 'W';
      controllers[x][y].reset();
      controllers[x][y].forward();
      if (!isMuted) {
        _audioPlayer.setAsset('move_sound.mp3').then((_) => _audioPlayer.play());
      }
      _checkCaptures(x, y);
      isBlackTurn = !isBlackTurn;
      moveInProgress = false;
      _showTurnNotification('Player\'s turn: ${isBlackTurn ? 'Black' : 'White'}');
    });
  }

  bool _isKo(int x, int y) {
    if (previousStates.isEmpty) return false;
    List<List<String>> currentBoard = _cloneBoard(board);
    currentBoard[x][y] = board[x][y];
    for (var state in previousStates) {
      if (_areBoardsEqual(state, currentBoard)) {
        return true;
      }
    }
    return false;
  }

  bool _isSuicideMove(int x, int y) {
    String currentPlayer = board[x][y];
    bool hasLiberties = _hasLiberties(x, y, currentPlayer, {});
    if (!hasLiberties) {
      board[x][y] = '';
    }
    return !hasLiberties;
  }

  bool _hasLiberties(int x, int y, String player, Set<String> visited) {
    if (x < 0 || x >= boardSize || y < 0 || y >= boardSize) return false;
    if (board[x][y] == '') return true;
    if (board[x][y] != player) return false;

    String currentPos = '$x,$y';
    if (visited.contains(currentPos)) return false;

    visited.add(currentPos);
    List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [0, -1],
      [-1, 0],
    ];

    for (List<int> direction in directions) {
      int newX = x + direction[0];
      int newY = y + direction[1];
      if (_hasLiberties(newX, newY, player, visited)) {
        return true;
      }
    }
    return false;
  }

  List<List<String>> _cloneBoard(List<List<String>> originalBoard) {
    return originalBoard.map((row) => List<String>.from(row)).toList();
  }

  bool _areBoardsEqual(List<List<String>> board1, List<List<String>> board2) {
    for (int i = 0; i < boardSize; i++) {
      for (int j = 0; j < boardSize; j++) {
        if (board1[i][j] != board2[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  // Random move generator
  List<int> _getRandomMove() {
    List<List<int>> emptyCells = [];

    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; x < boardSize; y++) {
        if (board[x][y] == '') {
          emptyCells.add([x, y]);
        }
      }
    }

    if (emptyCells.isEmpty) {
      return [];
    }

    return emptyCells[Random().nextInt(emptyCells.length)];
  }

  // Skillful move generator
  List<int> _getSkillfulMove() {
    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          if (_canCaptureOpponent(x, y)) {
            return [x, y];
          }
        }
      }
    }

    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          if (_canDefendOwnStone(x, y)) {
            return [x, y];
          }
        }
      }
    }

    List<List<int>> strategicMoves = _getStrategicMoves();
    if (strategicMoves.isNotEmpty) {
      return strategicMoves[Random().nextInt(strategicMoves.length)];
    }

    return _getRandomMove();
  }

  // Advanced skillful move generator
  List<int> _getAdvancedSkillfulMove() {
    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          if (_canCaptureOpponent(x, y)) {
            return [x, y];
          }
        }
      }
    }

    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          if (_canDefendOwnStone(x, y)) {
            return [x, y];
          }
        }
      }
    }

    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          if (_createsTwoEyes(x, y)) {
            return [x, y];
          }
        }
      }
    }

    List<List<int>> territoryMoves = _evaluateTerritoryMoves();
    if (territoryMoves.isNotEmpty) {
      return territoryMoves[Random().nextInt(territoryMoves.length)];
    }

    return _getSkillfulMove();
  }

  // Minimax move generator
  List<int> _getMinimaxMove() {
    int bestValue = -100000;
    List<int> bestMove = [];

    List<List<int>> moves = _generateMoves();
    String player = isBlackTurn ? 'B' : 'W';

    for (List<int> move in moves) {
      int x = move[0];
      int y = move[1];
      board[x][y] = player;
      int moveValue = _minimax(player, 3, -100000, 100000, false);
      board[x][y] = '';
      if (moveValue > bestValue) {
        bestValue = moveValue;
        bestMove = move;
      }
    }

    return bestMove;
  }

  void _makeBotMove() {
    if (botPlaying || gameEnded || !playWithBot || isBlackTurn == (playerColor == 'B')) return;

    setState(() {
      botPlaying = true;
    });

    _showTurnNotification('Bot is thinking...');
    Future.delayed(const Duration(milliseconds: 500), () {
      if (gameEnded) return;

      List<int>? move;
      if (botDifficulty == 'Random Bot') {
        move = _getRandomMove();
      } else if (botDifficulty == 'Strategic Bot') {
        move = _getSkillfulMove();
      } else if (botDifficulty == 'Advanced Strategic Bot') {
        move = _getAdvancedSkillfulMove();
      } else if (botDifficulty == 'Minimax Bot') {
        move = _getMinimaxMove();
      } else if (botDifficulty == 'MCTS Bot') {
        var mctsBot = MCTSBot();
        move = mctsBot.getBestMove(board, isBlackTurn ? 'B' : 'W');
      }

      if (move != null && !_isSuicideMove(move[0], move[1])) {
        _placeStone(move[0], move[1]);
      } else {
        _showTurnNotification("Bot avoided a suicide move.");
      }

      setState(() {
        botPlaying = false;
        moveInProgress = false;
        if (!isMuted) {
          _audioPlayer.setAsset('move_sound.mp3').then((_) => _audioPlayer.play());
        }
        _showTurnNotification('Player\'s turn: ${isBlackTurn ? 'Black' : 'White'}');
      });
    });
  }

  void _makeRandomMove() {
    List<List<int>> emptyCells = [];

    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          emptyCells.add([x, y]);
        }
      }
    }

    if (emptyCells.isEmpty) {
      return;
    }

    List<int> chosenCell = emptyCells[_random.nextInt(emptyCells.length)];
    int x = chosenCell[0];
    int y = chosenCell[1];

    setState(() {
      board[x][y] = isBlackTurn ? 'B' : 'W';
      isBlackTurn = !isBlackTurn;
      controllers[x][y].reset();
      controllers[x][y].forward();
      _checkCaptures(x, y);
      if (_isBoardFull()) {
        _declareWinner();
      }
    });
  }

  void _makeSkillfulMove() {
    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          if (_canCaptureOpponent(x, y)) {
            _placeStone(x, y);
            return;
          }
        }
      }
    }

    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          if (_canDefendOwnStone(x, y)) {
            _placeStone(x, y);
            return;
          }
        }
      }
    }

    List<List<int>> strategicMoves = _getStrategicMoves();
    if (strategicMoves.isNotEmpty) {
      List<int> chosenMove = strategicMoves[_random.nextInt(strategicMoves.length)];
      _placeStone(chosenMove[0], chosenMove[1]);
      return;
    }

    _makeRandomMove();
  }

  bool _canCaptureOpponent(int x, int y) {
    String opponent = isBlackTurn ? 'W' : 'B';
    List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [0, -1],
      [-1, 0],
    ];

    for (List<int> direction in directions) {
      int newX = x + direction[0];
      int newY = y + direction[1];
      if (newX >= 0 && newX < boardSize && newY >= 0 && newY < boardSize) {
        if (board[newX][newY] == opponent && _isCaptured(newX, newY, opponent)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _canDefendOwnStone(int x, int y) {
    String player = isBlackTurn ? 'B' : 'W';
    List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [0, -1],
      [-1, 0],
    ];

    for (List<int> direction in directions) {
      int newX = x + direction[0];
      int newY = y + direction[1];
      if (newX >= 0 && newX < boardSize && newY >= 0 && newY < boardSize) {
        if (board[newX][newY] == player && _isCaptured(newX, newY, player)) {
          return true;
        }
      }
    }
    return false;
  }

  List<List<int>> _getStrategicMoves() {
    List<List<int>> moves = [];
    List<List<int>> positions = [
      [0, 0], [0, boardSize - 1], [boardSize - 1, 0], [boardSize - 1, boardSize - 1],
      [0, boardSize ~/ 2], [boardSize - 1, boardSize ~/ 2], [boardSize ~/ 2, 0], [boardSize ~/ 2, boardSize - 1]
    ];

    for (List<int> pos in positions) {
      if (board[pos[0]][pos[1]] == '') {
        moves.add(pos);
      }
    }
    return moves;
  }

  void _makeAdvancedSkillfulMove() {
    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          if (_canCaptureOpponent(x, y)) {
            _placeStone(x, y);
            return;
          }
        }
      }
    }

    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          if (_canDefendOwnStone(x, y)) {
            _placeStone(x, y);
            return;
          }
        }
      }
    }

    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          if (_createsTwoEyes(x, y)) {
            _placeStone(x, y);
            return;
          }
        }
      }
    }

    List<List<int>> territoryMoves = _evaluateTerritoryMoves();
    if (territoryMoves.isNotEmpty) {
      List<int> chosenMove = territoryMoves[_random.nextInt(territoryMoves.length)];
      _placeStone(chosenMove[0], chosenMove[1]);
      return;
    }

    _makeSkillfulMove();
  }

  bool _createsTwoEyes(int x, int y) {
    String player = isBlackTurn ? 'B' : 'W';
    List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [0, -1],
      [-1, 0],
    ];
    int eyes = 0;

    for (List<int> direction in directions) {
      int newX = x + direction[0];
      int newY = y + direction[1];
      if (newX >= 0 && newX < boardSize && newY >= 0 && newY < boardSize) {
        if (board[newX][newY] == player) {
          eyes++;
        }
      }
    }
    return eyes >= 2;
  }

  List<List<int>> _evaluateTerritoryMoves() {
    List<List<int>> moves = [];
    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '' && _maximizesTerritory(x, y)) {
          moves.add([x, y]);
        }
      }
    }
    return moves;
  }

  bool _maximizesTerritory(int x, int y) {
    String player = isBlackTurn ? 'B' : 'W';
    List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [0, -1],
      [-1, 0],
    ];
    int friendlyStones = 0;
    int emptySpaces = 0;

    for (List<int> direction in directions) {
      int newX = x + direction[0];
      int newY = y + direction[1];
      if (newX >= 0 && newX < boardSize && newY >= 0 && newY < boardSize) {
        if (board[newX][newY] == player) {
          friendlyStones++;
        } else if (board[newX][newY] == '') {
          emptySpaces++;
        }
      }
    }
    return friendlyStones > 1 && emptySpaces > 1;
  }

  void _makeMinimaxMove() {
    int bestValue = -100000;
    List<int> bestMove = [];

    List<List<int>> moves = _generateMoves();
    String player = isBlackTurn ? 'B' : 'W';

    for (List<int> move in moves) {
      int x = move[0];
      int y = move[1];
      board[x][y] = player;
      int moveValue = _minimax(player, 3, -100000, 100000, false);
      board[x][y] = '';
      if (moveValue > bestValue) {
        bestValue = moveValue;
        bestMove = move;
      }
    }

    if (bestMove.isNotEmpty) {
      _placeStone(bestMove[0], bestMove[1]);
    } else {
      _makeSkillfulMove();
    }
  }

  void _placeStone(int x, int y) {
    setState(() {
      board[x][y] = isBlackTurn ? 'B' : 'W';
      controllers[x][y].reset();
      controllers[x][y].forward();
      if (!isMuted) {
        _audioPlayer.setAsset('move_sound.mp3').then((_) => _audioPlayer.play());
      }
      _checkCaptures(x, y);
      isBlackTurn = !isBlackTurn;
      if (_isBoardFull()) {
        _declareWinner();
      } else {
        _showTurnNotification('Player\'s turn: ${isBlackTurn ? 'Black' : 'White'}');
      }
    });
  }

  void _checkCaptures(int x, int y) {
    List<List<int>> directions = [
      [0, 1],
      [1, 0],
      [0, -1],
      [-1, 0],
    ];
    String opponent = board[x][y] == 'B' ? 'W' : 'B';
    for (List<int> direction in directions) {
      int newX = x + direction[0];
      int newY = y + direction[1];
      if (newX >= 0 && newX < boardSize && newY >= 0 && newY < boardSize) {
        if (board[newX][newY] == opponent && _isCaptured(newX, newY, opponent)) {
          _captureStones(newX, newY, opponent);
        }
      }
    }
  }

  int _minimax(String player, int depth, int alpha, int beta, bool isMaximizing) {
    if (depth == 0 || _isBoardFull()) {
      return _evaluateBoard(player);
    }

    String opponent = (player == 'B') ? 'W' : 'B';
    List<List<int>> moves = _generateMoves();

    if (isMaximizing) {
      int maxEval = -100000;
      for (List<int> move in moves) {
        int x = move[0];
        int y = move[1];
        board[x][y] = player;
        int eval = _minimax(opponent, depth - 1, alpha, beta, false);
        board[x][y] = '';
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) {
          break;
        }
      }
      return maxEval;
    } else {
      int minEval = 100000;
      for (List<int> move in moves) {
        int x = move[0];
        int y = move[1];
        board[x][y] = player;
        int eval = _minimax(opponent, depth - 1, alpha, beta, true);
        board[x][y] = '';
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) {
          break;
        }
      }
      return minEval;
    }
  }

  int _evaluateBoard(String player) {
    int score = 0;
    String opponent = (player == 'B') ? 'W' : 'B';

    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == player) {
          score += 10;

          if (_canCaptureOpponent(x, y)) {
            score += 30;
          }

          if (x > 0 && x < boardSize - 1 && y > 0 && y < boardSize - 1) {
            score += 5;
          }
        } else if (board[x][y] == opponent) {
          score -= 10;

          if (_canDefendOwnStone(x, y)) {
            score -= 30;
          }
        }
      }
    }
    return score;
  }

  List<List<int>> _generateMoves() {
    List<List<int>> moves = [];
    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == '') {
          moves.add([x, y]);
        }
      }
    }
    return moves;
  }

  bool _isCaptured(int x, int y, String player) {
    Set<String> visited = {};
    List<List<int>> stack = [[x, y]];
    bool captured = true;

    while (stack.isNotEmpty) {
      List<int> current = stack.removeLast();
      int currentX = current[0];
      int currentY = current[1];

      if (currentX < 0 || currentX >= boardSize || currentY < 0 || currentY >= boardSize) continue;
      if (board[currentX][currentY] == '') return false;
      if (board[currentX][currentY] != player) continue;

      String currentPos = '$currentX,$currentY';
      if (visited.contains(currentPos)) continue;

      visited.add(currentPos);

      stack.add([currentX + 1, currentY]);
      stack.add([currentX - 1, currentY]);
      stack.add([currentX, currentY + 1]);
      stack.add([currentX, currentY - 1]);
    }

    return captured;
  }

  void _captureStones(int x, int y, String player) {
    Set<String> visited = {};
    List<List<int>> stack = [[x, y]];

    while (stack.isNotEmpty) {
      List<int> current = stack.removeLast();
      int currentX = current[0];
      int currentY = current[1];

      if (currentX < 0 || currentX >= boardSize || currentY < 0 || currentY >= boardSize) continue;
      if (board[currentX][currentY] != player) continue;

      String currentPos = '$currentX,$currentY';
      if (visited.contains(currentPos)) continue;

      board[currentX][currentY] = '';
      visited.add(currentPos);

      stack.add([currentX + 1, currentY]);
      stack.add([currentX - 1, currentY]);
      stack.add([currentX, currentY + 1]);
      stack.add([currentX, currentY - 1]);
    }

    if (player == 'B') {
      whiteCaptures += visited.length;
    } else {
      blackCaptures += visited.length;
    }
  }

  bool _isBoardFull() {
    for (var row in board) {
      for (var cell in row) {
        if (cell == '') {
          return false;
        }
      }
    }
    return true;
  }

  int _scoreTerritory(String player) {
    int score = 0;
    Set<String> visited = {};

    for (int x = 0; x < boardSize; x++) {
      for (int y = 0; y < boardSize; y++) {
        if (board[x][y] == player) {
          score++;
        } else if (board[x][y] == '' && _isTerritory(x, y, player, visited)) {
          score++;
        }
      }
    }
    return score;
  }

  bool _isTerritory(int x, int y, String player, Set<String> visited) {
    if (x < 0 || x >= boardSize || y < 0 || y >= boardSize || visited.contains('$x,$y')) return false;
    visited.add('$x,$y');

    if (board[x][y] == player) return true;
    if (board[x][y] != '') return false;

    bool surrounded = true;
    List<List<int>> directions = [
      [0, 1], [1, 0], [0, -1], [-1, 0]
    ];

    for (var dir in directions) {
      surrounded = surrounded && _isTerritory(x + dir[0], y + dir[1], player, visited);
    }
    return surrounded;
  }

  void _declareWinner() {
    int blackScore = _scoreTerritory('B') + blackCaptures;
    int whiteScore = (_scoreTerritory('W') + whiteCaptures + 6.5).toInt();

    String winner;
    if (blackScore > whiteScore) {
      winner = 'Black';
    } else if (whiteScore > blackScore) {
      winner = 'White';
    } else {
      winner = 'No one, it\'s a tie';
    }

    setState(() {
      gameEnded = true;
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text('The winner is: $winner\nBlack: $blackScore\nWhite: $whiteScore'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _passTurn() {
    setState(() {
      if (playerPassed) {
        _declareWinner();
      } else {
        playerPassed = true;
        isBlackTurn = !isBlackTurn;
        if (playWithBot && isBlackTurn != (playerColor == 'B')) {
          _showTurnNotification('Bot\'s turn');
          _makeBotMove();
        } else {
          _showTurnNotification('Player\'s turn: ${isBlackTurn ? 'Black' : 'White'}');
        }
      }
    });
  }

  void _showEndGameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Game'),
          content: const Text('Are you sure you want to end the game and count territories?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _declareWinner();
              },
            ),
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBoard(double maxWidth) {
    double cellSize = (maxWidth - 30) / boardSize;

    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0.1),
        border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(boardSize, (x) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(boardSize, (y) {
                  return GestureDetector(
                    onTap: () => _handleTap(x, y),
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 0.2),
                      ),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: animations[x][y],
                          builder: (context, child) {
                            return board[x][y] == ''
                                ? const SizedBox.shrink()
                                : FadeTransition(
                                    opacity: animations[x][y],
                                    child: Container(
                                      width: cellSize - 10,
                                      height: cellSize - 10,
                                      decoration: BoxDecoration(
                                        color: board[x][y] == 'B' ? Colors.black : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.5),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                          },
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
          if (_tutorialManager.isTutorialActive)
            Positioned(
              left: _tutorialManager.currentStep.highlightPosition.dx,
              top: _tutorialManager.currentStep.highlightPosition.dy,
              child: Container(
                width: _tutorialManager.currentStep.highlightSize.width,
                height: _tutorialManager.currentStep.highlightSize.height,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurpleAccent, width: 2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  children: [
                    Text(
                      _tutorialManager.currentStep.message,
                      style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 16),
                    ),
                    ElevatedButton(
                      onPressed: _skipTutorial,
                      child: const Text('Skip'),
                    ),
                    if (!_tutorialManager.isLastStep)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _tutorialManager.nextStep();
                            if (_tutorialManager.currentStep.autoMove && _tutorialManager.currentStep.move != null) {
                              Future.delayed(const Duration(milliseconds: 500), () {
                                _autoMove(_tutorialManager.currentStep.move![0], _tutorialManager.currentStep.move![1]);
                              });
                            }
                          });
                        },
                        child: const Text('Next'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _initializeBoard();
      isBlackTurn = true;
      blackCaptures = 0;
      whiteCaptures = 0;
      gameEnded = false;
      playerPassed = false;
      moveInProgress = false;
      previousStates.clear();
    });
    _showTurnNotification('New Game');

    // Check if the player is white and trigger the bot's move if necessary
    if (playWithBot && playerColor == 'W') {
      Future.delayed(const Duration(milliseconds: 500), () {
        _makeBotMove();
      });
    }
  }

  void _skipTutorial() {
    setState(() {
      _tutorialManager.endTutorial();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go(wéiqí)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
          IconButton(
            icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: () {
              setState(() {
                isMuted = !isMuted;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onThemeToggle,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
              ),
              child: Text(
                'Go(wéiqí) Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(),
            ListTile(
              leading: const Icon(Icons.computer),
              title: const Text('New Game vs Bot'),
              onTap: () {
                setState(() {
                  playWithBot = true;
                  botDifficulty = 'Random Bot';
                });
                _resetGame();
                Navigator.pop(context);
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.extension),
              title: const Text('Bot Difficulty'),
              children: [
                ListTile(
                  title: const Text('Random Bot'),
                  onTap: () {
                    setState(() {
                      botDifficulty = 'Random Bot';
                      playWithBot = true;
                    });
                    _resetGame();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Strategic Bot'),
                  onTap: () {
                    setState(() {
                      botDifficulty = 'Strategic Bot';
                      playWithBot = true;
                    });
                    _resetGame();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Advanced Strategic Bot'),
                  onTap: () {
                    setState(() {
                      botDifficulty = 'Advanced Strategic Bot';
                      playWithBot = true;
                    });
                    _resetGame();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Minimax Bot'),
                  onTap: () {
                    setState(() {
                      botDifficulty = 'Minimax Bot';
                      playWithBot = true;
                    });
                    _resetGame();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('MCTS Bot'),
                  onTap: () {
                    setState(() {
                      botDifficulty = 'MCTS Bot';
                      playWithBot = true;
                    });
                    _resetGame();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Divider(),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('New Multiplayer Game'),
              onTap: () {
                setState(() {
                  playWithBot = false;
                });
                Navigator.pop(context); // Close the drawer
                Navigator.pushNamed(context, '/multiplayer'); // Navigate to the multiplayer screen
              },
            ),

            ExpansionTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Player Color'),
              children: [
                ListTile(
                  title: const Text('Black'),
                  onTap: () {
                    setState(() {
                      playerColor = 'B';
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('White'),
                  onTap: () {
                    setState(() {
                      playerColor = 'W';
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Divider(),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Tutorial'),
              onTap: () {
                _resetGame();
                setState(() {
                  _tutorialManager = TutorialManager(tutorialSteps);
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth;
          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Turn: ${isBlackTurn ? 'Black' : 'White'}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Black Captures: $blackCaptures  |  White Captures: $whiteCaptures',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                _buildBoard(maxWidth),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _passTurn,
                  child: const Text('Pass Turn'),
                ),
                ElevatedButton(
                  onPressed: _showEndGameDialog,
                  child: const Text('End Game'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DarkModeApp extends StatefulWidget {
  const DarkModeApp({super.key});

  @override
  _DarkModeAppState createState() => _DarkModeAppState();
}

class _DarkModeAppState extends State<DarkModeApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go(wéiqí)',
      routes: {
        '/multiplayer': (context) => const MultiplayerGame(),
      },
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: GoGame(onThemeToggle: _toggleTheme),
    );
  }
}

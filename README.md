# Go Multiplayer Game

## Overview

This project is a multiplayer implementation of the traditional board game Go (wéiqí) built with Flutter. The game includes single-player mode with various difficulty levels, a tutorial, and multiplayer mode utilizing Firebase Firestore for real-time data synchronization.

## Features

- **Multiplayer Mode**: Play against other players online in real-time.
- **Single-player Mode**: Challenge different levels of AI opponents.
- **Tutorial**: An interactive tutorial to learn the basics of Go.
- **Dark Mode**: Toggle between light and dark themes.
- **Sound Effects**: Optional sound effects for in-game actions.

## Getting Started

### Prerequisites

- Flutter SDK: [Installation Guide](https://flutter.dev/docs/get-started/install)
- Firebase Account: [Sign Up](https://firebase.google.com/)
- Dart: Included with Flutter

### Firebase Setup

1. **Create a Firebase Project**
   - Go to the [Firebase Console](https://console.firebase.google.com/).
   - Click on "Add project" and follow the steps to create a new project.

2. **Add an Android/iOS App to the Project**
   - Register your app with Firebase by adding your app's package name.
   - Download the `google-services.json` (for Android) or `GoogleService-Info.plist` (for iOS) and place it in the appropriate directory in your Flutter project.

3. **Enable Firestore**
   - In the Firebase Console, navigate to Firestore Database and click "Create database".
   - Choose a location and set security rules. For development, you can use the following rules (not recommended for production):
     ```javascript
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /{document=**} {
           allow read, write: if true;
         }
       }
     }
     ```

### Project Setup

1. **Clone the Repository**

   ```bash
   git clone https://github.com/your-repo/Go-w-iq---production.git
   cd go-multiplayer-game
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the App**

   ```bash
   flutter run
   ```

### Firebase Configuration

Ensure your Firebase configuration is correctly set up in `lib/firebase_options.dart` as generated by the FlutterFire CLI.

## Code Structure

- `lib/`: Contains the main source code for the game.
  - `main.dart`: Entry point of the application.
  - `firebase_options.dart`: Firebase configuration file.
  - `multiplayer_game.dart`: Implements multiplayer functionality.
  - `tutorial_manager.dart`: Handles the game tutorial.
  - `mcts_bot.dart`: Implements Monte Carlo Tree Search (MCTS) bot for AI.

## Gameplay

### Multiplayer Mode

- Players are matched with an available opponent or placed in a waiting room until another player joins.
- The game state is synchronized in real-time using Firestore.

### Single-player Mode

- Players can choose to play against various AI difficulties:
  - Random Bot
  - Strategic Bot
  - Advanced Strategic Bot
  - Minimax Bot
  - MCTS Bot

### Tutorial

- An interactive guide teaches players the rules and strategies of Go.

## Contributing

Contributions are welcome! Please follow the standard GitHub workflow:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -m 'Add your feature'`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Create a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For any questions or issues, please reach out to [Subhan Solehria](mailto:subhansolehria@live.com).

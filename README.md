# Twitch Hangman

A hangman game for Twitch streamers. Your viewers guess letters and words in chat to play along.

> **Note:** This README was generated with AI. The game itself was not — it was designed, coded, and shipped by hand.

[Gameplay Video](https://www.youtube.com/watch?v=IyTr7-XQBfY)

## Features

- Twitch chat integration - viewers guess by typing in chat
- 5 rounds per game with scoring
- Leaderboard showing top players
- Visual hangman progression

## Requirements

- Godot 4.1+
- A Twitch account
- A registered Twitch application (for OAuth)

## Setup

### 1. Create a Twitch Application

1. Go to the [Twitch Developer Console](https://dev.twitch.tv/console/apps)
2. Click "Register Your Application"
3. Fill in:
   - **Name**: Whatever you want (e.g., "My Hangman Game")
   - **OAuth Redirect URLs**: Add your redirect URL (see below)
   - **Category**: Game Integration
4. Click "Create"
5. Copy your **Client ID**

### 2. Configure the Game

1. Copy `Scenes/Util/twitch_config.gd.example` to `Scenes/Util/twitch_config.gd`
2. Edit `twitch_config.gd` and fill in your Client ID and redirect URL:

```gdscript
const CLIENT_ID := "your_client_id_here"
const REDIRECT_URL := "http://localhost:3000/auth"
```

### 3. OAuth Redirect

The OAuth flow requires a redirect URL that can capture the access token. Options:

- **Self-hosted**: Set up a simple web page on your domain that displays the token from the URL fragment
- **Localhost**: Use a local server during development
- **Manual**: The game has a field to paste the token manually if your redirect page shows it

### 4. Run the Game

1. Open the project in Godot
2. Run the game (F5)
3. Click "Login with Twitch" and authorize
4. Enter your channel name
5. Click "Start" to begin

## How to Play

- Viewers type single letters or full word guesses in chat
- Correct letters: +20 points
- Wrong guesses: -5 points
- Solving the word: bonus points based on remaining letters
- Top 3 players shown at the end of each game

## License

MIT

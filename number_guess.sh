#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Ask for username
echo "Enter your username:"
read USERNAME

# Check if user exists
USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_DATA ]]; then
  # New user - insert with 0 games played and null best game
  $PSQL "INSERT INTO users(username, games_played) VALUES('$USERNAME', 0)" > /dev/null
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # Existing user - split the data
  IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start guessing
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

while true; do
  read GUESS

  # Check if guess is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  NUMBER_OF_GUESSES=$(( NUMBER_OF_GUESSES + 1 ))

  if [[ $GUESS -eq $SECRET_NUMBER ]]; then
    # Correct guess
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Get current user data for update
    CURRENT_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")
    IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$CURRENT_DATA"

    NEW_GAMES=$(( GAMES_PLAYED + 1 ))

    # Update best game if it is null or current guesses is less than best game
    if [[ -z $BEST_GAME ]] || [[ $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
      $PSQL "UPDATE users SET games_played=$NEW_GAMES, best_game=$NUMBER_OF_GUESSES WHERE username='$USERNAME'" > /dev/null
    else
      $PSQL "UPDATE users SET games_played=$NEW_GAMES WHERE username='$USERNAME'" > /dev/null
    fi

    break

  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done
# Second commit - add database setup note
#!/bin/bash

PSQL="psql --username=freecodecamp dbname=number_guess --no-align -t -c"

function LETS_PLAY {
    echo Enter your username:
    read NAME

    CURRENT_GAME_SCORE=0
    USER_EXISTS=$($PSQL "SELECT user_id FROM users WHERE user_name = '$NAME'")
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_name = '$NAME'")
    BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE user_name = '$NAME'")

    if [[ -z $USER_EXISTS ]]
    then
        INSERT_NEW_USER=$($PSQL "INSERT INTO users (user_name, games_played) VALUES ('$NAME', 1)")
        USER_EXISTS=$($PSQL "SELECT user_id FROM users WHERE user_name = '$NAME'")
        echo Welcome, $NAME! It looks like this is your first time here.
    else
        UPDATE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_name = '$NAME'")
        echo Welcome back, $NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses.
    fi
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_name = '$NAME'")

    RANDOM_NUMBER=$(( RANDOM % 999 ))
    CURRENT_GAME_SCORE=0

    echo -e "\nGuess the secret number between 1 and 1000:"
    read NUMBER

    while [[ ! $NUMBER =~ ^[0-9]+$ ]]
    do
        echo -e "\nThat is not an integer, guess again:"
        read NUMBER
    done
    
    while [[ $NUMBER != $RANDOM_NUMBER ]]
    do
        if [[ $NUMBER -gt $RANDOM_NUMBER ]]
        then
            echo -e "\nIt's lower than that, guess again:"
        else
            echo -e "\nIt's higher than that, guess again:"
        fi
        (( CURRENT_GAME_SCORE += 1 ))
        read NUMBER
    done
    
    (( CURRENT_GAME_SCORE += 1 ))

    if [[ $GAMES_PLAYED -eq 1 ]]
    then
        UPDATE_BEST_GAME=$($PSQL "UPDATE users SET best_game = $CURRENT_GAME_SCORE WHERE user_id = $USER_EXISTS")
    fi
    
    if [[ $CURRENT_GAME_SCORE -lt $BEST_GAME ]]
    then
        UPDATE_BEST_GAME=$($PSQL "UPDATE users SET best_game = $CURRENT_GAME_SCORE WHERE user_id = $USER_EXISTS")
    fi  

    echo -e "\nYou guessed it in $CURRENT_GAME_SCORE tries. The secret number was $RANDOM_NUMBER. Nice job!"
}

LETS_PLAY
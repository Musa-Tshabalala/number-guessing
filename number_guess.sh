#!/bin/bash


PSQL="psql --username=freecodecamp dbname=number_guess --no-align -t -c"

function LETS_PLAY {
    echo Enter your username:
    read NAME

    USER_EXISTS=$($PSQL "SELECT user_name FROM users WHERE user_name = '$NAME'")

    if [[ -z $USER_EXISTS ]]
    then
        INSERT_NEW_USER=$($PSQL "INSERT INTO users (user_name) VALUES ('$NAME')")
        USER_EXISTS=$($PSQL "SELECT user_name FROM users WHERE user_name = '$NAME'")
        echo Welcome, $NAME! It looks like this is your first time here.
    else
        echo Welcome back, $NAME! You have played <games_played> games, and your best game took <best_game> guesses.
    fi
}

LETS_PLAY
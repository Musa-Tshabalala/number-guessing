#!/bin/bash

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

clear

PSQL="psql -U $DB_USER -d $DB_NAME --no-align -t -c"

echo "Enter Your Username:"
read NAME
NAME=$(echo $NAME | xargs)
echo

USER_EXISTS=$($PSQL "SELECT user_name FROM users WHERE user_name = '$NAME'")

clear
sleep 1

if [[ -z $USER_EXISTS ]]
then
    echo It looks like this is Your first time here, please enter ID number and create a password.
    echo
    echo Enter Id Number:
    read ID_NUMBER

    until [[ $ID_NUMBER =~ ^([0-9]){13}$ ]]
    do
        clear
        sleep 1
        echo Invalid ID number!, try again:
        read ID_NUMBER
    done

    clear
    sleep 1

    echo Enter New Password:
    read -s PASSWORD
    echo -e "\nConfirm Password:"
    read -s CONFIRM_PASSWORD

    while [[ $PASSWORD != $CONFIRM_PASSWORD ]]
    do
        clear
        sleep 1
        echo Oops! The password does not match try again.
        echo
        echo Enter New Password
        read -s PASSWORD
        echo -e "\nConfirm Password"
        read -s CONFIRM_PASSWORD
    done 
else
    VALID_PASSWORD=$($PSQL "SELECT password FROM users WHERE user_name = '$NAME'")
    sleep 1
    echo Enter Your Password:
    read -s PASSWORD

    until [[ $PASSWORD == $VALID_PASSWORD ]]
    do
        clear
        sleep 1
        echo -e "Your password is Incorrect, try again:"
        read -s PASSWORD
    done
fi

echo

function MENU {
    clear
    sleep 1
    if [[ $1 ]]
    then
        echo $1
    else
        echo Account: $NAME
    fi

    ADMIN=$($PSQL "SELECT admin FROM users WHERE admin = true AND user_name = '$NAME'")
    if [[ -z $ADMIN ]]
    then
        echo -e "\n1. Play a game\n2. View Leaderboard\n3. Update Profile\n4. View Messages\n5. Exit"
        read SELECTION

        case $SELECTION in
        1) PLAY ;;
        2) VIEW_LEADERBOARD ;;
        3) UPDATE_PROFILE ;;
        4) VIEW_MESSAGES ;;
        5) EXIT "Thank you for joining us today, hope to see you again soon!" ;;
        *) MENU "Please enter a valid option." ;;
        esac
    else
        echo -e "\n1. Play a game\n2. View Leaderboard\n3. Update Profile\n4. Office\n5. Exit"
        read SELECTION

        case $SELECTION in
        1) PLAY ;;
        2) VIEW_LEADERBOARD ;;
        3) UPDATE_PROFILE ;;
        4) OFFICE "Office: $NAME" ;;
        5) EXIT "Thank you for joining us today, hope to see you again soon!" ;;
        *) MENU "Please enter a valid option." ;;
        esac
    fi
}

function PLAY {
    clear
    sleep 1
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_name = '$NAME'")
    BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE user_name = '$NAME'")

    if [[ -z $GAMES_PLAYED ]]
    then
        echo Welcome $NAME and Good Luck on your first game! The game will begin in 3 seconds
        UPDATE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played = 1 WHERE user_name = '$NAME'")
    else
        UPDATE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE user_name = '$NAME'")
        GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_name = '$NAME'")
        echo "Welcome back for round $GAMES_PLAYED $NAME! In regards to your best form It took you $BEST_GAME guesses to beat the game"
        sleep 1
        echo Good luck, the game will begin in 3 seconds
    fi
    GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE user_name = '$NAME'")

    RANDOM_NUMBER=$(( RANDOM % 499 + 1 ))
    CURRENT_GAME_SCORE=0

    sleep 3

    echo -e "\nGuess the secret number between 1 and 500:"
    read NUMBER

    while [[ ! $NUMBER =~ ^[0-9]+$ ]]
    do
        echo -e "\nThat is not an integer, guess again:"
        read NUMBER
    done
    
    while [[ $NUMBER -ne $RANDOM_NUMBER ]]
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

    echo -e "\nYou guessed it in $CURRENT_GAME_SCORE tries. The secret number was $RANDOM_NUMBER.\n"
    echo Press enter to go back to main menu.

    if [[ -z $BEST_GAME || $CURRENT_GAME_SCORE -lt $BEST_GAME ]]
    then
        UPDATE_BEST_GAME=$($PSQL "UPDATE users SET best_game = $CURRENT_GAME_SCORE, best_game_since = NOW() WHERE user_name = '$NAME'")
        read

        MENU "Well done $NAME! The leaderboard has been updated."
    else
        read
        
        MENU "Oops better luck next time."
    fi
}

function VIEW_LEADERBOARD {
    clear
    sleep 1
    echo "$(psql -U $DB_USER -d $DB_NAME -c "SELECT user_name AS players, games_played, best_game, best_game_since AS since FROM users ORDER BY best_game")"
    BEST_PLAYER=$($PSQL "SELECT MIN(best_game) FROM users")
    echo -e "The best player is $($PSQL "SELECT user_name FROM users WHERE best_game = $BEST_PLAYER")\n"
    echo Press enter to go back to main menu.
    read ENTER
    MENU
}

function EXIT {
    clear
    sleep 1
     if [[ $1 ]]
     then
        echo -e "$1\n"
     fi
}

function UPDATE_PROFILE {
    clear
    sleep 1
    if [[ $1 ]]
    then
        echo -e "$1\n"
    fi

    echo -e "1. Change username\n2. Change password\n3. Back to menu"
    read OPTIONS

    case $OPTIONS in
    1) CHANGE_USERNAME ;;
    2) CHANGE_PASSWORD ;;
    3) MENU ;;
    *) MENU "Invalid Option" ;;
    esac
}

function CHANGE_USERNAME {
    clear
    sleep 1
    echo -e "Your Current username is: $NAME\n"
    echo "Are you sure you wish to change your name? (y/n)"
    read CONFIRMATION
    
    if [[ $CONFIRMATION == 'Yes' || $CONFIRMATION == 'yes' || $CONFIRMATION = 'y' ]]
    then
        echo Please enter new username
        read NEW_NAME

        MESSAGE_NAME=$($PSQL "SELECT user_name FROM messages WHERE user_name = '$NAME'")

        if [[ $MESSAGE_NAME ]]
        then
            UPDATE_MESSAGE_USER=$($PSQL "UPDATE messages SET user_name = '$NEW_NAME' WHERE user_name = '$NAME'")
        fi

        ALTER_NAME=$($PSQL "UPDATE users SET user_name = '$NEW_NAME' WHERE user_name = '$NAME'")
        NAME=$NEW_NAME
        UPDATE_PROFILE "Your username has been succesfully updated"

    elif [[ $CONFIRMATION == 'No' || $CONFIRMATION == 'no' || $CONFIRMATION == 'n' ]]
    then
        UPDATE_PROFILE "Username change cancelled"
    else
        UPDATE_PROFILE "Invalid option, enter either yes/y or no/n to confirm changes"
    fi
}

function CHANGE_PASSWORD {
    clear
    sleep 1
    echo "Are you sure you want to change your password (y/yes)"
    read CONFIRMATION

    if [[ $CONFIRMATION == 'Yes' || $CONFIRMATION == 'yes' || $CONFIRMATION == 'y' ]]
    then
        CURRENT_PASSWORD=$($PSQL "SELECT password FROM users WHERE user_name = '$NAME'")
        echo -e "\nEnter Current Password:"
        read -s PASSWORD
        
        until [[ $PASSWORD == $CURRENT_PASSWORD || $PASSWORD == 'cancel' ]]
        do
            echo Wrong password! re-enter password or type cancel
            read -s PASSWORD
        done

        if [[ $PASSWORD == 'cancel' ]]
        then
            UPDATE_PROFILE "Password change cancelled"
        else
            echo -e "\nEnter new password"
            read -s NEW_PASSWORD
            echo -e "\nConfirm Password"
            read -s CONFIRM_PASSWORD
            
            until [[ $NEW_PASSWORD == $CONFIRM_PASSWORD ]]
            do 
                echo -e "\nPasswords do not match, try again\n"
                echo enter new password
                read -s NEW_PASSWORD
                echo -e "\nConfirm Password"
                read -s CONFIRM_PASSWORD
            done
            ALTER_PASSWORD=$($PSQL "UPDATE users SET password = '$NEW_PASSWORD' WHERE user_name = '$NAME'")
            UPDATE_PROFILE "$(echo -e "Your password has been successfully changed\n")"
        fi
    else
        UPDATE_PROFILE "Password change cancelled"
    fi
}

function OFFICE {
    clear
    sleep 1
    if [[ $1 ]]
    then
        echo -e "$1\n"
    fi

    SUPER_ADMIN=$($PSQL "SELECT user_id FROM users WHERE super_admin = true AND user_name = '$NAME'")

    if [[ -z $SUPER_ADMIN ]]
    then
        echo -e "1. Delete User Account\n2. Block Account\n3. View Messages\n4. Send Message\n5. Back to Menu"
        read SELECTION

        case $SELECTION in
            1) DELETE_USER "Select ID of the player you would like to remove from the database\n" ;;
            2) BLOCK_USER "OFFICE: $NAME" ;;
            3) VIEW_MESSAGES ;;
            4) SEND_MESSAGES ;;
            5) MENU ;;
            *) OFFICE "Please select valid option" ;;
        esac
    else
        echo -e "1. Delete User Account\n2. Alter Admin Priviledges\n3. Block Account\n4. View Accounts\n5. View Messages\n6. Send Message\n7. Delete Message\n8. Switch Accounts\n9. Back to Menu"
        read SELECTION

        case $SELECTION in
            1) DELETE_USER "Select ID of the player you would like to remove from the database\n" ;;
            2) ALTER_ADMIN ;;
            3) BLOCK_USER "OFFICE: $NAME" ;;
            4) VIEW_ACCOUNTS ;;
            5) VIEW_MESSAGES ;;
            6) SEND_MESSAGES ;;
            7) DELETE_MESSAGES ;;
            8) SWITCH_ACCOUNTS ;;
            9) MENU ;;
            *) OFFICE "Please select valid option" ;;
        esac
    fi
}

function DELETE_USER {
    clear
    sleep 1
    if [[ $1 ]]
    then
        echo -e "$1\n"
    fi

    echo -e "$(psql -U $DB_USER -d $DB_NAME -c "SELECT user_id AS ID, user_name AS players FROM users WHERE super_admin = false AND user_name != '$NAME' ORDER BY best_game")\n"
    read SELECTION

    if [[ ! $SELECTION =~ ^[0-9]+$ ]]
    then
        SELECTION=0
    fi

    VALID_PLAYER_ID=$($PSQL "SELECT user_id FROM users WHERE user_id = $SELECTION AND super_admin = false AND user_name != '$NAME'")
    VALID_PLAYER_NAME=$($PSQL "SELECT user_name FROM users WHERE user_id = $SELECTION")

    if [[ -z $VALID_PLAYER_ID ]]
    then
        OFFICE "Please select a valid player"
    else
        echo "Are you sure you would like to delete this player (y/n)"
        read CONFIRMATION

        if [[ $CONFIRMATION == 'y' || $CONFIRMATION == 'yes' ]]
        then
            DELETE_MESSAGES=$($PSQL "DELETE FROM messages WHERE user_id = $VALID_PLAYER_ID")
            DELETING_USER=$($PSQL "DELETE FROM users WHERE user_id = $VALID_PLAYER_ID")
            OFFICE "$VALID_PLAYER_NAME has been removed from the database"
        else
            OFFICE "Player has not been removed"
        fi
    fi
}

function ALTER_ADMIN {
    clear
    sleep 1
    if [[ $1 ]]
    then
        echo -e "$1\n"
    fi

    echo -e "1. Remove admin priviledges\n2. Set admin priviledges\n3. Back to Office\n4. Back to Menu"
    read SELECTION

    case $SELECTION in
        1) REMOVE_ADMIN "Who would you like removed as admin?" ;;
        2) SET_ADMIN "Who would you like to make admin?" ;;
        3) OFFICE ;;
        4) MENU ;;
        *) ALTER_ADMIN "Please select valid option." ;;
    esac
}

function REMOVE_ADMIN {
    clear
    sleep 1
    if [[ $1 ]]
    then
        echo -e "$1\n"
    fi

    echo -e "$(psql -U $DB_USER -d $DB_NAME -c "SELECT user_id, user_name AS players FROM users WHERE admin = true AND super_admin = false ORDER BY best_game")\n"
    echo "Please select ID"
    read ID

    if [[ ! $ID =~ ^[0-9]+$ ]]
    then
        ID=0
    fi

    VALID_PLAYER_ID=$($PSQL "SELECT user_id FROM users WHERE user_id = $ID AND admin = true AND super_admin = false")
    VALID_PLAYER_NAME=$($PSQL "SELECT user_name FROM users WHERE user_id = $ID")

    if [[ -z $VALID_PLAYER_ID ]]
    then
        ALTER_ADMIN "User not found."
    else
        UPDATE_ADMIN=$($PSQL "UPDATE users SET admin = false WHERE user_id = $VALID_PLAYER_ID")
        ALTER_ADMIN "$VALID_PLAYER_NAME is now not admin"
    fi
}

function SET_ADMIN {
    clear
    sleep 1
    if [[ $1 ]]
    then
        echo -e "$1\n"
    fi

    echo -e "$(psql -U $DB_USER -d $DB_NAME -c "SELECT user_id AS ID, user_name AS players FROM users WHERE admin = false AND super_admin = false ORDER BY best_game")\n"
    echo "Please select ID"
    read ID

    if [[ ! $ID =~ ^[0-9]+$ ]]
    then
        ID=0
    fi

    VALID_PLAYER_ID=$($PSQL "SELECT user_id FROM users WHERE user_id = $ID AND admin = false and super_admin = false")
    VALID_PLAYER_NAME=$($PSQL "SELECT user_name FROM users WHERE user_id = $ID")

    if [[ -z $VALID_PLAYER_ID ]]
    then
        ALTER_ADMIN "User not found."
    else
        UPDATE_ADMIN=$($PSQL "UPDATE users SET admin = true WHERE user_id = $VALID_PLAYER_ID")
        ALTER_ADMIN "$VALID_PLAYER_NAME is now admin"
    fi
}

function VIEW_ACCOUNTS {
    clear
    sleep 1
    echo -e "$(psql -U $DB_USER -d $DB_NAME -c "SELECT * FROM users WHERE super_admin = false ORDER BY user_id")\n"
    echo Press enter to go back
    read ENTER
    OFFICE
}

function BLOCK_USER {
    clear
    sleep 1

    if [[ $1 ]]
    then
        echo -e "$1\n"
    fi

    echo -e "1. Block Account\n2. Unblock Account\n3. View Blocked Players\n4. Back to Office\n5. Back to Menu"
    read OPTION

    case $OPTION in
        1) BLOCK_PLAYER ;;
        2) UNBLOCK_PLAYER ;;
        3) VIEW_BLOCKED_PLAYERS ;;
        4) OFFICE "Office: $NAME" ;;
        5) MENU ;;
        *) BLOCK_USER "Please choose a valid option" ;;
    esac
}

function BLOCK_PLAYER {
    clear
    sleep 1
    echo -e "Who would you like to block?\n"
    echo "$(psql -U $DB_USER -d $DB_NAME -c "SELECT user_id, user_name FROM users WHERE user_name != '$NAME' AND blocked = false AND super_admin = false")"
    echo -e "\nPlease enter user id"
    read SELECTION

    if [[ ! $SELECTION =~ ^[0-9]+$ ]]
    then
        SELECTION=0
    fi

    PLAYER_TO_BLOCK=$($PSQL "SELECT user_id, user_name, id_number FROM users WHERE user_name != '$NAME' AND user_id = $SELECTION AND super_admin = false AND blocked = false")
    PLAYER=$($PSQL "SELECT user_name FROM users WHERE user_id = $SELECTION")
    
    if [[ -z $PLAYER_TO_BLOCK ]]
    then
        BLOCK_USER "User does not exist"
    else
        echo "$PLAYER_TO_BLOCK" | while IFS="|" read USER_ID USER_NAME ID_NUMBER
        do
            INSERT_INTO_BLOCKED_USERS=$($PSQL "INSERT INTO blocked_users(user_id, user_name, id_number) VALUES($USER_ID, '$USER_NAME', '$ID_NUMBER')")
            UPDATE_BLOCKED=$($PSQL "UPDATE users SET blocked = true WHERE user_id = $USER_ID")
            PLAYER=$USER_NAME
        done
        BLOCK_USER "$PLAYER's account has been successfully blocked!"
    fi
}

function UNBLOCK_PLAYER {
    clear
    sleep 1

    echo -e "Choose player to unblock"

    echo "$(psql -U $DB_USER -d $DB_NAME -c "SELECT user_id, user_name, id_number FROM blocked_users")"

    echo -e "Please enter user id"
    read SELECTION

    if [[ ! $SELECTION =~ ^[0-9]+$ ]]
    then
        SELECTION=0
    fi

    SELECTED_PLAYER=$($PSQL "SELECT user_name FROM blocked_users WHERE user_id = $SELECTION")
    
    if [[ -z $SELECTED_PLAYER ]]
    then
        BLOCK_USER "Player does not exist"
    else
        UNBLOCK=$($PSQL "DELETE FROM blocked_users WHERE user_name = '$SELECTED_PLAYER'")
        UPDATE_BLOCKED=$($PSQL "UPDATE users SET blocked = false WHERE user_name = '$SELECTED_PLAYER' AND blocked = true")
        BLOCK_USER "User $SELECTED_PLAYER's account is unblocked"
    fi
}

function VIEW_BLOCKED_PLAYERS {
    clear
    sleep 1
    echo "$(psql -U $DB_USER -d $DB_NAME -c "SELECT user_id, user_name, id_number FROM blocked_users")"
    echo -e "Press enter to exit"
    read ENTER
    BLOCK_USER "OFFICE: $NAME"
}

function VIEW_MESSAGES {
    clear
    sleep 1
    echo -e "Your Current Messages:\n"

    CURRENT_MESSAGE=0
    GET_MESSAGE=$($PSQL "SELECT message FROM messages WHERE user_name = '$NAME'")

    MESSAGE_COUNT=$(echo "$GET_MESSAGE" | wc -l)

    if [[ -z $GET_MESSAGE ]]
    then
        echo  You currently have 0 messages
    elif [[ $MESSAGE_COUNT -eq 1 ]]
    then
        echo "1. $GET_MESSAGE"
    else
        echo "$GET_MESSAGE" | while read MESSAGE
        do
            (( CURRENT_MESSAGE += 1 ))
            echo -e "$CURRENT_MESSAGE. $MESSAGE"
        done
    fi
    echo -e "\nPress enter to exit"
    read ENTER
    
    IS_ADMIN=$($PSQL "SELECT user_name FROM users WHERE user_name = '$NAME' AND admin = true")
    if [[ -z $IS_ADMIN ]]
    then
        MENU
    else
        OFFICE "Account: $NAME"
    fi
}

function SEND_MESSAGES {
    clear
    sleep 1
    echo -e "Who would you like text?\n"
    echo "$(psql -U $DB_USER -d $DB_NAME -c "SELECT user_id, user_name, blocked FROM users WHERE user_name != '$NAME' ORDER BY user_id")"
    echo "Enter ID number:"
    read ID

    if [[ ! $ID =~ ^[0-9]+$ ]]
    then
        ID=0
    fi

    GET_USER=$($PSQL "SELECT user_name FROM users WHERE user_id = $ID AND user_name != '$NAME'")

    if [[ -z $GET_USER ]]
    then
        OFFICE "Invalid ID, try again."
    else
        clear
        echo -e "\nRemove message and press enter to cancel\n"
        echo Enter Your Message to $GET_USER:
        read MESSAGE
        
        if [[ ! $MESSAGE ]]
        then
            OFFICE "Message cancelled."
        else
            SEND_MESSAGE=$($PSQL "INSERT INTO messages(user_id, user_name, message) VALUES($ID, '$GET_USER', '$MESSAGE')")
            OFFICE "Message has been sent to $GET_USER."
        fi
    fi
}

function DELETE_MESSAGES {
    clear
    sleep 1
    echo -e "Which message would you like to delete?\n"
    echo "$(psql -U $DB_USER -d $DB_NAME -c "SELECT message_id, user_name, message FROM messages ORDER BY user_id")"
    echo -e "\nEnter message ID"
    read MESSAGE_ID

    if [[ ! $MESSAGE_ID =~ ^[0-9]+$ ]]
    then
        MESSAGE_ID=0
    fi

    MESSAGE_EXISTS=$($PSQL "SELECT user_name FROM messages WHERE message_id = $MESSAGE_ID")

    if [[ -z $MESSAGE_EXISTS ]]
    then
        OFFICE "Message ID does not exist"
    else
        sleep 1
        echo -e "\nAre you sure you want delete this message? (y/n)"
        read CONFIRMATION

        if [[ $CONFIRMATION == "y" || $CONFIRMATION == "yes" || $CONFIRMATION == "Yes" ]]
        then
            DELETE=$($PSQL "DELETE FROM messages WHERE message_id = $MESSAGE_ID")
            OFFICE "Message to $MESSAGE_EXISTS Is deleted"
        else
            OFFICE "Message not deleted"
        fi
    fi
}

function SWITCH_ACCOUNTS {
    clear
    sleep 1
    echo -e "Which account do you want to use?\n"
    echo "$(psql -U $DB_USER -d $DB_NAME -c "SELECT user_id, user_name, password FROM users WHERE super_admin = false")"
    echo -e "\nEnter user ID:"
    read ID

    if [[ ! $ID =~ ^[0-9]+$ ]]
    then
        ID=0
    fi

    USER=$($PSQL "SELECT user_name FROM users WHERE user_id = $ID AND super_admin = false")

    if [[ -z $USER ]]
    then
        OFFICE "User is Invalid"
    else
        echo -e "\nAre you sure you would like to switch to $USER's account? (y/n)"
        read CONFIRMATION

        if [[ $CONFIRMATION == "y" || $CONFIRMATION == "yes" || $CONFIRMATION == "Yes" ]]
        then
            USER_PASSWORD=$($PSQL "SELECT password FROM users WHERE user_id = $ID")

            NAME=$USER
            PASSWORD=$USER_PASSWORD

            MENU "You have now switched to $USER's account"
        else
            OFFICE "Office: $NAME (switch cancelled)"
        fi
    fi
}

if [[ -z $USER_EXISTS ]]
then
    ID_NUMBER_EXISTS=$($PSQL "SELECT user_name FROM users WHERE id_number = '$ID_NUMBER'")

    if [[ $ID_NUMBER_EXISTS ]]
    then
        EXIT "You already have an account, log in with your initial logins."
    else
        INSERT_NEW_PLAYER=$($PSQL "INSERT INTO users (user_name, password, id_number) VALUES ('$NAME', '$PASSWORD', '$ID_NUMBER')")
        MENU "Welcome to the family Game $NAME! Hope you enjoy."
    fi
else
    IS_BLOCKED=$($PSQL "SELECT id_number FROM users WHERE user_name = '$NAME' AND password = '$PASSWORD'")
    BLOCKED_USER=$($PSQL "SELECT user_name FROM blocked_users WHERE id_number = '$IS_BLOCKED'")

    if [[ $BLOCKED_USER ]]
    then
        EXIT "Your account has been blocked!"
    else
        MENU "Good to have you back $NAME!"
    fi    
fi

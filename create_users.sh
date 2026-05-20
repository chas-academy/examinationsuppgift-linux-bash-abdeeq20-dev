#!/bin/bash

# Detta script skapar användare, mappar och en personlig välkomstfil.
# Scriptet måste köras som root eftersom useradd och ändring av ägare kräver det.

# Kontrollera att scriptet körs som root
if [ "$EUID" -ne 0 ]; then
    echo "Fel: Detta script måste köras som root."
    exit 1
fi

# Kontrollera att minst ett användarnamn skickas in
if [ "$#" -eq 0 ]; then
    echo "Användning: $0 användare1 användare2 användare3"
    exit 1
fi

# Först skapas alla användare som skickas in som argument
for username in "$@"; do
    if id "$username" &>/dev/null; then
        echo "Användaren $username finns redan."
    else
        useradd -m "$username"
        echo "Användaren $username skapades."
    fi
done

# Sedan skapas mappar och välkomstfil för varje användare
for username in "$@"; do
    home_dir="/home/$username"

    # Skapa mappar i användarens hemkatalog
    mkdir -p "$home_dir/Documents"
    mkdir -p "$home_dir/Downloads"
    mkdir -p "$home_dir/Work"

    # Sätt ägare och strikta rättigheter på mapparna
    chown -R "$username:$username" "$home_dir/Documents" "$home_dir/Downloads" "$home_dir/Work"
    chmod 700 "$home_dir/Documents" "$home_dir/Downloads" "$home_dir/Work"

    # Skapa personlig välkomstfil
    welcome_file="$home_dir/welcome.txt"

    echo "Välkommen $username" > "$welcome_file"
    echo "" >> "$welcome_file"
    echo "Övriga användare på systemet:" >> "$welcome_file"

    # Lista alla andra användare som har hemkatalog under /home
    for other_user in $(awk -F: '$6 ~ /^\/home\// {print $1}' /etc/passwd); do
        if [ "$other_user" != "$username" ]; then
            echo "- $other_user" >> "$welcome_file"
        fi
    done

    # Sätt rätt ägare och rättigheter på välkomstfilen
    chown "$username:$username" "$welcome_file"
    chmod 600 "$welcome_file"

    echo "Mappar och welcome.txt skapades för $username."
done

#!/bin/bash

# Affiche le titre
su -c 'figlet "ICT-182" | lolcat -a -s 100 | boxes -d parchment' cpnv

# Fonction pour afficher le menu
function show_menu {
    echo "Menu:"
    echo "1. Créer les laboratoires"
    echo "2. Mettre en pause tous les laboratoires"
    echo "3. Redémarrer tous les laboratoires"
    echo "4. Stopper et supprimer tous les laboratoires"
    echo "5. Activer cowsay"
    echo "6. Désactiver cowsay"
    echo "7. Afficher le statut des conteneurs Docker"
    echo "8. Quitter"
}

# Fonction pour exécuter le script principal
function run_script {
    # Demande à l'utilisateur s'il souhaite réinitialiser sa configuration Docker
    read -p "Voulez-vous réinitialiser votre configuration Docker? (y/n) " reset_docker

    if [ "$reset_docker" = "y" ]; then
        # Arrêter et supprimer tous les conteneurs
        docker stop $(docker ps -aq)
        docker rm $(docker ps -aq)

        # Supprimer toutes les images Docker
        docker rmi $(docker images -q) -f

        # Supprimer tous les réseaux Docker
        docker network rm $(docker network ls -q)
    fi 

    # Demande à l'utilisateur combien de paires de machines il veut
    read -p "Combien d'élèves avez-vous? " pairs

    # Initialiser des tableaux pour stocker les noms de machines et les adresses IP
    declare -A pirate_ips
    declare -A pentester_ips

    # Boucle pour créer et lancer les paires de machines
    for i in $(seq 1 $pairs)
    do
        # Nom du fichier docker-compose pour cette paire
        compose_file="docker-compose-pair-$i.yml"

        # Générer le contenu du fichier docker-compose
        cat > $compose_file <<EOF
version: '3.8'

services:
  pirate-$i:
    build:
      context: ./
      dockerfile: DockerfilePirate
    container_name: Pirate_$i
    ports:
      - "800${i}:80"
    stdin_open: true
    tty: true
    networks:
      - app-network-$i

  pentester-$i:
    build:
      context: ./
      dockerfile: DockerfilePentester
    container_name: Pentester_$i
    ports:
      - "220${i}:22"
    stdin_open: true
    tty: true
    networks:
      - app-network-$i

networks:
  app-network-$i:
EOF

        # Lancer le docker-compose pour cette paire
        docker-compose -f $compose_file up -d

        # Récupérer les adresses IP des conteneurs
        pirate_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' Pirate_$i)
        pentester_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' Pentester_$i)

        # Stocker les adresses IP dans les tableaux
        pirate_ips[Pirate_$i]=$pirate_ip
        pentester_ips[Pentester_$i]=$pentester_ip

        # Supprimer le fichier docker-compose
        rm $compose_file
    done

    # Afficher les adresses IP après la boucle
    echo "Adresses IP des conteneurs par élève:"
    for i in $(seq 1 $pairs); do
        echo "Paire $i:"
        echo "  Pirate-$i (Pirate_$i): ${pirate_ips[Pirate_$i]} Nom d'utilisateur: root Mot de passe: live"
        echo "  Pentester-$i (Pentester_$i): ${pentester_ips[Pentester_$i]}"
    done
}

# Fonction pour mettre en pause tous les laboratoires
function pause_labs {
    docker pause $(docker ps -q)
    echo "Tous les laboratoires ont été mis en pause."
}

# Fonction pour redémarrer tous les laboratoires
function restart_labs {
    docker restart $(docker ps -q)
    echo "Tous les laboratoires ont été redémarrés."
}

# Fonction pour stopper et supprimer tous les laboratoires
function stop_and_remove_labs {
    docker stop $(docker ps -aq)
    docker rm $(docker ps -aq)
    echo "Tous les laboratoires ont été stoppés et supprimés."
}

# Fonction pour activer cowsay
function enable_cowsay {
    sed -i '/cowsay/s/^# //' DockerfilePirate
    echo "Cowsay a été activé."
}

# Fonction pour désactiver cowsay
function disable_cowsay {
    sed -i '/cowsay/s/^/# /' DockerfilePirate
    echo "Cowsay a été désactivé."
}

# Fonction pour afficher le statut des conteneurs Docker
function show_docker_status {
    containers=$(docker ps -a --format '{{.ID}} {{.Names}} {{.Status}}')
    echo "Statut des conteneurs Docker:"
    echo "ID          Nom           Etat            IP"
    echo "---------------------------------------------"
    while IFS= read -r container; do
        container_id=$(echo $container | awk '{print $1}')
        container_name=$(echo $container | awk '{print $2}')
        container_status=$(echo $container | awk '{print $3, $4, $5, $6}')
        container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_id)
        printf "%-10s %-12s %-15s %-10s\n" $container_id $container_name "$container_status" $container_ip
    done <<< "$containers"
}

# Boucle principale du menu
while true; do
    show_menu
    read -p "Choisissez une option: " choice
    case $choice in
        1) run_script ;;
        2) pause_labs ;;
        3) restart_labs ;;
        4) stop_and_remove_labs ;;
        5) enable_cowsay ;;
        6) disable_cowsay ;;
        7) show_docker_status ;;
        8) exit 0 ;;
        *) echo "Option invalide. Veuillez réessayer." ;;
    esac
done

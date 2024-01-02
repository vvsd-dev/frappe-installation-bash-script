#!/bin/bash

# Function to display a checklist
show_checklist() {
    local title="$1"
    shift
    local options=()
    local choices=()

    while [ $# -gt 0 ]; do
        options+=("$1" "$2" off)
        shift 2
    done

    choices=$(whiptail --separate-output --checklist "$title" 20 50 10 "${options[@]}" 3>&1 1>&2 2>&3)

    echo "$choices"
}

# Function to prompt for input using whiptail
whiptail_input() {
    local prompt="$1"
    local default="$2"
    local result

    result=$(whiptail --inputbox "$prompt" 10 40 "$default" 3>&1 1>&2 2>&3)
    echo "$result"
}

# Function to check if the user exists
user_exists() {
    local username="$1"
    id "$username" &>/dev/null
}

# Set default username to the result of whoami
DEFAULT_USER=$(whoami)

# Prompt the user to enter their username (with default)
input_user=$(whiptail_input "Please enter your username:" "$DEFAULT_USER")
ORIGINAL_USER=${input_user:-"$DEFAULT_USER"}

# Check if the entered username is not the default and does not exist
if [ "$ORIGINAL_USER" != "$DEFAULT_USER" ] && ! user_exists "$ORIGINAL_USER"; then
    whiptail --msgbox "User $ORIGINAL_USER does not exist." 10 40

    # Prompt for retry
    if whiptail --yesno "Retry with a different username?" 10 40; then
        input_user=$(whiptail_input "Please enter your username:" "")
        ORIGINAL_USER=${input_user:-"$DEFAULT_USER"}

        # Check again if the entered username exists
        if ! user_exists "$ORIGINAL_USER"; then
            whiptail --msgbox "User $ORIGINAL_USER does not exist. Exiting." 10 40
            exit 1
        fi
    else
        whiptail --msgbox "Exiting." 10 40
        exit 1
    fi
fi

# Prompt the user to enter the installation path for the bench (with default)
bench_path=$(whiptail_input "Please enter the installation path for the bench:" "/home/$ORIGINAL_USER")
BENCH_PATH=${bench_path:-"/home/$ORIGINAL_USER"}

# Check if the specified path exists
if [ ! -d "$BENCH_PATH" ]; then
    whiptail --msgbox "Specified path $BENCH_PATH does not exist. Exiting." 10 40
    exit 1
fi

# Prompt the user to enter the name of the bench folder (with default)
bench_folder=$(whiptail_input "Please enter the name of the bench folder:" "version14_bench")
BENCH_FOLDER=${bench_folder:-"version14_bench"}

# MySQL configuration
MYSQL_CONFIG="[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4"

# Packages to install with descriptions
packages_to_install=("Git" "Install Git" "Python" "Install Python and related packages" "MariaDB" "Install MariaDB" "Libmysqlclient_Dev" "Install libmysqlclient-dev" "XVFB_Libfontconfig_Wkhtmltopdf" "Install xvfb libfontconfig wkhtmltopdf" "MySQL" "Secure MySQL installation" "NVM_Node.js" "Install NVM and Node.js" "NPM_Yarn" "Install npm and yarn" "Redis_Server" "Install redis-server" "Software_Properties_Common" "Install software-properties-common" "Frappe_Bench" "Install Frappe Bench" "Frappe_Production" "Setup Frappe Production Mode")

# Display a checklist for package selection
selected_packages=$(show_checklist "Select packages to install" "${packages_to_install[@]}")

# Process the selected packages
for package in $selected_packages; do
    case "$package" in
        "Git") echo "Installing Git..." && sudo apt-get install git -y ;;
        "Python") echo "Installing Python and related packages..." && sudo apt-get install python3-dev python3.10-dev python3-setuptools python3-pip python3-distutils -y && sudo apt-get install python3.10-venv -y ;;
        "MariaDB") echo "Installing MariaDB..." && sudo apt install mariadb-server mariadb-client -y ;;
        "Libmysqlclient_Dev") echo "Installing libmysqlclient-dev..." && sudo apt-get install libmysqlclient-dev -y ;;
        "XVFB_Libfontconfig_Wkhtmltopdf") echo "Installing xvfb libfontconfig wkhtmltopdf..." && sudo apt-get install xvfb libfontconfig wkhtmltopdf -y ;;
        "MySQL") echo "Securing MySQL installation..." && sudo mysql_secure_installation && echo "$MYSQL_CONFIG" | sudo tee -a /etc/mysql/my.cnf > /dev/null && sudo service mysql restart ;;
        "NVM_Node.js") echo "Installing NVM and Node.js..." && sudo apt install curl -y && curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash && source ~/.profile && nvm install 16.15.0 ;;
        "NPM_Yarn") echo "Installing npm and yarn..." && sudo apt-get install npm -y && sudo npm install -g yarn ;;
        "Redis_Server") echo "Installing redis-server..." && sudo apt-get install redis-server -y ;;
        "Software_Properties_Common") echo "Installing software-properties-common..." && sudo apt-get install software-properties-common -y ;;
        "Frappe_Bench") echo "Installing Frappe Bench..." && sudo pip3 install frappe-bench && cd "$BENCH_PATH" && bench init --frappe-branch version-14 --python python3.10 "$BENCH_FOLDER" ;;
        "Frappe_Production") echo "Setting up Frappe Production Mode..." && cd "$BENCH_PATH/$BENCH_FOLDER" && . env/bin/activate && sudo bench setup production $ORIGINAL_USER && sudo bench setup production $ORIGINAL_USER ;;
    esac
done


whiptail --msgbox "Installation process completed." 10 40

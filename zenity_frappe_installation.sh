#!/bin/bash

# Function to check if the user exists
user_exists() {
    local username="$1"
    id "$username" &>/dev/null
}

# Set default username to the result of whoami
DEFAULT_USER=$(whoami)

# Prompt the user to enter their username (with default)
input_user=$(zenity --entry --title="Username" --text="Please enter your username:" --entry-text="$DEFAULT_USER")
ORIGINAL_USER=${input_user:-"$DEFAULT_USER"}

# Check if the entered username is not the default and does not exist
if [ "$ORIGINAL_USER" != "$DEFAULT_USER" ] && ! user_exists "$ORIGINAL_USER"; then
    zenity --error --title="Error" --text="User $ORIGINAL_USER does not exist. Exiting."
    exit 1
fi

# Prompt the user to enter the installation path for the bench (with default)
bench_path=$(zenity --entry --title="Bench Path" --text="Please enter the installation path for the bench:" --entry-text="/home/$ORIGINAL_USER")

# Check if the specified path exists
if [ ! -d "$bench_path" ]; then
    zenity --error --title="Error" --text="Specified path $bench_path does not exist. Exiting."
    exit 1
fi

# Prompt the user to enter the name of the bench folder (with default)
bench_folder=$(zenity --entry --title="Bench Folder" --text="Please enter the name of the bench folder:" --entry-text="version14_bench")

# MySQL configuration
MYSQL_CONFIG="[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4"

# Display a checklist for package selection
selected_packages=$(zenity --list --title="Select packages to install" --text="Choose packages to install:" --checklist --column="" --column="Package" --column="Description" \
    FALSE "Git" "Install Git" \
    FALSE "Python" "Install Python and related packages" \
    FALSE "MariaDB" "Install MariaDB" \
    FALSE "MySQL" "Secure MySQL installation" \
    FALSE "NVM_Node.js" "Install NVM and Node.js" \
    FALSE "NPM_Yarn" "Install npm and yarn" \
    FALSE "Frappe_Bench" "Install Frappe Bench" \
    FALSE "Frappe_Production" "Setup Frappe Production Mode")

# Process the selected packages
for package in $selected_packages; do
    case "$package" in
        "Git") zenity --info --title="Installing Git" --text="Installing Git..." && sudo apt-get install git -y ;;
        "Python") zenity --info --title="Installing Python" --text="Installing Python and related packages..." && sudo apt-get install python3-dev python3.10-dev python3-setuptools python3-pip python3-distutils -y && sudo apt-get install python3.10-venv -y ;;
        "MariaDB") zenity --info --title="Installing MariaDB" --text="Installing MariaDB..." && sudo apt install mariadb-server mariadb-client -y ;;
        "MySQL")
            zenity --info --title="Securing MySQL" --text="Securing MySQL installation..."
            sudo mysql_secure_installation && echo "$MYSQL_CONFIG" | sudo tee -a /etc/mysql/my.cnf > /dev/null && sudo service mysql restart
            ;;
        "NVM_Node.js") zenity --info --title="Installing NVM and Node.js" --text="Installing NVM and Node.js..." && sudo apt install curl -y && curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash && source ~/.profile && nvm install 16.15.0 ;;
        "NPM_Yarn") zenity --info --title="Installing npm and yarn" --text="Installing npm and yarn..." && sudo apt-get install npm -y && sudo npm install -g yarn ;;
        "Frappe_Bench") zenity --info --title="Installing Frappe Bench" --text="Installing Frappe Bench..." && sudo pip3 install frappe-bench && cd "$bench_path" && bench init --frappe-branch version-14 --python python3.10 "$bench_folder" ;;
        "Frappe_Production") zenity --info --title="Setting up Frappe Production Mode" --text="Setting up Frappe Production Mode..." && cd "$bench_path/$bench_folder" && . env/bin/activate && sudo bench setup production $ORIGINAL_USER && sudo bench setup production $ORIGINAL_USER ;;
    esac
done

zenity --info --title="Completion" --text="Installation process completed."

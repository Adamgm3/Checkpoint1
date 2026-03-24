# Creating a log file
LOG_FILE="../../../var/log/user_onboarding_audit.log"

# Log message logic
log_message() {
   local message="$1"
   local timestamp
   timestamp=$(date +"%Y-%m-%d %H:%M:%S")
   echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

while IFS=',' read -r username groupname shell; do
        # Validate username: only lowercase letters, digits, hyphens, underscores
        if ! [[ "$username" =~ ^[a-z][a-z0-9_-]{0,31}$ ]]; then
                log_message "ERROR: Invalid username $username -- skipping"
                continue # skip to next loop iteration
        fi

        # Check all fields are non-empty
        if [[ -z "$username" || -z "$groupname" || -z "$shell" ]]; then
                log_message "ERROR: Missing field(s) in record -- skipping"
                continue
        fi

        # Validate that the shell exists on this system
        if ! grep -qx "$shell" /etc/shells; then
                log_message "WARNING: Shell '$shell' not in /etc/shells -- proceeding anyway"
        fi

        # Checking if the user exists
        id "$username" &>/dev/null && log_message "User $username already exists" || log_message "User does not exist"

        # Create a user with a home directory and specific shell
        sudo useradd -m -s "$shell" "$username" && log_message "Added user $username"

        # Update an existing user's shell
        sudo usermod -s "$shell" "$username" && log_message "Set $username's shell to $shell"

        # Check if a group exists
        getent group "$groupname" &>/dev/null && log_message "Group $groupname already exists" || sudo groupadd "$groupname" log_message "Added group: $groupname"

        # Add a user to a group (supplementary, non-destructive)
        sudo usermod -aG "$groupname" "$username" && log_message "Added user $username to group $groupname"

        # Verify membership
        groups "$username"
        membership=$(groups "$username")
        log_message "$username's group: $membership"

        # Create home directory if it doesn't exist
        [ ! -d "/home/$username" ] && sudo mkdir -p "/home/$username" && log_message "Home directory created"

        # Set correct ownership and permissions
        sudo chown "$username":"$username" "/home/$username"
        sudo chmod 700 "/home/$username"
        log_message "Set ownership and permissions for home directory"

        # Creating project directory
        [ ! -d "/opt/projects/$username" ] && sudo mkdir -p "/opt/projects/$username" && log_message "Project directory created"

        # Setting ownership and permissions for the project directory
        sudo chown "$username":"$groupname" "/opt/projects/$username"
        sudo chmod 750 "/opt/projects/$username"
        log_message "Set ownership and permissions for project directory"

done < users.csv
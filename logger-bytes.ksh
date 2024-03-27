#!/bin/ksh

# Function for preventing running another instance of this script
prevent_function() {

    # Lock file path
    LOCK_FILE="/apps/dccs/LOGGERTEST/logger_script.pid"

    # Check if another instance of the script is running
    if [ -f "$LOCK_FILE" ]; then
        # Read the PID from the lock file
        pid=$(cat "$LOCK_FILE")

        # Check if the process corresponding to the PID is running
        if ps -p "$pid" >/dev/null; then
            echo "Script is already running with PID $pid. Exiting..."
            exit 1
        else
            # Remove stale lock file
            rm -f "$LOCK_FILE"
        fi
    fi

    # Get the current process ID
    current_pid=$$

    # Write the current PID to the lock file
    echo "$current_pid" >"$LOCK_FILE"
}

# The script
prevent_function

# Store LOG_FILE variable and get its size
LOG_FILE=$(find /apps/dccs/LOGGERTEST/ -type f -name 'testlo*' -print | xargs ls -ltr | tail -n 1 | awk '{print $9}')
old_size=$(wc -c <"$LOG_FILE")

# Adding the tag to logger messages
APP_NAME="TESTLOG_TAG"

# Main checking and logger function
main_function() {

    # Get the latest log file and store another NEW_LOG_FILE variable
    NEW_LOG_FILE=$(find /apps/dccs/LOGGERTEST/ -type f -name 'testlo*' -print | xargs ls -ltr | tail -n 1 | awk '{print $9}')

    if [ "$NEW_LOG_FILE" = "$LOG_FILE" ]; then
        # Get the current size of the log file
        new_size=$(wc -c <"$NEW_LOG_FILE")

        # If the log file size hasn't changed, exit the loop
        if [ "$new_size" -eq "$old_size" ]; then
            sleep 10
        # If the log file has grown since the last check
        elif [ "$new_size" -gt "$old_size" ]; then
            # Calculate the number of bytes to read
            num_bytes=$((new_size - old_size))
            # Get new entries and push them to syslogd
            new_entries=$(tail -c "$num_bytes" "$LOG_FILE")
            logger "$APP_NAME: $new_entries"
        # If the new_size is less than old_size or equals 0
        else
            sleep 10
        fi
    fi

    # This block should process 2 files, the old one and the new one
    if [ "$NEW_LOG_FILE" != "$LOG_FILE" ]; then
        # Get the current size of the old log file
        new_size=$(wc -c <"$LOG_FILE")

        # Get the current size of the new log file
        new_size_new_file=$(wc -c <"$NEW_LOG_FILE")

        # If the old log file size hasn't changed
        if [ "$new_size" -eq "$old_size" ]; then
            # Calculate the number of the new log file bytes to read
            num_bytes_new_file=$((new_size_new_file - 0))

            # Get new entries of a new file and push them to syslogd
            new_entries_new_file=$(tail -c "$num_bytes_new_file" "$NEW_LOG_FILE")
            logger "$APP_NAME: $new_entries_new_file"

        # If the old log file has grown since the last check
        elif [ "$new_size" -gt "$old_size" ]; then
            # Calculate the number of bytes to read
            num_bytes=$((new_size - old_size))

            # Get new entries and push them to syslogd
            new_entries=$(tail -c "$num_bytes" "$LOG_FILE")
            logger "$APP_NAME: $new_entries"

            # Calculate the number of the new log file bytes to read
            num_bytes_new_file=$((new_size_new_file - 0))

            # Get new entries of a new file and push them to syslogd
            new_entries_new_file=$(tail -c "$num_bytes_new_file" "$NEW_LOG_FILE")
            logger "$APP_NAME: $new_entries_new_file"

        # If the new_size is less than old_size or equals 0, process the new file only
        elif [ "$new_size" -lt "$old_size" ] || [ "$new_size" = 0 ]; then
            # Calculate the number of the new log file bytes to read
            num_bytes_new_file=$((new_size_new_file - 0))

            # Get new entries of a new file and push them to syslogd
            new_entries_new_file=$(tail -c "$num_bytes_new_file" "$NEW_LOG_FILE")
            logger "$APP_NAME: $new_entries_new_file"

        fi
    fi
}

# Performing the main_function while true
while true; do
    main_function

    # Store the LOG_FILE
    LOG_FILE=$NEW_LOG_FILE

    # Store old_size as a new_size
    old_size=$new_size

    # Pause 10 secs
    sleep 10

    # End of code block
done
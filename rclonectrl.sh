#!/usr/bin/env bash

# Warning: Be careful with the directories you add here!
mntdir="/run/media/"          # The path to mount remotes to. Alternatively choose /mnt/, /media/, /run/media/, /run/mnt/, a folder in /home/$USER/ or another directory. Use absolute paths.
usrmntdir="${mntdir}${USER}/" # Variable that takes the mount path and appends the username as a subdirectory in order to limit access.
provider=("Mega")             # List of providers separated by spaces and wrapped in double quotes. The names must match your rclone remote profiles, do not add colons or slashes.

remotemntdir=()
remotename=()

for p in "${provider[@]}"; do
    remotemntdir+=("${usrmntdir}${p}/") # Directories for the individual remotes named after the remotes.
    remotename+=("${p}:/")              # The path for the remotes root directories.
done

mount_remotes() {
    # Create user subdirectory if it does not exist
    if test ! -d "$usrmntdir"; then
        echo "User subdirectory doesn't exist, making one..."
        sudo mkdir -m 750 "$usrmntdir"
        sudo chown root:root "$usrmntdir"
        sudo setfacl -m u::rwx,u:"$USER":r-x,g::r-x,m:r-x,o::--- "$usrmntdir"
    fi

    # Create mount points for each remote in the array
    for i in "${!remotemntdir[@]}"; do
        if test ! -d "${remotemntdir[$i]}"; then
            echo "Creating mount points..."
            sudo mkdir -m 755 "${remotemntdir[$i]}"
            sudo chown "$(whoami):$(id -gn)" "${remotemntdir[$i]}"
        fi

        # Mount each remote
        echo "Mounting remotes..."
        if rclone mount "${remotename[$i]}" "${remotemntdir[$i]}" --daemon; then
            echo "${remotename[$i]} mount complete at ${remotemntdir[$i]}"
        else
            echo "${remotename[$i]} mount failed at ${remotemntdir[$i]}"
        fi
    done
}

unmount_remotes() {
    # Unmount each remote
    for i in "${!remotemntdir[@]}"; do
        echo "Unmounting remotes..."
        if fusermount -u "${remotemntdir[$i]}"; then
            echo "${remotename[$i]} unmount complete at ${remotemntdir[$i]}"

            # Remove each empty mount directory
            if test -d "${remotemntdir[$i]}"; then
                sudo rmdir "${remotemntdir[$i]}"
                echo "Removing mount points..."
            fi
        else
            echo "${remotename[$i]} unmount failed at ${remotemntdir[$i]}"
        fi
    done

    # Remove empty user subdirectory
    if test -z "$(find "$usrmntdir" -mindepth 1 -maxdepth 1)"; then
        echo "Removing empty user subdirectory..."
        sudo rmdir "$usrmntdir"
    fi
}

safety_check() {
    # To catch common errors
    if test "$EUID" -eq 0; then
        echo "Safety check failed! Do not run this script as root! Exiting..."
        sleep 3
        exit 1
    fi

    if ! test "${mntdir#"/"}" != "$mntdir"; then
        echo "Safety check failed! mntdir must be an absolute path. Exiting..."
        sleep 3
        exit 1
    fi

    if printf '%s\n' "${remotemntdir[@]}" | grep -q '//'; then
        echo "Safety check failed! Double slashes in directory! Exiting..."
        sleep 3
        exit 1
    fi
}

usage() {
    echo -e "rclone-mount - mount and unmount rclone remotes\n\nusage: $(basename "$0") [option]\n\noptions:\n  -m, --mount\tmount all configured remotes\n  -u, --unmount\tunmount all configured remotes\n  -h, --help\tshow this help message"
}

main() {
    safety_check
    case "$1" in
    -m)
        mount_remotes
        ;;
    -u)
        unmount_remotes
        ;;
    --mount)
        mount_remotes
        ;;
    --unmount)
        unmount_remotes
        ;;
    *)
        usage
        exit 1
        ;;
    esac
}

main "$@"
echo "All done!"
exit 0

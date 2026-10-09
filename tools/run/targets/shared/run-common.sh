#!/usr/bin/env bash
# Shared logic for the run scripts (macOS and Linux).
#
# The caller sources run.conf and common.sh first, then defines these adapter
# functions and summary strings, then sources this file and calls main "$@":
#
#   require_platform   platform check (exits when the platform is wrong)
#   image_exists       return 0 when the image is present
#   pull_image         pull the image
#   container_exists   return 0 when the container is present
#   create_container   create the container
#   start_container    start the container
#   stop_container_cmd stop the container
#   remove_container   force-remove the container (quiet)
#   remove_image       force-remove the image (quiet)
#   prepare_data_dir   make the data directory writable by the container
#   LOGS_CMD STOP_CMD DELETE_CMD EXEC_CMD   summary command strings

# Common create arguments: the volume mount and the forwarded DB_ENV_* values.
COMMON_ARGS=()
common_create_args() {
    COMMON_ARGS=(
        --volume "${DATA_DIR}:/data"
        --env "CRON_SCHEDULE=${CRON_SCHEDULE}"
        --env "DB_ENV_DB_SLEEP=${DB_ENV_DB_SLEEP:-}"
        --env "DB_ENV_DB_BROWSER=${DB_ENV_DB_BROWSER:-}"
        --env "DB_ENV_ENABLE_ST_EK2=${DB_ENV_ENABLE_ST_EK2:-}"
        --env "DB_ENV_LIMIT_JOBS=${DB_ENV_LIMIT_JOBS:-}"
    )
}

usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [--stop | --remove]
  (no args)   pull the image, create, and run the container
  --stop      stop the container if it exists
  --remove    remove the container and the image if they exist
EOF
}

stop_container() {
    if container_exists; then
        info "Stopping container '${CONTAINER_NAME}' ..."
        stop_container_cmd
        ok "Stopped."
    else
        warn "Container '${CONTAINER_NAME}' does not exist."
    fi
}

remove_all() {
    if container_exists; then
        info "Removing container '${CONTAINER_NAME}' ..."
        remove_container
    fi
    if image_exists; then
        info "Removing image '${IMAGE_NAME}' ..."
        remove_image
    fi
    ok "Removed."
}

create_and_start() {
    info "Creating container '${CONTAINER_NAME}' ..."
    create_container
    info "Starting container '${CONTAINER_NAME}' ..."
    start_container
}

run_container() {
    # Honour DB_ENV_PATH_DATA when it points to an existing directory.
    if [ -n "${DB_ENV_PATH_DATA:-}" ] && [ -d "${DB_ENV_PATH_DATA}" ]; then
        DATA_DIR="${DB_ENV_PATH_DATA}"
    fi

    # Pull the image when it is missing.
    if ! image_exists; then
        info "Pulling ${IMAGE_NAME} ..."
        pull_image
    fi

    # Prepare the data directory.
    mkdir -p "${DATA_DIR}"
    info "Making ${DATA_DIR} writable by the container ..."
    prepare_data_dir

    if container_exists; then
        warn "Container '${CONTAINER_NAME}' already exists."
        read -r -p "Stop, delete, and recreate it? [y/N] " answer
        case "${answer}" in
        [yY]*)
            info "Removing the existing container ..."
            remove_container
            create_and_start
            ;;
        *)
            info "Keeping the existing container and starting it ..."
            start_container
            ;;
        esac
    else
        create_and_start
    fi

    echo
    ok "Container '${CONTAINER_NAME}' is running."
    echo
    echo "To run the bot now:"
    echo "  ${EXEC_CMD}"
    echo
    echo "Follow logs:  ${LOGS_CMD}"
    echo "Stop:         ${STOP_CMD}"
    echo "Delete:       ${DELETE_CMD}"
    echo
}

main() {
    # Help works without any platform requirement.
    case "${1:-}" in
    -h | --help) usage; exit 0 ;;
    esac

    require_platform

    case "${1:-}" in
    --stop)   stop_container ;;
    --remove) remove_all ;;
    "")       run_container ;;
    *)        usage; exit 1 ;;
    esac
}

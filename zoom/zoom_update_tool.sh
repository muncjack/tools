#!/bin/bash

# Configuration
MY_NAME="zoom_update_tool.sh"
BASE_DIR="/opt/tools"
SCRIPT_DIR="${BASE_DIR}/scripts"
LOCAL_REPO_DIR="${BASE_DIR}/repo/zoom_repo"
SCRIPT_DIR="`dirname ${LOCAL_REPO_DIR}`/scripts"
REPO_LIST_FILE="/etc/apt/sources.list.d/zoom.list"
GPG_KEY_URL="https://zoom.us/linux/gpg-release-key.asc"
GPG_KEY_URL="https://zoom.us/linux/download/pubkey"
ZOOM_URL="https://zoom.us/client/latest/zoom_amd64.deb"
GPG_KEY_FILE="/usr/share/keyrings/zoom-archive-keyring.gpg"

if [ "${USER}" == "root" ]
  then
    BASE_CMD=""
else
    BASE_CMD="sudo"
fi

fail_exit() {
    echo "Failed" 
    exit $1
}

setup_config() {
  echo -e "Repository directory created \t"
  ${BASE_CMD} mkdir -p "$LOCAL_REPO_DIR" && echo -e "done" || fail_exit 1
  
  if [ ! -f "/usr/share/keyrings/zoom-archive-keyring.gpg" ]
    then
       echo -e "adding Zoom GPG key\t" 
       #${BASE_CMD} gpg --dearmor -o /usr/share/keyrings/zoom-archive-keyring.gpg <(curl -fsSL "$GPG_KEY_URL") &&
       #${BASE_CMD} gpg --dearmor -o /usr/share/keyrings/zoom-archive-keyring.gpg <(wget -O - "$GPG_KEY_URL") &&
       wget -q -O - "$GPG_KEY_URLfsdfdfdsf" |${BASE_CMD} gpg --dearmor -o ${GPG_KEY_FILE} &&
       echo -e "done" || fail_exit 2
  fi
  if [ ! -f "$REPO_LIST_FILE" ]
    then
       DEB_SOURCE_STR="deb [signed-by=${GPG_KEY_FILE}] file://$LOCAL_REPO_DIR ./"
       echo -e "adding repo config to apt\t" 
       #${BASE_CMD} tee "$REPO_LIST_FILE" > /dev/null <(echo "deb file://$LOCAL_REPO_DIR ./") &&
       echo "${DEB_SOURCE_STR}"| {BASE_CMD} tee "$REPO_LIST_FILE" > /dev/null &&
       echo -e "done" || fail_exit 3
  fi
  if [ ! -f "${SCRIPT_DIR}/${MY_NAME}" ]
    then
        echo -e "adding script dir\t" 
        ${BASE_CMD} mkdir -p "${SCRIPT_DIR}"  && echo -e "done" || fail_exit 1
        ${BASE_CMD} wget -q 
  fi
  package_download
}


package_download() {
  echo -e "doing itial package download\t"
  ${BASE_CMD} wget -N -P "$LOCAL_REPO_DIR" "$ZOOM_URL" && echo -e "done" || fail_exit 4

  cd ${LOCAL_REPO_DIR}
  #exit 0
  echo -e "create package repolist\t"
  #${BASE_CMD} tee Packages <(${BASE_CMD} apt-ftparchive packages zoom_amd64.deb) && echo -e "done" || fail_exit 5
  ${BASE_CMD} apt-ftparchive packages zoom_amd64.deb |${BASE_CMD} tee  Packages && echo -e "done" || fail_exit 5
  ${BASE_CMD} apt update
}

# Main function
main() {
    if [ ! -f  "${LOCAL_REPO_DIR}" ]
      then
        setup_config
        ${BASE_CMD} apt install zoom
    else
      package_download
    fi
}

# Run the main function
main

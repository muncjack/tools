#!/bin/bash

# Configuration
MY_NAME="zoom_update_script.sh"
BASE_DIR="/opt/tools"
SCRIPT_DIR="${BASE_DIR}/scripts"
SCRIPT_MIRROR_DIR="${BASE_DIR}/mirror/zoom"
SCRIPT_URL="https://github.com/muncjack/tools/blob/main/zoom/${MY_NAME}"
LOCAL_REPO_DIR="${BASE_DIR}/repo/zoom_repo"
REPO_LIST_FILE="/etc/apt/sources.list.d/zoom.list"
GPG_KEY_URL="https://zoom.us/linux/gpg-release-key.asc"
GPG_KEY_URL="https://zoom.us/linux/download/pubkey"
ZOOM_URL="https://zoom.us/client/latest/zoom_amd64.deb"
GPG_KEY_FILE="/usr/share/keyrings/zoom-archive-keyring.gpg"

if [ "${USER}" == "root" ]; then
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
  
  if [ ! -f "${GPG_KEY_FILE}" ]; then
      echo -e "adding Zoom GPG key\t" 
      #${BASE_CMD} gpg --dearmor -o /usr/share/keyrings/zoom-archive-keyring.gpg <(curl -fsSL "$GPG_KEY_URL") &&
      #${BASE_CMD} gpg --dearmor -o /usr/share/keyrings/zoom-archive-keyring.gpg <(wget -O - "$GPG_KEY_URL") &&
      wget -q -O - "$GPG_KEY_URL" |${BASE_CMD} gpg --dearmor -o ${GPG_KEY_FILE} &&
      echo -e "done" || fail_exit 2
  fi
  if [ ! -f "$REPO_LIST_FILE" ]; then
      DEB_SOURCE_STR="deb [signed-by=${GPG_KEY_FILE}] file://$LOCAL_REPO_DIR ./"
      echo -e "adding repo config to apt\t" 
      #${BASE_CMD} tee "$REPO_LIST_FILE" > /dev/null <(echo "deb file://$LOCAL_REPO_DIR ./") &&
      echo "${DEB_SOURCE_STR}"| ${BASE_CMD} tee "$REPO_LIST_FILE" > /dev/null &&
      echo -e "done" || fail_exit 3
  fi
  if [ ! -f "${SCRIPT_DIR}/${MY_NAME}" ]; then
      echo -e "adding script dir\t" 
      ${BASE_CMD} mkdir -p "${SCRIPT_DIR}"  && echo -e "done" || fail_exit 1
      
      echo -e "adding script mirror dir\t" 
      ${BASE_CMD} mkdir -p "${SCRIPT_MIRROR_DIR}"  && echo -e "done" || fail_exit 1
      ${BASE_CMD} chown -R root:root ${BASE_DIR}
  fi
  script_download
  package_download
}

script_download() {
  echo -e "download script\t\t"
  ${BASE_CMD} wget -q -N -P "${SCRIPT_MIRROR_DIR}" "${SCRIPT_URL}" && echo -e "done" || fail_exit 1
  if [ "`sum -r ${SCRIPT_DIR}/.${MY_NAME}.new 2>/dev/null`" != "sum -r ${SCRIPT_DIR}/.${MY_NAME}.new" ]; then
      # this is for currently runing process to not fail
      ${BASE_CMD} mv -v "${SCRIPT_DIR}/${MY_NAME}" "${SCRIPT_DIR}/.${MY_NAME}.old"
      ${BASE_CMD} cp "${SCRIPT_MIRROR_DIR}/${MY_NAME}" "${SCRIPT_DIR}/${MY_NAME}"
      # set flag to void loop on exec reload of new self
      export SCRIPT_RESTART="1"
  fi
  ${BASE_CMD} chmod 555 "${SCRIPT_DIR}/${MY_NAME} "
  exec "${SCRIPT_DIR}/${MY_NAME}"
}

package_download() {
  echo -e "download/check package download\t"
  ${BASE_CMD} wget -q -N -P "$LOCAL_REPO_DIR" "$ZOOM_URL" && echo -e "done" || fail_exit 4
  cd ${LOCAL_REPO_DIR}
  #exit 0
  echo -e "create package repolist\t"
  #${BASE_CMD} tee Packages <(${BASE_CMD} apt-ftparchive packages zoom_amd64.deb) && echo -e "done" || fail_exit 5
  ${BASE_CMD} apt-ftparchive packages zoom_amd64.deb |${BASE_CMD} tee  Packages && echo -e "done" || fail_exit 5
  #${BASE_CMD} apt update
}

# Main function
main() {
  if [ -n "${SCRIPT_RESTART}" ]; then
    # we have reloaded after update, so just do the package download 
    package_download
  elif [ ! -f  "${LOCAL_REPO_DIR}" ]; then
    setup_config
    ${BASE_CMD} apt install zoom
  else
    # self update if needed
    script_download 
    package_download
  fi
}

# Run the main function
main

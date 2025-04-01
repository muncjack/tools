#!/bin/bash

# Configuration
MY_NAME="zoom_update_script.sh"
BASE_DIR="/opt/tools"
SCRIPT_DIR="${BASE_DIR}/scripts"
SCRIPT_MIRROR_DIR="${BASE_DIR}/mirror/zoom"
SCRIPT_URL="https://raw.githubusercontent.com/muncjack/tools/refs/heads/main/zoom/${MY_NAME}"
LOCAL_REPO_DIR="${BASE_DIR}/repo/zoom_repo"
REPO_LIST_FILE="/etc/apt/sources.list.d/zoom.sources"
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
  echo -en "Repository directory created \t"
  ${BASE_CMD} mkdir -p "$LOCAL_REPO_DIR" && echo -e "done" || fail_exit 1
  
  if [ ! -f "${GPG_KEY_FILE}" ]; then
      echo -en "adding Zoom GPG key\t" 
      wget -q -O - "$GPG_KEY_URL" |${BASE_CMD} gpg --dearmor -o ${GPG_KEY_FILE} &&
      echo -e "done" || fail_exit 2
  fi
  if [ ! -f "$REPO_LIST_FILE" ]; then
      echo -en "adding repo config to apt sources\t" 
      (
        echo "Types: deb"
        echo "URIs: file:$LOCAL_REPO_DIR"
        echo "Suites: ./"
        echo "#Components: ./"
        echo "Trusted: yes"
        echo "Signed-By: ${GPG_KEY_FILE}"
      )| ${BASE_CMD} tee "$REPO_LIST_FILE" > /dev/null && echo -e "done" || fail_exit 3
  fi
  if [ ! -f "${SCRIPT_DIR}/${MY_NAME}" ]; then
      echo -en "adding script dir\t" 
      ${BASE_CMD} mkdir -p "${SCRIPT_DIR}"  && echo -e "done" || fail_exit 1
      
      echo -en "adding script mirror dir\t" 
      ${BASE_CMD} mkdir -p "${SCRIPT_MIRROR_DIR}"  && echo -e "done" || fail_exit 1
      ${BASE_CMD} chown -R root:root ${BASE_DIR}
  fi
  script_download
  package_download
}

script_download() {
  echo -en "download script\t\t"
  ${BASE_CMD} wget -q -N -P "${SCRIPT_MIRROR_DIR}" "${SCRIPT_URL}" && echo -e "done" || fail_exit 1
  if [ "`sum -r ${SCRIPT_DIR}/.${MY_NAME}.new 2>/dev/null`" != "`sum -r ${SCRIPT_MIRROR_DIR}/${MY_NAME} 2>/dev/null`" ]; then
      # this is for currently runing process to not fail
      [ -f ${SCRIPT_MIRROR_DIR}/${MY_NAME} ] || ${BASE_CMD} mv -v "${SCRIPT_DIR}/${MY_NAME}" "${SCRIPT_DIR}/.${MY_NAME}.old"
      ${BASE_CMD} cp "${SCRIPT_MIRROR_DIR}/${MY_NAME}" "${SCRIPT_DIR}/${MY_NAME}"
      # set flag to void loop on exec reload of new self
      export SCRIPT_RESTART="1"
  fi
  ${BASE_CMD} chmod 555 "${SCRIPT_DIR}/${MY_NAME}"
  exec "${SCRIPT_DIR}/${MY_NAME}"
}

package_download() {
  BEFORE_SUM="`sum -r ${LOCAL_REPO_DIR}/zoom_amd64.deb` 2>/dev/null"
  echo -en "download/check package download\t"
  ${BASE_CMD} wget -q -N -P "$LOCAL_REPO_DIR" "$ZOOM_URL" && echo -e "done" || fail_exit 4
  if [ "${BEFORE_SUM}" != "`sum -r ${LOCAL_REPO_DIR}/zoom_amd64.deb`" ]; then
      cd ${LOCAL_REPO_DIR}
      #exit 0
      echo -en "(re)create Package file\t"
      #${BASE_CMD} apt-ftparchive packages zoom_amd64.deb |${BASE_CMD} tee Packages >/dev/null && echo -e "done" || fail_exit 5
      ${BASE_CMD} apt-ftparchive packages . |${BASE_CMD} tee Packages >/dev/null && echo -e "done" || fail_exit 5
      echo -en "(re)create Release file \t"
      ${BASE_CMD} apt-ftparchive release . | ${BASE_CMD} tee Release >/dev/null && echo -e "done" || fail_exit 6
      #${BASE_CMD} apt update
  fi 
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

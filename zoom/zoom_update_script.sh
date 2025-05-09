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
SETUP=0
SYSTEMD_APT_PRERUN_FILE=/etc/systemd/system/apt-daily.service.d/prerun-zoom.conf

if [ "${USER}" == "_apt" ]; then
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
  ${BASE_CMD} setfacl -R -m _apt:wr ${BASE_DIR}
  ${BASE_CMD} setfacl -R -d -m _apt:wr ${BASE_DIR}
  if [ ! -f "${GPG_KEY_FILE}" ]; then
      echo -en "adding Zoom GPG key\t" 
      wget -4 -q -O - "$GPG_KEY_URL" |${BASE_CMD} gpg --dearmor -o ${GPG_KEY_FILE} &&
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
      ${BASE_CMD} chown -R root:_apt ${BASE_DIR}
  fi
  if [ ! -f "${SYSTEMD_APT_PRERUN_FILE}" ]; then
    echo -en "systemd apt daily pre-run conf dir\t\t"
    ${BASE_CMD} mkdir `dirname "${SYSTEMD_APT_PRERUN_FILE}"` && echo -e "done" || fail_exit 11
    echo -en "systemd apt daily pre-run\t\t"
    echo -e "[Service]\nExecStartPre=${SCRIPT_DIR}/${MY_NAME}" | ${BASE_CMD} tee "${SYSTEMD_APT_PRERUN_FILE}" >/dev/null && echo -e "done" || fail_exit 10
    ${BASE_CMD} systemctl daemon-reload
  fi
  script_download
  package_download
}

uninstall(){
  echo -en "uninstall all the bit's\t\t\t"
  ${BASE_CMD} rm -rf opt/tools/scripts/zoom_update_script.sh /opt/tools/mirror/zoom/ /etc/systemd/system/apt-daily.service.d/prerun-zoom.conf /opt/tools/repo/zoom_repo/ && echo -e "done" || fail_exit 1
  exit 0
}

script_download() {
  if [ "${0}" == "bash" ]; then
      # install run 
      echo -en "install script\t\t"
      ${BASE_CMD} wget -4 -q -N -P "${SCRIPT_MIRROR_DIR}" "${SCRIPT_URL}" && echo -e "done" || fail_exit 1
      ${BASE_CMD} cp "${SCRIPT_MIRROR_DIR}/${MY_NAME}" "${SCRIPT_DIR}/${MY_NAME}"
      ${BASE_CMD} chmod 555 "${SCRIPT_DIR}/${MY_NAME}"
      ${BASE_CMD} setfacl -R -m _apt:wr ${BASE_DIR}
      ${BASE_CMD} setfacl -R -d -m _apt:wr ${BASE_DIR}
  elif [ "${0}" == "${SCRIPT_MIRROR_DIR}/${MY_NAME}" ]; then
      echo "New version install"
      ${BASE_CMD} setfacl -R -m _apt:wr ${BASE_DIR}
      ${BASE_CMD} setfacl -R -d -m _apt:wr ${BASE_DIR}
      ${BASE_CMD} cp "${SCRIPT_MIRROR_DIR}/${MY_NAME}" "${SCRIPT_DIR}/${MY_NAME}"
      ${BASE_CMD} chmod 555 "${SCRIPT_DIR}/${MY_NAME}"
      if [ ${SETUP} -ne 1 ]; then 
          echo "run new version"
          exec "${SCRIPT_DIR}/${MY_NAME}"
      fi      
  else
      echo -en "download/check script\t\t"
      ${BASE_CMD} wget -4 -q -N -P "${SCRIPT_MIRROR_DIR}" "${SCRIPT_URL}" && echo -e "done" || fail_exit 1
      SUM_NEW="`sum -r ${SCRIPT_DIR}/${MY_NAME} 2>/dev/null| sed -r -e 's/^([0-9]+\s+[0-9]+).*/\1/'`"
      SUM_CUR="`sum -r ${SCRIPT_MIRROR_DIR}/${MY_NAME} 2>/dev/null| sed -r -e 's/^([0-9]+\s+[0-9]+).*/\1/'`"
      # check if new version ....
      if [ "${SUM_NEW}" != "${SUM_CUR}" ]; then
          # this is for currently runing process to not fail
          [ -f ${SCRIPT_MIRROR_DIR}/${MY_NAME} ] || ${BASE_CMD} mv -v "${SCRIPT_DIR}/${MY_NAME}" "${SCRIPT_DIR}/.${MY_NAME}.old"
          exec bash "${SCRIPT_MIRROR_DIR}/${MY_NAME}"
      fi

  fi
}

package_download() {
  BEFORE_SUM="`sum -r ${LOCAL_REPO_DIR}/zoom_amd64.deb 2>/dev/null| sed -r -e 's/^([0-9]+\s+[0-9]+).*/\1/'`"
  echo -en "download/check package download\t"
  ${BASE_CMD} wget -4 -q -N -P "$LOCAL_REPO_DIR" "$ZOOM_URL" && echo -e "done" || fail_exit 4
  DOWNLOADED_SUM="`sum -r ${LOCAL_REPO_DIR}/zoom_amd64.deb 2>/dev/null| sed -r -e 's/^([0-9]+\s+[0-9]+).*/\1/'`"
  if [ "${BEFORE_SUM}" != "${DOWNLOADED_SUM}" ]; then
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
  if [ "$1" == "uninstall" ]; then
    uninstall
  elif [ "${0}" == "${SCRIPT_MIRROR_DIR}/${MY_NAME}" ]; then
    # we have reloaded after update, so just do the package download 
    echo "main() New/check version of script"
    package_download
  elif [ ! -d  "${LOCAL_REPO_DIR}" ]; then
    echo "main() new install"
    SETUP=1
    setup_config
    ${BASE_CMD} apt install zoom -y
  else
    echo "main() script and download"
    # self update if needed
    script_download 
    package_download
  fi
}

# Run the main function
main

#!/usr/bin/env bash

#=======================================================================#
# Copyright (C) 2020 - 2022 Dominik Willner <shilong.native@gmail.com>  #
#                                                                       #
# This file is part of KIAUH - Klipper Installation And Update Helper   #
# https://github.com/EchoHeim/kiauh                                     #
#                                                                       #
# This file may be distributed under the terms of the GNU GPLv3 license #
#=======================================================================#

set -e

#=================================================#
#=============== INSTALL Crowsnest ===============#
#=================================================#

function install_Crowsnest() {
  local crowsnest_cfg="${KIAUH_SRCDIR}/resources/crowsnest/crowsnest.conf"
  local crowsnest_service="${KIAUH_SRCDIR}/resources/crowsnest/crowsnest.service"

  local printer_data="${HOME}/printer_data"
  local cfg_dir="${printer_data}/config"

  local repo="https://github.com/mainsail-crew/crowsnest.git"

  ### return early if webcamd.service already exists
  if [[ -d "${HOME}/crowsnest" ]]; then
    print_error "Looks like Crowsnest is already installed!\n Please remove it first before you try to re-install it!"
    return
  fi

  status_msg "Initializing Crowsnest ..."

  ### step 1: clone Crowsnest
  status_msg "Cloning Crowsnest from ${repo} ..."
  [[ -d "${HOME}/crowsnest" ]] && rm -rf "${HOME}/crowsnest"

  cd "${HOME}" || exit 1
  if ! git clone "${repo}" ; then
    print_error "Cloning Crowsnest from\n ${repo}\n failed!"
    exit 1
  fi
  ok_msg "Cloning complete!"

  ### step 2: compiling Crowsnest
  status_msg "Compiling Crowsnest ..."
  cd "${HOME}/crowsnest"
  if ! sudo make install; then
    print_error "Compiling Crowsnest failed!"
    exit 1
  fi
  ok_msg "Compiling complete!"

  ### step 3: check if user is in group "video"
  local usergroup_changed="false"
  if ! groups "${USER}" | grep -q "video"; then
    status_msg "Adding user '${USER}' to group 'video' ..."
    sudo usermod -a -G video "${USER}" && ok_msg "Done!"
    usergroup_changed="true"
  fi

  ### step 4: create crowsnest config file
  [[ ! -d ${cfg_dir} ]] && mkdir -p "${cfg_dir}"
  [[ -f "${cfg_dir}/crowsnest.conf" ]] && rm -rf "${cfg_dir}/crowsnest.conf"

  status_msg "Creating crowsnest config file ..."
  cp ${crowsnest_cfg} ${cfg_dir}

  status_msg "Change crowsnest.service path ..."
  sudo sed -i 's/klipper_config/printer_data\/config/' /etc/systemd/system/crowsnest.service

  ok_msg "Done!"

  ### print webcam ip adress/url
  local ip
  ip=$(hostname -I | cut -d" " -f1)
  local cam_url="http://${ip}:8080/?action=stream"
  local cam_url_alt="http://${ip}/webcam/?action=stream"
  echo -e " ${cyan}● Webcam URL:${white} ${cam_url}"
  echo -e " ${cyan}● Webcam URL:${white} ${cam_url_alt}"
  echo
}

#=================================================#
#================ REMOVE Crowsnest ===============#
#=================================================#

function remove_Crowsnest() {
    local printer_data="${HOME}/printer_data"
    local cfg_dir="${printer_data}/config"

    if [[ -d "${HOME}/crowsnest" ]];then
        cd ~/crowsnest
        make uninstall
        [[ -d "${HOME}/crowsnest" ]] && rm -rf "${HOME}/crowsnest"
        [[ -e "${cfg_dir}/crowsnest.conf" ]] && rm -rf "${cfg_dir}/crowsnest.conf"
        print_confirm "Crowsnest successfully removed!"
    else
        print_confirm "Crowsnest not installed!"
    fi
}
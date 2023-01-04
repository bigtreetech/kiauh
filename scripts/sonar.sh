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
#=============== INSTALL Sonar ===============#
#=================================================#

function install_Sonar() {
  local sonar_cfg="${KIAUH_SRCDIR}/resources/mainsail-kits/sonar.conf"

  local printer_data="${HOME}/printer_data"
  local cfg_dir="${printer_data}/config"

  local repo="https://github.com/mainsail-crew/sonar.git"

  ### return early if sonar already exists
  if [[ -d "${HOME}/sonar" ]]; then
    print_error "Looks like Sonar is already installed!\n Please remove it first before you try to re-install it!"
    return
  fi

  status_msg "Initializing Sonar ..."

  ### step 1: clone Sonar
  status_msg "Cloning Sonar from ${repo} ..."
  [[ -d "${HOME}/sonar" ]] && rm -rf "${HOME}/sonar"

  cd "${HOME}" || exit 1
  if ! git clone "${repo}" ; then
    print_error "Cloning Sonar from\n ${repo}\n failed!"
    exit 1
  fi
  ok_msg "Cloning complete!"

  ### step 2: compiling Sonar
  status_msg "Compiling Sonar ..."
  cd "${HOME}/sonar"
  make config
  if ! sudo make install; then
    print_error "Compiling Sonar failed!"
    exit 1
  fi
  ok_msg "Compiling complete!"

  ### step 4: create sonar config file
  [[ ! -d ${cfg_dir} ]] && mkdir -p "${cfg_dir}"
  [[ -f "${cfg_dir}/sonar.conf" ]] && rm -rf "${cfg_dir}/sonar.conf"

  status_msg "Creating sonar config file ..."
  cp ${sonar_cfg} ${cfg_dir}

  ok_msg "Done!"
}

#=================================================#
#================ REMOVE Sonar ===============#
#=================================================#

function remove_Sonar() {
    local printer_data="${HOME}/printer_data"
    local cfg_dir="${printer_data}/config"

    if [[ -d "${HOME}/sonar" ]];then
        cd ~/sonar
        make uninstall
        [[ -d "${HOME}/sonar" ]] && rm -rf "${HOME}/sonar"
        [[ -e "${cfg_dir}/sonar.conf" ]] && rm -rf "${cfg_dir}/sonar.conf"
        print_confirm "Sonar successfully removed!"
    else
        print_confirm "Sonar not installed!"
    fi
}
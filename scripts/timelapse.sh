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
#=============== INSTALL Timelapse ===============#
#=================================================#

function install_Timelapse() {
  local timelapse_cfg="${KIAUH_SRCDIR}/resources/mainsail-kits/timelapse.cfg"

  local printer_data="${HOME}/printer_data"
  local cfg_dir="${printer_data}/config"

  local repo="https://github.com/mainsail-crew/moonraker-timelapse.git"

  ### return early if Timelapse already exists
  if [[ -d "${HOME}/moonraker-timelapse" ]]; then
    print_error "Looks like Moonraker-Timelapse is already installed!\n Please remove it first before you try to re-install it!"
    return
  fi

  status_msg "Initializing Moonraker-Timelapse ..."

  ### step 1: clone Timelapse
  status_msg "Cloning Timelapse from ${repo} ..."
  [[ -d "${HOME}/moonraker-timelapse" ]] && rm -rf "${HOME}/moonraker-timelapse"

  cd "${HOME}" || exit 1
  if ! git clone "${repo}" ; then
    print_error "Cloning Moonraker-Timelapse from\n ${repo}\n failed!"
    exit 1
  fi
  ok_msg "Cloning complete!"

  ### step 2: install Moonraker-Timelapse
  status_msg "Install moonraker-timelapse ..."
  bash ~/moonraker-timelapse/install.sh
  ok_msg "Compiling complete!"

  ### step 4: create Timelapse config file
  [[ ! -d ${cfg_dir} ]] && mkdir -p "${cfg_dir}"
  [[ -f "${cfg_dir}/timelapse.cfg" ]] && rm -rf "${cfg_dir}/timelapse.cfg"

  status_msg "Creating Timelapse config file ..."
  cp ${timelapse_cfg} ${cfg_dir}

  ok_msg "Done!"
}

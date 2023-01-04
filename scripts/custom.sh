LCF_SRC_DIR="${KIAUH_SRCDIR}/resources/custom"

function udisk_auto_mount() {
    sudo cp ${LCF_SRC_DIR}/usb/usb_udev.sh /etc/scripts
    sudo cp ${LCF_SRC_DIR}/usb/15-udev.rules /etc/udev/rules.d

    sudo sed -i 's/%user%/'''`whoami`'''/' /etc/scripts/usb_udev.sh

    if [ `grep -c "PrivateMounts=yes" "/usr/lib/systemd/system/systemd-udevd.service"` -eq '1' ];then
        sudo sed -i 's/PrivateMounts=yes/PrivateMounts=no/' /usr/lib/systemd/system/systemd-udevd.service
    elif [ `grep -c "PrivateMounts=no" "/usr/lib/systemd/system/systemd-udevd.service"` -eq '0' ];then
        sudo bash -c 'echo "PrivateMounts=no" >> /usr/lib/systemd/system/systemd-udevd.service'
    fi

    if [ `grep -c "MountFlags=shared" "/usr/lib/systemd/system/systemd-udevd.service"` -ne '1' ];then
        sudo bash -c 'echo "MountFlags=shared" >> /usr/lib/systemd/system/systemd-udevd.service'
    fi

    sync
    sudo systemctl daemon-reload
    sudo service systemd-udevd --full-restart

    print_confirm "Auto-mounting of u-disk is enabled!"
}

function fix_klipperscreen() {
    if [[ -e "/etc/X11/Xwrapper.config" && $(get_klipperscreen_status) == "Installed!" ]]; then
        # KlipperScreen display
        if [ `grep -c "allowed_users=anybody" "/etc/X11/Xwrapper.config"` -ne '1' ];then
            sudo bash -c 'echo "allowed_users=anybody" >> /etc/X11/Xwrapper.config'
        fi
        if [ `grep -c "needs_root_rights=yes" "/etc/X11/Xwrapper.config"` -ne '1' ];then
            sudo bash -c 'echo "needs_root_rights=yes" >> /etc/X11/Xwrapper.config'
        fi

        # KlipperScreen Chinese Fonts
        # sudo apt install fonts-arphic-bkai00mp fonts-arphic-bsmi00lp fonts-arphic-gbsn00lp fonts-arphic-gkai00mp fonts-arphic-ukai fonts-arphic-uming -y

        ok_msg "Reboot KlipperScreen!"
        sudo systemctl restart KlipperScreen.service

        print_confirm "KlipperScreen restoration complete!"
    else
        print_error "KlipperScreen not installed correctly!"
    fi
    sync
}

function mDNS_DependencyPackages() {
 # Many people prefer to access their machines using the name.
 # local addressing scheme available via mDNS (zeroconf, bonjour) instead of an IP address. 
 # This is simple to enable on the hurakan but requires the installation of 
 # the following packages which should be installed from the factory:
    sudo apt update

    sudo apt install avahi-daemon bind9-host geoip-database -y
    sudo apt install libavahi-common-data libavahi-common3 libavahi-core7 -y
    sudo apt install libdaemon0 libgeoip1 libnss-mdns libnss-mymachines -y

    print_confirm "mDNS service is installed!"
    sync
}

function config_klipper_cfgfile() {
    local printer_data="${HOME}/printer_data"
    local cfg_dir="${printer_data}/config"

    if [[ -d "${cfg_dir}" ]]; then
        case "$1" in
            "Hurakan")
                cp ${KIAUH_SRCDIR}/resources/custom/Hurakan/*.cfg ${cfg_dir} -f
                [[ ! -d ${cfg_dir}/Hurakan ]] && mkdir -p ${cfg_dir}/Hurakan
                cp ${KIAUH_SRCDIR}/resources/custom/Hurakan/Hurakan/* ${cfg_dir}/Hurakan -f 
                [[ ! -d ${cfg_dir}/.theme ]] && mkdir -p ${cfg_dir}/.theme
                cp ${KIAUH_SRCDIR}/resources/custom/Hurakan/theme/* ${cfg_dir}/.theme -f 
                ;;
        esac
        sync
        print_confirm "config_klipper_cfgfile OK"
    else
        print_error "No config directory found! Skipping Configure ..."
    fi
}

function config_klipper_host_MCU() {
    if [[ -d "${HOME}/klipper" && $(get_klipper_status) != "Not installed!" && $(get_klipper_status) != "Incomplete!" ]]; then
        cd ~/klipper/

        cp ${KIAUH_SRCDIR}/resources/custom/.config ~/klipper/
        make

        sudo service klipper stop
        make flash
        sudo service klipper start

        sudo usermod -a -G tty `whoami`

        print_confirm "config_klipper_host_MCU OK"
    else
        print_error "Klipper not installed correctly!"
    fi
    sync
}

function Create_can0_cfg() {
    # Reference: https://www.klipper3d.org/CANBUS.html#host-hardware

    cd ~
    touch can0

    cat <<-EOF > can0
	allow-hotplug can0
	iface can0 can static
	    bitrate 1000000
	    up ifconfig \$IFACE txqueuelen 1024
	EOF

    cd /etc/network/interfaces.d
    [[ -f can0 ]] && sudo rm -rf can0
    sudo mv ~/can0 ./

    sync
    print_confirm "Create can0 configuration file OK"
}

function config_shaper_auto_calibration() {
    status_msg "Installing dependency packages..."

    sudo apt update
    sudo apt install python3-numpy python3-matplotlib libatlas-base-dev -y

    status_msg "Installing NumPy..."
    ~/klippy-env/bin/pip install -v numpy

    sync
    print_confirm "config_shaper_auto_calibration OK"
}

function OS_clean() {
    local printer_data="${HOME}/printer_data"
    local cfg_dir="${printer_data}/config"
    local log_dir="${printer_data}/logs"

    cd ~

    status_msg "Delete klipper logs..."
    [[ ! "`ls -A ${log_dir}`" = "" ]] && rm ${log_dir}/*
    sync
    ok_msg "Done!"

    # Reference: https://blog.csdn.net/weixin_39534395/article/details/119229057
    status_msg "Cancel SSH timeout disconnection..."

    if [ `grep -c "#TCPKeepAlive yes" "/etc/ssh/sshd_config"` -eq '1' ];then
        sudo sed -i 's/#TCPKeepAlive yes/TCPKeepAlive yes/' /etc/ssh/sshd_config
    elif [ `grep -c "TCPKeepAlive yes" "/etc/ssh/sshd_config"` -eq '0' ];then
        sudo bash -c 'echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config'
    fi

    if [ `grep -c "#ClientAliveInterval 0" "/etc/ssh/sshd_config"` -eq '1' ];then
        sudo sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 360/' /etc/ssh/sshd_config
    elif [ `grep -c "ClientAliveInterval 360" "/etc/ssh/sshd_config"` -eq '0' ];then
        sudo bash -c 'echo "ClientAliveInterval 360" >> /etc/ssh/sshd_config'
    fi

    if [ `grep -c "#ClientAliveCountMax 3" "/etc/ssh/sshd_config"` -eq '1' ];then
        sudo sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 20/' /etc/ssh/sshd_config
    elif [ `grep -c "ClientAliveCountMax 20" "/etc/ssh/sshd_config"` -eq '0' ];then
        sudo bash -c 'echo "ClientAliveCountMax 20" >> /etc/ssh/sshd_config'
    fi
    ok_msg "Done!"

    # ------------------------------------------------ #
    status_msg "klipper clears the compilation history..."
    cd ~/klipper
    make clean
    ok_msg "Done!"

    status_msg "Delete wifi history connection ..."
    cd /etc/NetworkManager/system-connections
    [[ ! "`ls -A ./`" = "" ]] && sudo rm ./*
    sync
    ok_msg "Done!"

    status_msg "Remove git proxy..."
    cd ~
    [[ -f .gitconfig ]] && rm -rf .gitconfig
    ok_msg "Done!"

    status_msg "Clear shell history command file..."
    cd ~
    [[ -f .bash_history ]] && rm -rf .bash_history
    [[ -f .zsh_history ]] && rm -rf .zsh_history
    [[ -f .kiauh.ini ]] && rm -rf .kiauh.ini
    ok_msg "Done!"
    echo ""

    warn_msg "You need to run the following command to clear the history cmd:"
    warn_msg "source ${KIAUH_SRCDIR}/OS_bash_clean.sh"
    echo ""

    print_confirm " This kiauh script will exit!"
    sleep 3
    exit 0
}

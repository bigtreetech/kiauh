function detect_pack() {
    for pkg in "${dep_pkg[@]}"
    do
        if [[ ! $(dpkg-query -f'${Status}' --show $pkg 2>/dev/null) = *\ installed ]]; then
            # echo "$pkg Uninstalled!"
            inst_pkg+=($pkg)
        fi
    done
}

function WhetherInstall(){
    if [ "${#inst_pkg[@]}" != "0" ]; then
        echo -e "\nChecking for the following dependencies:\n"
        for pkg in "${inst_pkg[@]}"
        do
            echo -e "${cyan}● $pkg ${default}"
        done
        echo -e "\n"

        read -p "${cyan}###### Installing the above packages? (Y/n):${default} " yn
        case "$yn" in
            Y|y|Yes|yes|"")
                echo
                sudo apt-get update --allow-releaseinfo-change && sudo apt install ${inst_pkg[@]} -y
                echo -e "\nDependencies installed!"
                ;;

            N|n|No|no)
                exit 0;;
        esac
    fi
    unset inst_pkg
}

#-----------------------------------------------------------------------------------

function custom_function_ui(){
    top_border
    echo -e "|     ${green}~~~~~~~~~ [ Custom Function Menu ] ~~~~~~~~~~${white}     | "
    hr
    echo -e "| Machine Config:          | Add-on Features:           |"
    echo -e "|                          |                            |"
    echo -e "| s) [SKR-3]               | 1) [fix KlipperScreen]     |"
    echo -e "|                          | 2) [Host MCU]              |"
    echo -e "| h) [Hurakan]             | 3) [Measuring Resonances]  |"
    echo -e "|                          | 4) [U-disk Automount]      |"
    echo -e "| m) [STM32MP157]          | 5) [Install mDNS service]  |"
    echo -e "|                          | 6) [add CAN file]          |"
    echo -e "|                          |                            |"
    hr
    echo -e "|  c) Cleanup System                                    |"
    back_footer
}

function custom_function_menu(){
    dep_pkg=(git tofrodos)
    detect_pack
    WhetherInstall
    unset dep_pkg

    do_action "" "custom_function_ui"
    while true; do
        read -p "${cyan}Perform action:${white} " action; echo
        case "$action" in
            1) 
                do_action "fix_klipperscreen" "custom_function_ui";;
            2) 
                do_action "config_klipper_host_MCU" "custom_function_ui";;
            3) 
                do_action "config_shaper_auto_calibration" "custom_function_ui";;
            4) 
                do_action "udisk_auto_mount" "custom_function_ui";;
            5) 
                do_action "mDNS_DependencyPackages" "custom_function_ui";;
            6) 
                do_action "Create_can0_cfg" "custom_function_ui";;

            S|s)
                do_action "config_klipper_cfgfile skr3" "custom_function_ui";;
            H|h) 
                do_action "config_klipper_cfgfile Hurakan" "custom_function_ui";;
            M|m) 
                do_action "config_klipper_cfgfile stm32mp157" "custom_function_ui";;

            C|c)
                do_action "OS_clean" "custom_function_ui";;

            B|b)
                clear; main_menu; break;;
            *)
                deny_action "custom_function_ui";;
        esac
    done
    custom_function_ui
}

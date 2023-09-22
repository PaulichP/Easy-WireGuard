#!/bin/bash

BOLD=$(tput bold)
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)

is_valid_ip() {
    local ip="$1"
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

get_host_ip() {
    local host_ip=""
    while true; do
        host_ip=$(curl -s https://ipinfo.io/ip)
        if is_valid_ip "$host_ip"; then
            echo "Detected host IP address: ${GREEN}$host_ip${NORMAL}"
            read -p "Is this the correct host IP address? (yes, no, quit): " confirm
            case "$confirm" in
            "yes" | "y" | "Y")
                hostip="$host_ip"
                return 0
                ;;
            "no" | "n" | "N")
                read -p "Please enter the correct host IP address: " host_ip
                if is_valid_ip "$host_ip"; then
                    hostip="$host_ip"
                    echo "Host IP address set to: ${GREEN}$host_ip${NORMAL}"
                    return 0
                else
                    echo "${RED}Invalid IP address entered.${NORMAL}"
                fi
                ;;
            "quit" | "q" | "Q")
                return 1
                ;;
            *)
                echo "${RED}Invalid choice. Please enter 'yes', 'no', or 'quit'.${NORMAL}"
                ;;
            esac
        else
            echo "${RED}Failed to automatically detect host IP address.${NORMAL}"
            read -p "Please enter the host IP address: " host_ip
            if is_valid_ip "$host_ip"; then
                hostip="$host_ip"
                echo "Host IP address set to: ${GREEN}$host_ip${NORMAL}"
                return 0
            else
                echo "${RED}Invalid IP address entered.${NORMAL}"
            fi
        fi
    done
}

display_section_header() {
    local section_title="$1"
    echo ""
    echo "===================================================================="
    echo "${BOLD}$section_title${NORMAL}"
    echo "===================================================================="
}

echo "${BOLD}"
echo "███████╗██╗░░░░██╗░██████╗"
echo "██╔════╝██║░░░░██║██╔════╝ "
echo "█████╗░░██║░█╗░██║██║░░███╗"
echo "██╔══╝░░██║███╗██║██║░░░██║"
echo "███████╗╚███╔███╔╝╚██████╔╝"
echo "╚══════╝░╚══╝╚══╝░░╚═════╝ "
echo ""
echo "    ${GREEN}v1.1${NORMAL} by PaulichP"
echo "${NORMAL}"

display_section_header "Host IP Address"
if get_host_ip; then
    :
else
    echo "Installation aborted."
    exit 1
fi

display_section_header "Admin Password"
echo ""
read -s -p "Enter your admin password for the web panel: " admpass
echo ""

display_section_header "Web Panel Selection"
PS3='Please enter your choice: '
options=("wg-easy" "wg-access-server" "Quit")
select opt in "${options[@]}"; do
    case $opt in
    "wg-easy")
        docker run -d \
            --name=wg-easy \
            -e WG_HOST=$hostip \
            -e PASSWORD=$admpass \
            -v ~/.wg-easy:/etc/wireguard \
            -p 51820:51820/udp \
            -p 51821:51821/tcp \
            --cap-add=NET_ADMIN \
            --cap-add=SYS_MODULE \
            --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
            --sysctl="net.ipv4.ip_forward=1" \
            --restart unless-stopped \
            weejewel/wg-easy
        display_section_header "Installation Completed"
        echo "Installation completed successfully!"
        echo ""
        echo "Here's the link to your web panel:"
        echo "http://$hostip:51821"
        echo ""
        echo "Your admin password is: $admpass"
        break
        ;;
    "wg-access-server")
        echo "${BLUE}IMPORTANT! Please press ctrl+c after INFO[0000] will come up.${NORMAL}"
        sleep 2
        export WG_ADMIN_PASSWORD=$admpass
        export WG_WIREGUARD_PRIVATE_KEY="$(wg genkey)"
        docker run \
            -it \
            --cap-add NET_ADMIN \
            --cap-add SYS_MODULE \
            --device /dev/net/tun:/dev/net/tun \
            --sysctl net.ipv6.conf.all.disable_ipv6=0 \
            --sysctl net.ipv6.conf.all.forwarding=1 \
            -v wg-access-server-data:/data \
            -v /lib/modules:/lib/modules:ro \
            -e "WG_ADMIN_PASSWORD=$WG_ADMIN_PASSWORD" \
            -e "WG_WIREGUARD_PRIVATE_KEY=$WG_WIREGUARD_PRIVATE_KEY" \
            -p 8000:8000/tcp \
            -p 51820:51820/udp \
            --restart unless-stopped \
            ghcr.io/freifunkmuc/wg-access-server:latest
        display_section_header "Installation Completed"
        echo "Installation completed successfully!"
        echo ""
        echo "Here's the link to your web panel:"
        echo "http://$hostip:51821"
        echo ""
        echo "Your username is: admin"
        echo "Your admin password is: $admpass"
        break
        ;;
    "Quit")
        break
        ;;
    *)
        echo "Invalid option $REPLY"
        ;;
    esac
done

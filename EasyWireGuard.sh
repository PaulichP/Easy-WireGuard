#!/bin/bash
echo " "
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@               Welcome to Easy WireGuard!               @"
echo "@                         v1.0.0                         @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo " "
read -r -p "Do you have Docker installed? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        echo "Nice, let's start!"
        ;;
    *)
        echo "No problem, we can do the installation for you."
        sleep 2
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        echo "Now we can start!"
esac
echo " "
echo "Please, eneter your host IP adress:"
read hostip
echo "Perfect! Please, enter your admin password for web panel:"
read admpass
echo "Alright, now select which web panel you want to install:"
PS3='Please enter your choice: '
options=("wg-easy" "wg-access-server" "Quit")
select opt in "${options[@]}"
do
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
             echo " "
             echo "All Done!"
             echo " "
             echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
             echo "                                                         "
             echo "  Here's the link to your web panel:                     "
             echo "  http://"$hostip":51821                                 "
             echo "                                                         "
             echo "  Your admin password is:                                "
             echo "  $admpass                                               "
             echo "                                                         "
             echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            break
            ;;
        "wg-access-server")
            echo "IMPORTANT! Please press ctrl+c after INFO[0000] will come up."
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
            docker restart $(docker ps -a -q)
            echo " "
            echo "All Done!" 
	    echo " "
            echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            echo "                                                          "
            echo "  Here's the link to your web panel:                      "
            echo "  http://"$hostip":51821                                  "
            echo "                                                          "
            echo "  Your username is:                                       "
            echo "  admin                                                   "
            echo "                                                          "
	    echo "  Your admin password is:                                 "
            echo "  $admpass                                                "
	    eсho "                                                          "
	    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

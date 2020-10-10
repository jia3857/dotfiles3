sudo openconnect connect.${COMPANY:-"google.com"} -u $USER

setup_vpn_routing() {
    iptables --flush            # Flush all the rules in filter and nat tables
    iptables --table nat --flush
    iptables --delete-chain
    iptables --table nat --delete-chain

    #
    IN_INT=eth0
    OUT_INT=tun0
    #iptables --table nat --append POSTROUTING --out-interface eth0 -j MASQUERADE
    #iptables --append FORWARD --in-interface eth1 -j ACCEPT
    iptables --table nat --append POSTROUTING --out-interface ${IN_INT} -j MASQUERADE
    iptables --append FORWARD --in-interface ${OUT_INT} -j ACCEPT
    echo 1 > /proc/sys/net/ipv4/ip_forward
    service iptables restart
}

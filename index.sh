#!/bin/bash

#Global variables
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"
selectedIface=""
setIps=('192.168.0.253' '172.16.0.253' '10.0.0.253' '3.3.3.253')
setNetmask='255.255.0.0'

    # Helpanel
    if [[ $1 ]] && [[ "$1" == "-h" ]] ; then
        echo -e "${yellowColour}\n[+] <<============ Ayuda ============>>${endColour}\n"
        echo -e "${yellowColour}\t${blueColour}*${yellowColour} Para utilizar diferentes ip y rangos, modificar el array de ips al principio del script ${endColour}\n"
        echo -e "${yellowColour}\t${blueColour}*${yellowColour} Tener en cuenta que si la ip esta ocupada por un dispositivo el reconocimiento en el segmento fallará. ${endColour}"
        echo -e "${yellowColour}\t  En ese caso probar en el mismo rango otra ip diferente${endColour}\n"
        exit 0
    fi
    #Are you root?
    if [[ "$(whoami)" != "root" ]]; then
        echo -e "${redColour}\n[!] Are you root${endColour}\n"
        exit 1
    fi
    #Validate moreutils
    if [[ "$(which sponge )" != "/usr/bin/sponge" ]]; then
        echo -e "${redColour}\n[!] Necesita instalar  el paquete moreutils${endColour}"
        echo -e "${yellowColour}\n\t[+] apt install moreutils${endColour}\n"
        exit 1
    fi
    #Validate batcat
    if [[ "$(which batcat )" != "/usr/bin/batcat" ]] && [[ "$(which bat )" != "/usr/bin/bat" ]]; then
        echo -e "${redColour}\n[!] Necesita instalar  el paquete batcat${endColour}"
        echo -e "${yellowColour}\n\t[+] apt install batcat${endColour}\n"
        exit 1
    fi
    #Validate arp-scan
    if [[ "$(which arp-scan )" != "/usr/sbin/arp-scan" ]] ; then
        echo -e "${redColour}\n[!] Necesita instalar  el paquete arp-scan${endColour}"
        echo -e "${yellowColour}\n\t[+] apt install arp-scan${endColour}\n"
        exit 1
    fi


    #ctrl_c
    function ctrl_c(){
        echo -e "\n${redColour} [!] Saliendo... ${endColour}\n"
        removeAdapters
        exit 1
    }
    trap ctrl_c INT

    #Clear subinterfaces
    function removeAdapters(){
        for i in $(seq 0 $((${#setIps[@]}-1))); do
            ifconfig $selectedIface:$i down &>/dev/null
        done
    }
    #Generate a netmask based in user input CIDR
    function cdr2mask(){
        set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
        [ $1 -gt 1 ] && shift $1 || shift
        echo ${1-0}.${2-0}.${3-0}.${4-0}
    }
    #Select listed interfaces function
    function selectIface(){

        base_ifaces=$(ifconfig | grep "flags" | grep -v "LOOPBACK" | cut -d ":" -f1)
        
        listed_ifaces=$(echo -e "$base_ifaces" | while read line; do
            echo -e "\t${greenColour} $line ${endColour}"
        done)

        echo -e "\n${blueColour}[+]Interfaces disponibles ${endColour}"
        echo "$listed_ifaces"
        echo -e "\n${blueColour}[+]Selecciona una interfaz para crear subinterfaces en distintas redes: ${endColour}"

        read selectedIface

        echo "$base_ifaces" | grep  $selectedIface
        if [[ $? -ne 0 ]]; then
            echo -e "\n${redColour}[!]Interfáz inválida ${endColour}"
            removeAdapters
            exit 1
        else
            clear
            echo -e "\n${greenColour}[+]Interfáz ${blueColour}$selectedIface${greenColour} seleccionada! ${endColour}"
            sleep 1
            clear
        fi
    }
    #Select netmask function
    function selectNetmask(){

        echo -e "\n${blueColour}[+] CIDR ${redColour}(Prefijos recomendados) ${endColour}"
        echo -e "\n\t${yellowColour} ${redColour}\24${yellowColour} --> 254 hosts por subred${endColour}"
        echo -e "\n\t${yellowColour} ${redColour}\16${yellowColour} --> 69534 hosts por subred (Recomendada)${endColour}"
        echo -e "\n\t${yellowColour} ${redColour}\8 ${yellowColour} -->  16777214 hosts por subred (Escaneo extenso)${endColour}"
        echo -e "\n${blueColour}[+] Ingrese un CIDR válido ${redColour}(Entre 1 y 32)${endColour}${blueColour} y presione ENTER${endColour}"
        read prefix

        if [[ $prefix -gt 0 ]] && [[ $prefix -le 32 ]]; then
            setNetmask=$(cdr2mask $prefix)
        else
            echo -e "\n${redColour}[!]Prefijo inválido${endColour}"
            exit 1
        fi
    }

    #Functión to generate subinterface based in recived params
    function netConfig(){
        iface=$1
        ip=$2
        netmask=$3
        ifconfig $selectedIface:$iface $ip netmask $netmask
        ifconfig $selectedIface:$iface up
        analyze $iface $ip $netmask
    }
    #Function to validate an created interface and make arp-scan in ip network segment
    function analyze(){
        ip=$(ifconfig | grep -C 1 "$selectedIface:$1" | grep inet | awk '{print $2}' )
        netmask=$(ifconfig | grep -C 1 "$selectedIface:$1" | grep inet | awk '{print $4}')
        cidr=$(ip addr | grep -C 1 "$selectedIface:$1" | grep inet | awk '{print $2}' | awk '{print $2}' FS='/') 
        networkId=$(cat /proc/net/fib_trie | grep -B 3 $ip | grep -vE '\+--|UNICAST|host' | sort -u | awk '{print $2}' | head -n 1)

        if [[ "$ip" == "$2" ]] && [[ "$netmask" == "$3" ]]; then 
            echo -e "\n[+] ${greenColour}$selectedIface:$1${endColour} up Iniciando reconocimiento de rango ${purpleColour} $networkId ${redColour}/$cidr${purpleColour} $broadcast ${endColour}\n"
            (/usr/sbin/arp-scan -I "$selectedIface:$1" -t 1 --localnet --ignoredups >> ./escaneo.txt) &
            sleep 2

        else 
            echo -e "\n${redColour}[!] Error no se pudo crear la subinterfaz ${endColour}\n"
            removeAdapters
        exit 1 
        fi
    }
    #Main function
    function main(){

        removeAdapters
        selectIface
        selectNetmask
        rm ./escaneo.txt &>/dev/null
        clear
        echo -e "\n${redColour}[!] ${yellowColour} Aguarde ..${endColour}\n"
        sleep 3

        clear
        for i in $(seq 0 $((${#setIps[@]}-1)) ); do
            netConfig $i ${setIps[$i]} $setNetmask
        done 2>/dev/null
        sleep 2


        clear
        echo -e "\n${redColour}[!]${yellowColour} Analizando posibles subredes, esto va a demorar... ${endColour}\n"
        wait
        sleep 2
        clear
        echo -e "\n${blueColour}[+]${greenColour}Presione una tecla para continuar${endColour}\n"
        read
        
        removeAdapters

        cat ./escaneo.txt | grep -vE 'Starting|Ending|kernel|filter' | sponge ./escaneo.txt
        /usr/bin/batcat -l java ./escaneo.txt  2>/dev/null
        if [[ $? -ne 0 ]]; then
        /usr/bin/bat -l java ./escaneo.txt  2>/dev/null
        fi 

    }

    (main ) 2>/dev/null

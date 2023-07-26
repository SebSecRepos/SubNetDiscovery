# SubNetDiscovery


> Esta herramienta fue creada para poder buscar segmentos de red desconocidos dentro de una red LAN o VLAN.
> Funciona creando multiples subinterfaces de red tomando como base un adaptador de red que seleccionemos, a cada subinterfaz se le asigna como ip
> una de las direcciones dentro de un array de ips declarado al principio del script, cada una de estas ips pertenece a un rango diferente de ips, los rangos colocados en el array corresponden a los segmentos comunmente mas utilizados de ip, claro se pueden modificar y agregar diferentes ip.
> Luego a todas las subinterfaces se le asigna la misma máscara de red que seleccionemos al ingresar el CIDR, se recomienda /16.

![1](https://github.com/SebSecRepos/SubNetDiscovery/assets/130188315/383d3cd9-c8e2-4a5e-94b3-4b5b0535ae94)
![2](https://github.com/SebSecRepos/SubNetDiscovery/assets/130188315/d4aac223-7689-44e2-9e18-0d0df21359e5)
![3](https://github.com/SebSecRepos/SubNetDiscovery/assets/130188315/9c7f4030-7271-4703-8f00-9208135ac10d)
![Captura de pantalla_área-de-selección_20230726181245](https://github.com/SebSecRepos/SubNetDiscovery/assets/130188315/109a7b74-cfb9-407e-ae6b-816694f517c9)

## A tener en cuenta

> Si la ip asignada a la subinterfaz esta siendo utilizada por un equipo activo dentro del segmento de red que va a escanear el script, el escaneo fallará en dicho segmento, en el caso de fallar en un rango de ips muy comunmente utilizado como 192.168.x.x, modificar el array de ips colocándole una ip diferente pero en el mismo rango
> Mientras mas grande la máscara de subred mas demorará el escaneo

## Requerimientos
- batcat
- moreutils
- arp-scan
  
## Descargar la herramienta
```bash
	git clone https://github.com/SebSecRepos/SubNetDiscovery.git
```

## Uso
``` bash
	sudo ./index.sh

	sudo ./index.sh -h  #Ayuda
```

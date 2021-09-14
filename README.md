# VPC Auto Escalamiento :chart_with_upwards_trend::arrow_double_up:
Con *Auto Scale for VPC* puede crear un grupo de instancias para escalar según sus necesidades. En función de las métricas de utilización objetivo que defina, el grupo de instancias puede añadir o eliminar instancias de forma dinámica para lograr la disponibilidad de instancias especificada.

Siguiendo las instrucciones de esta guía se aprovisionarán los siguientes recursos:

- VPC
- Subnets - una en cada zona (zone 1 and zone 2)
- VSIs - Dependiendo de la cantidad de carga de la aplicación
- Load balancer (backend pool and frontend listener)
- Instance group  
- Instance template

Dichos recursos serán aprovisionados por medio de *IBM® Cloud Schematics*, una vez sean implementados, se realizará una prueba de esfuerzo para observar el autoescalamiento en el grupo de instancias.

<p align="center">
<img width="500" alt="autoscale" src=https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/vpc-autoscale.png>
</p>

## Índice  📰
1. [Pre-Requisitos](#Pre-Requisitos-pencil)
2. [Crear y configurar un espacio de trabajo en IBM Cloud Schematics](#Crear-y-configurar-un-espacio-de-trabajo-en-IBM-Cloud-Schematics-bookmark_tabs)
3. [Configurar las variables de personalización de la plantilla de terraform](#Configurar-las-variables-de-personalización-de-la-plantilla-de-terraform-memo)
4. [Generar y aplicar el plan de despliegue de los servidores VPC](#Generar-y-aplicar-el-plan-de-despliegue-de-los-servidores-VPC-white_check_mark)
5. [Obtener IP pública del load balancer y solicitud HTTP](#Obtener-IP-pública-del-load-balancer-y-solicitud-HTTP-mag)
6. [Prueba de esfuerzo para generar el autoescalamiento](#Prueba-de-esfuerzo-para-generar-el-autoescalamiento-muscle)
7. [Programar el autoescalamiento](#Programar-el-autoescalamiento-alarm_clock)
8. [Referencias](#Referencias-mag)
9. [Autores](#Autores-black_nib)
<br />


## Pre Requisitos :pencil:
* Contar con una cuenta en <a href="https://cloud.ibm.com/"> IBM Cloud</a>.
* Contar con un grupo de recursos específico para el despliegue de los recursos
* Contar con una llave ssh configurada en IBM Cloud - referencia [VPC SSH documentation](https://github.com/emeloibmco/VPC-Despliegue-VSI-Acceso-SSH#Configurar-claves-SSH-closed_lock_with_key)
* Tener descargado <a href="https://jmeter.apache.org/download_jmeter.cgi">Apache JMeter</a> en caso de realizar la prueba de esfuerzo con esta herramienta. Esta aplicación se basa en Java, por lo tanto, asegúrese de tener instalado el Java Runtime en su computador para poder ejecutar el JMeter.
<br />

## Crear y configurar un espacio de trabajo en IBM Cloud Schematics :bookmark_tabs:
Dirijase al servicio de <a href="https://cloud.ibm.com/schematics/workspaces">IBM Cloud Schematics</a> y de click en ```Crear espacio de trabajo / Create workspace```, una vez hecho esto aparecera una ventana en la que debera diligenciar la siguiente información.

| Variable | Descripción |
| ------------- | ------------- |
| URL del repositorio de GitHub  | https://github.com/emeloibmco/VPC-Auto-Escalamiento |
| Tocken de acceso  | "(Opcional) Este parametro solo es necesario para trabajar con repositorio privados"  |
| Version de Terraform | terraform_v0.14 |

Presione ```Siguiente / Next```. Posteriormente complete lo siguiente:
* ```Nombre```: Agregue un nombre para el espacio de trabajo.
* ```Grupo de recursos```: Seleccione el grupo de recursos al que tiene acceso.
* ```Ubicación```: Seleccione una ubicacion para el espacio de trabajo. Recuerde que la ubicación determina dónde se ejecutarán las acciones del espacio de trabajo y no donde se desplegarán los recursos.
* ```Descripción```: Opcionalmente puede dar una descripción del proyecto. 

Una vez completos todos los campos puede presionar la opcion ```Crear / Create```.
<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/schematics.gif"></p>
<br />

## Configurar las variables de personalización de la plantilla de terraform :memo:
Una vez  creado el espacio de trabajo, podra ver el campo ```Variables``` que permite personalizar el espacio de trabajo. Allí ingrese los siguientes campos:

* ```resource_group_name```: Ingrese el nombre del grupo de recursos en el cual tiene permisos y donde quedaran agrupados todos los recursos que se aprovisionaran.
* ```vpc_name```: Ingrese el nombre que tendra el recurso de VPC en IBM Cloud.
* ```basename```: Ingrese el prefijo de nombre que tendran los recursos a desplegar dentro de la VPC.
* ```region```: Ingrese el nombre de la ubicación, en caso de que requiera una diferente a la por defecto ```jp-osa```.


| Name | Display Name |
| ------------- | :---: |
| au-syd        | Sydney          |     
| in-che        | Chennai         |     
| jp-osa        | Osaka           |     
| jp-tok        | Tokyo           |     
| kr-seo        | Seoul           |     
| eu-de         | Frankfurt       | 
| eu-gb         | London          | 
| ca-tor        | Toronto         |     
| us-south      | Dallas          | 
| us-south-test | Dallas Test     |
| us-east       | Washington DC   |
| br-sao        | Sao Paulo       |

* ```ssh_keyname```: Nombre del ssh key que tendrán las instancias de computo en el template, la cual aprovisono previamente. Recuerde que debe estar aprovisionada en la misma ubicación que escogio en la variable anterior.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/variables.gif"></p>
<br />

## Generar y aplicar el plan de despliegue de los servidores VPC :white_check_mark:
Ya que estan todos los campos de personalización completos, debe ir hasta la parte superior de la ventana donde encontrará dos opciones, ```Generar plan``` y ```Aplicar plan```. Para continuar con el despliegue de los recursos debera presionar ```Generar Plan``` y una vez termine de generarse el plan ```Aplicar Plan```.

* ```Generar plan```: Según su configuración, Terraform crea un plan de ejecución y describe las acciones que deben ejecutarse para llegar al estado que se describe en sus archivos de configuración de Terraform. Para determinar las acciones, Schematics analiza los recursos que ya están aprovisionados en su cuenta de IBM Cloud para brindarle una vista previa de si los recursos deben agregarse, modificarse o eliminarse. Puede revisar el plan de ejecución, cambiarlo o simplemente ejecutar el plan.

Asegurese de que el proceso se complete con éxito.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/generate.gif"></p>
<br />

* ```Aplicar plan```: Cuando esté listo para realizar cambios en su entorno de nube, puede aplicar sus archivos de configuración de Terraform. Para ejecutar las acciones que se especifican en sus archivos de configuración, Schematics utiliza el complemento *IBM Cloud Provider* para Terraform.

A medida que se aplique el plan, se crearán los distintos recursos, los cuales puede ir observando en la lista de recursos de su cuenta. Puede reconocerlos por el ```basename``` especificado previamente. Asegurese de que el proceso se complete con éxito.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/apply.gif"></p>
<br />

## Obtener IP del load balancer y solicitud HTTP :mag:

1. Dirijase al servicio de <a href="https://cloud.ibm.com/vpc-ext/network/loadBalancers">Load Balancer</a> y de click en el Load Balancer desplegado.
2. En ```IPs``` guarde cualquiera de las IP.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/ip.gif"></p>
<br />

3. Coloque la siguiente URL en la barra de navegación ```http://IP pública/?n=X```, ```X``` es el número hasta donde la aplicación calculará el número de primos, asi que si X= 20000 deberá visualizar lo que se muestra en la imagen.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/servidor.PNG"></p>
<br />

## Prueba de esfuerzo para generar el autoescalamiento :muscle:

Para realizar la prueba de esfuerzo se utiliza la herramienta JMeter, a través de la cual se envian un número determinado de peticiones al servidor en un tiempo determinado, de tal manera que se logre estresar a más del 10% la CPU de la instancia aprovisionada y el grupo de instancias autoescale. 

### Uso de JMeter
Siga estos pasos para realizar la prueba de esfuerzo:

1. Ejecute el JMeter (Se encuentra en carpeta ```bin```, con extensión ```.bat``` para Windows y/o ```.sh``` para Linux / MaC).

2. Cuando cargue el programa, observará que lo primero que aparece es un ```Test Plan```. Deje en todos los campos los valores que salen por defecto.

3. De click derecho sobre el ```Test Plan``` y seleccione ➡ ```Add``` ➡ ```Threads (Users)``` ➡ ```Thread Group```.

4. En el ```Thread Group``` indique la cantidad de usuarios que desean realizar las solicitudes HTTP y el tiempo deseado. Por ejemplo utilice: ```Users: 5000``` y ```Seconds: 360```.

5. Posteriormente, de click derecho sobre ```Thread Group``` ➡ ```Add``` ➡ ```Sampler``` ➡ ```HTTP Request```.

6. En el ```HTTP Request``` complete los campos:
   * ```Protocol[http]```: para este caso de ejemplo coloque ```http```.
   * ```Server Name or IP```: coloque la IP de Load Balancer. Por ejemplo: ```163.68.92.105```.
   * ```Port Number```: indique el puerto en caso de ser necesario. 
   * ```Path```: coloque la ruta en caso de ser necesaria. Por ejemplo: ```/?n=20000```

7. De click derecho sobre ```HTTP Request``` ➡ ```Add``` ➡ ```Listener``` ➡ ```View Results Tree```.

8. Para finalizar de click en la pestaña ```Run``` ➡ ```Start``` y espere mientras se completan las solicitudes HTTP.

<p align="center"><img width="900" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/FinalJMeterAutoescalamiento.gif"></p>
<br />

### Visualización del autoescalamiento en la consola 
1. Dirijase a <a href="https://cloud.ibm.com/vpc-ext/autoscale/groups">Grupos de Instancia / Instance Groups</a>, ingrese al grupo de intancias desplegado y de click en la pestaña ```Memberships```. Cuando Jmeter se este ejecutando, puede ingresar a la instancia, posteriormente dar clik en la pestaña ```Monitoring```, allí encuentra el resumen del consumo de CPU y puede evidenciar que actualmente se esta esforzando a más del 10%.

<p align="center"><img width="900" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/monitoring.gif"></p>
<br />
2. Tambien podrá observar como los grupos de instancias autoescalan mientra se ejecuta las solicitudes en Jmeter.

<p align="center"><img width="900" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/ae1.gif"></p>
<br />

3. Finalmente cuando se terminen de enviar las solicitudes, podrá visualizar el desescalamiento de las instancias.

<p align="center"><img width="900" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/ae2.gif"></p>
<br />


## Programar el autoescalamiento :alarm_clock:
*IBM Cloud* le permite programar un autoescalamiento de sus recursos, para lograrlo siga estos pasos:

1. Dirijase a <a href="https://cloud.ibm.com/vpc-ext/autoscale/groups">Grupos de Instancia / Instance Groups</a> y de click en la pestaña ```Scheduled actions```. Active la opción ```Auto scale scheduling``` y a continuación de click en ```Crear / Create ``` e ingrese la siguiente información:
* ```Nombre```: seleccione un nombre para la acción a programar.
* ```Frecuencia```: elija si desea ejecutar la acción una vez o de manera recurrente.
* ```Fecha```: elija la fecha y la hora a la que debe ser ejecutado el autoescalamiento.
* ```Tamaño del grupo de instancias```: Seleccione un tamaño mínimo o máximo (o ambos) para aplicar cuando se ejecute esta acción.

Una vez haya ingresado todos los datos, de click en ``` Crear / Create ```.
<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/programar.gif"></p>
<br />

2. En la fecha y hora que programo, ingrese a <a href="https://cloud.ibm.com/vpc-ext/autoscale/groups">Grupos de Instancia / Instance Groups</a> y observe el estado en ```Escalamiento / Scaling ``` y que el número de instancias haya autoescalado, como se observa en la imagen.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/scaling.PNG"></p>
<br />

 3. Transcurrido un tiempo, ingrese a <a href="https://cloud.ibm.com/vpc-ext/autoscale/groups">Grupos de Instancia / Instance Groups</a> y observe el estado en ```Saludable / Healthy ``` del grupo de instancias, ingrese a su grupo de instancias y dirijase a ```Memberships``` y visualice las dos instancias y su estado.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/intances.gif"></p>
<br />

4. Dirijase al servicio de <a href="https://cloud.ibm.com/vpc-ext/network/loadBalancers">Load Balancer</a> y de click en el Load Balancer desplegado. Seleccione la pestaña ```Back-end pool``` y visualice las instancias con la subred donde esta desplegadas y su dirección IP privada.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/loadbalancer.gif"></p>
<br />

5. Por último ingrese a <a href="https://cloud.ibm.com/vpc-ext/compute/vs">Virtual Server Instances</a> y visualice las instancias en estado ```Running```, como se observa en la imagen.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento-IMG/blob/main/Imagenes/vsi.PNG"></p>
<br />


## Referencias :mag:

* <a href="https://cloud.ibm.com/docs/schematics?topic=schematics-about-schematics">Acerca de IBM Cloud Schematics</a>

<br />

## Autores :black_nib:
Equipo IBM Cloud Tech Sales Colombia.
<br />

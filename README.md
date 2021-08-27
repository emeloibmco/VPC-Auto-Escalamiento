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
<img width="500" alt="autoscale" src=images/vpc-autoscale.png>
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
* ```Ubicación```: Seleccione una ubicacion para el espacio de trabajo.
* ```Descripción```: Opcionalmente puede dar una descripción del proyecto. 

Una vez completos todos los campos puede presionar la opcion ```Crear / Create```.
<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento/blob/main/images/schematics.gif"></p>
<br />

## Configurar las variables de personalización de la plantilla de terraform :memo:
Una vez  creado el espacio de trabajo, podra ver el campo ```Variables``` que permite personalizar el espacio de trabajo. Allí ingrese los siguientes campos:

* ```resource_group_name```: Ingrese el nombre del grupo de recursos en el cual tiene permisos y donde quedaran agrupados todos los recursos que se aprovisionaran.
* ```vpc_name```: Ingrese el nombre que tendra el recurso de VPC en IBM Cloud.
* ```basename```: Ingrese el prefijo de nombre que tendran los recursos a desplegar dentro de la VPC.
* ```ssh_keyname```: Nombre del ssh key que tendrán las instancias de computo en el template, la cual aprovisono previamente.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento/blob/main/images/variables.gif"></p>
<br />

## Generar y aplicar el plan de despliegue de los servidores VPC :white_check_mark:
Ya que estan todos los campos de personalización completos, debe ir hasta la parte superior de la ventana donde encontrará dos opciones, ```Generar plan``` y ```Aplicar plan```. Para continuar con el despliegue de los recursos debera presionar ```Generar Plan``` y una vez termine de generarse el plan ```Aplicar Plan```.

* ```Generar plan```: Según su configuración, Terraform crea un plan de ejecución y describe las acciones que deben ejecutarse para llegar al estado que se describe en sus archivos de configuración de Terraform. Para determinar las acciones, Schematics analiza los recursos que ya están aprovisionados en su cuenta de IBM Cloud para brindarle una vista previa de si los recursos deben agregarse, modificarse o eliminarse. Puede revisar el plan de ejecución, cambiarlo o simplemente ejecutar el plan.

Asegurese de que el proceso se complete con éxito.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento/blob/main/images/generate.gif"></p>
<br />

* ```Aplicar plan```: Cuando esté listo para realizar cambios en su entorno de nube, puede aplicar sus archivos de configuración de Terraform. Para ejecutar las acciones que se especifican en sus archivos de configuración, Schematics utiliza el complemento *IBM Cloud Provider* para Terraform.

A medida que se aplique el plan, se crearán los distintos recursos, los cuales puede ir observando en la lista de recursos de su cuenta. Puede reconocerlos por el ```basename``` especificado previamente. Asegurese de que el proceso se complete con éxito.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento/blob/main/images/apply.gif"></p>
<br />

## Obtener IP pública del load balancer y solicitud HTTP :mag:

1. Dirijase al servicio de <a href="https://cloud.ibm.com/vpc-ext/network/loadBalancers">Load Balancer</a> y de click en el Load Balancer desplegado.
2. En ```IPs``` guarde la IP pública.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento/blob/main/images/ip.gif"></p>
<br />

3. Coloque la ```IP pública``` en la barra de navegación y deberá visualizar lo que se muestra en la imagen.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento/blob/main/images/servidor.PNG"></p>
<br />

## Prueba de esfuerzo para generar el autoescalamiento :muscle:

Para realizar una prueba de esfuerzo lo puede realizar mediante dos opciones:

1. [Ejecutar comando curl](#Ejecutar-comando-curl)
2. [Uso de JMeter](#Uso-de-JMeter)


### Ejecutar comando curl

1. Se ejecutará el comando ```curl``` 2000 veces. Para esto, acceda a *PowerShell* y ejecute el siguiente comando:
```
for ($i=0; $i -le 2000; $i++) {
  curl http://<IP Pública>
 }
```

2. Mientras se ejecuta la prueba, dirijase a <a href="https://cloud.ibm.com/vpc-ext/autoscale/groups">Grupos de Instancia / Instance Groups</a>, elija la instancia que se aprovisonó y de click en la pestaña de ```Memberships```, allí a medida que se ejecuta la prueba deberá observar como se genera el autoescalamiento, añadiendo más intancias automáticamente.
<br />

### Uso de JMeter


## Programar el autoescalamiento :alarm_clock:
*IBM Cloud* le permite programar un autoescalamiento de sus recursos, para lograrlo siga estos pasos:

1. Dirijase a <a href="https://cloud.ibm.com/vpc-ext/autoscale/groups">Grupos de Instancia / Instance Groups</a> y de click en la pestaña ```Scheduled actions```. Active la opción ```Auto scale scheduling``` y a continuación de click en ```Crear / Create ``` e ingrese la siguiente información:
* ```Nombre```: seleccione un nombre para la acción a programar.
* ```Frecuencia```: elija si desea ejecutar la acción una vez o de manera recurrente.
* ```Fecha```: elija la fecha y la hora a la que debe ser ejecutado el autoescalamiento.
* ```Tamaño del grupo de instancias```: Seleccione un tamaño mínimo o máximo (o ambos) para aplicar cuando se ejecute esta acción.

Una vez haya ingresado todos los datos, de click en ``` Crear / Create ```.
<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento/blob/main/images/programar.gif"></p>
<br />

2. En la fecha y hora que programo, ingrese a <a href="https://cloud.ibm.com/vpc-ext/autoscale/groups">Grupos de Instancia / Instance Groups</a> y observe el estado en ```Escalamiento / Scaling ``` y que el número de instancias haya autoescalado, como se observa en la imagen.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento/blob/main/images/scaling.PNG"></p>
<br />

 3. Transcurrido un tiempo, ingrese a <a href="https://cloud.ibm.com/vpc-ext/autoscale/groups">Grupos de Instancia / Instance Groups</a> y observe el estado en ```Saludable / Healthy ``` del grupo de instancias, ingrese a su grupo de instancias y dirijase a ```Memberships``` y visualice las dos instancias y su estado.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento/blob/main/images/intances.gif"></p>
<br />

4. Dirijase al servicio de <a href="https://cloud.ibm.com/vpc-ext/network/loadBalancers">Load Balancer</a> y de click en el Load Balancer desplegado. Seleccione la pestaña ```Back-end pool``` y visualice las instancias con la subred donde esta desplegadas y su dirección IP privada.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento/blob/main/images/loadbalancer.gif"></p>
<br />

5. Por último ingrese a <a href="https://cloud.ibm.com/vpc-ext/compute/vs">Virtual Server Instances</a> y visualice las instancias en estado ```Running```, como se observa en la imagen.

<p align="center"><img width="700" src="https://github.com/emeloibmco/VPC-Auto-Escalamiento/blob/main/images/vsi.PNG"></p>
<br />





## Referencias :mag:

* <a href="https://cloud.ibm.com/docs/schematics?topic=schematics-about-schematics">Acerca de IBM Cloud Schematics</a>

<br />

## Autores :black_nib:
Equipo IBM Cloud Tech Sales Colombia.
<br />

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
5. [Referencias](#Referencias-mag)
6. [Autores](#Autores-black_nib)
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

## Referencias 📖

* [Acerca de IBM Cloud Schematics](https://cloud.ibm.com/docs/schematics?topic=schematics-about-schematics
<br />

## Autores :black_nib:
Equipo IBM Cloud Tech Sales Colombia.
<br />

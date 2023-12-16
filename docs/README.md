<h1 style="text-align: center; font-size: 40px">
  ENTREGABLE DOCKER 3
</h1>

# Fork del repositorio

Lo primero que haremos será, tal y como se indica en el entregable, crear un fork del repositorio que se indica en el tutorial que debemos seguir. Este fork lo podremos hacer manualmente entrando al repositorio de GitHub de la aplicacion, creando un fork y clonando el repositorio. O también para mayor comodidad (esta es la opción que yo he escogido), nos descargamos el cliente de linux de GitHub y podemos hacer el fork con el siguiente comando.

>$ gh repo fork \<user>/\<repo>

Esto es indiferente, pero esta herramienta que he descubierto con el desarrollo de la práctica me ha parecido bastante útil.

Luego se nos pide crear una rama **main** para desarrollar nuestra aplicación y hacer los push al repositorio. Esto lo haremos con el siguiente comando

>$ git checkout -b main

Con esto comprobamos si existe esa rama, si no existe creala y cámbiate a esa rama reacién creada.

Luego se nos pide crear un directorio en la base del repositorio que se llame _docs/_. Para eso introducimos el siguiente comando simplemente:

>$ mkdir docs

Y ahí crear este archivo README.md, el archivo de configuración de **Terraform** y el **Dockerfile** para la creación de nuestra imagen.

Para ello y para poder empezar a visualizar nuestra estructura simplemente creamos los 3 ficheros vacíos en el directorio docs y el archivo Jenkins que tambien se nos pide en la raiz del respositorio:

>$ touch Jenkins docs/README.md docs/Dockerfile docs/main.tf

# Creacion de imagen personalizada

Para la creación de nuestra imagen de Jenkins personal, nos situaremos en el directorio docs/ de nuestro repositorio local e introduciremos el siguiente comando:

>$ docker build -t myjenkins .

Esto nos creará exactamente lo que le hemos indicado dentro de nuestro fichero Dockerfile y nos creará la imagen con nombre myjenkins.

# Creación del Jenkinsfile

Este será simplemente copiar y pegar el contenido que nos proporcionan en la web indicada en el entregable.

Cabe destacar que tuve que hacer unos cambios en la imagen de python que utiliza, puesto que me daba errores, cambiando de la versión _python:3.12.1-alpine3.19_ a _python:alpine3.19_.

# Creación del fichero Terraform

A continuación debemos editar nuestro fichero _main.tf_ e introducir en él el contenido que habríamos tenido que introducir en nuestro comando de docker para lanzar nuestras aplicaciones Jenkins y Dind respectivamente.

Para ambas dentro del fichero _main.tf_ deberemos crear arriba del todo lo siguiente:

```smalltalk
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

resource "docker_network" "jenkins" {
  name = "jenkins"
}
```

Primero presentaré la aplicación de Dind y como la he configurado (añado solo lo más destacable, el resto se puede encontrar en mi repositorio de GitHub en su rama main).

```smalltalk
...

resource "docker_container" "jenkins_dind" {
  name  = "jenkins-docker"
  image = docker_image.dind.image_id
  attach = false
  rm = true
  privileged = true

  env = [
    "DOCKER_TLS_CERTDIR=/certs",
  ]
  
  networks_advanced {
  	name = docker_network.jenkins.name
  }

  volumes {
    volume_name = docker_volume.jenkins_data.name
    container_path = "/var/jenkins_home"
  }
 
  ...

  ports {
    internal = 2376
    external = 2376
  }

  ...

}
```

Como podemos ver en las primeras líneas definimos algunos parámetros simples de nuestro contenedor docker como lo son: nombre, imagen, detach y los privilegios. Mas abajo definimos las variables de entorno, la red a la que pertenece este contenedor y uno de los volúmenes que utiliza. Por último vemos unos de los puertos que debemos exponer para que pueda funcionar correctamente la aplicación.

Ahora presentaré la parte correspondiente a la aplicación Jenkins:

```smalltalk
...

resource "docker_image" "jenkins_image" {
  name = "myjenkins:latest"
  keep_locally = false
}

resource "docker_container" "jenkins_app" {
  name = "jenkins_app"
  image = docker_image.jenkins_image.image_id
  restart = "on-failure"
  attach = false
  
  env = [
    "DOCKER_TLS_CERTDIR=/certs",
    "DOCKER_HOST=tcp://docker:2376",
    "DOCKER_TLS_VERIFY=1",
    "JAVA_OPTS=-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true",
  ]
  
  networks_advanced {
  	name = docker_network.jenkins.name
  }

  ...

  volumes {
    volume_name = "home-jenkins"
    container_path = "/home"
  }
  
  ports {
  	internal = 8080
  	external = 8080
  }

  ...

}
```

Esta parte es más de lo mismo que ya he explicado anteriormente no hay nada nuevo, salvo el cambio de los nombres y poco más.

# Despliegue de Terraform

Para desplegar nuestros servicios desde Terraform lo primero que haremos será situarnos en nuestro directorio **docs/** y, a continuacion introducimos el siguiente comando:

>$ terraform init

Una vez que no haya errores al iniciar introducimos el comando:

>$ terraform plan

Si este comando tampoco nos lanza ningún error podemos proceder a desplegar nuestros servicios con Terraform a través del comando:

>$ terraform apply

Con esto ya tendríamos nuestros servicios lanzados, pudiendo comprobar esto yendo a nuestro navegador a la página http://localhost:8080 y comprobando que podemos entrar a nuestro servicio Jenkins


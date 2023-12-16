terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {}

# Creamos la network para los dos contenedores
resource "docker_network" "jenkins" {
  name = "jenkins"
}


# ------------------------- DOCKER:DIND -------------------------


resource "docker_image" "dind" {
  name = "docker:dind"
  keep_locally = false
}

resource "docker_volume" "jenkins_docker_certs" {
  name = "jenkins-docker-certs"
}

resource "docker_volume" "jenkins_data" {
  name = "jenkins-data"
}

# Creamos y ejecutamos el contenedor exactamente como lo hacemos con docker
# en la página de referencia pero con comandos de terraform
resource "docker_container" "jenkins_dind" {
  name  = "jenkins-docker"
  image = docker_image.dind.image_id

  attach = false
  rm = true
  privileged = true
  network_mode    = docker_network.jenkins.name

  env = [
    "DOCKER_TLS_CERTDIR=/certs",
  ]

  volumes {
    volume_name = docker_volume.jenkins_data.name
    container_path = "/var/jenkins_home"
  }
  
  volumes {
  	volume_name = docker_volume.jenkins_docker_certs.name
  	container_path = "/certs/client"
  }	

  ports {
    internal = 2376
    external = 2376
  }

  ports {
    internal = 3000
    external = 3000
  }

  ports {
    internal = 5000
    external = 5000
  }

}

# ----------------------------- JENKINS -----------------------------

# Image

resource "docker_image" "jenkins_image" {
  name = "myjenkins:latest"
  keep_locally = false
}

resource "docker_container" "jenkins_app" {
  name = "jenkins_app"
  image = docker_image.jenkins_image.image_id
  network_mode = docker_network.jenkins.name
  restart = "on-failure"
  attach = false
  
  env = [
    "DOCKER_TLS_CERTDIR=/certs",
    "DOCKER_HOST=tcp://docker:2376",
    "DOCKER_TLS_VERIFY=1",
    "JAVA_OPTS=-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true",
  ]

  volumes {
    volume_name = docker_volume.jenkins_data.name
    container_path = "/var/jenkins_home"
  }
  
  volumes {
  	volume_name = docker_volume.jenkins_docker_certs.name
  	container_path = "/certs/client"
  }
  
  volumes {
    volume_name = "home-jenkins"
    container_path = "/home"
  }
  
  ports {
  	internal = 8080
  	external = 8080
  }
  
  ports {
    internal = 50000
    external = 50000
  }
}









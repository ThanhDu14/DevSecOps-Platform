data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2204-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "ansible_controller" {
  name         = "ansible-controller"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["allow-ssh"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
    # No access_config block = Private VM only
  }

  metadata = {
    ssh-keys = "jenkins:${var.ssh_public_key}"
  }
}

resource "google_compute_instance" "jenkins_master" {
  name         = "jenkins-master"
  machine_type = "e2-standard-2"
  zone         = var.zone
  tags         = ["allow-ssh", "jenkins-master"]

  service_account {
    email  = google_service_account.jenkins_sa.email
    scopes = ["cloud-platform"]
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 30
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    ssh-keys = "jenkins:${var.ssh_public_key}"
  }
}

resource "google_compute_instance" "jenkins_agent" {
  name         = "jenkins-agent"
  machine_type = "e2-standard-2"
  zone         = var.zone
  tags         = ["allow-ssh", "jenkins-agent"]

  scheduling {
    preemptible        = true
    automatic_restart  = false
    provisioning_model = "SPOT"
  }

  service_account {
    email  = google_service_account.jenkins_sa.email
    scopes = ["cloud-platform"]
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 50
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
  }

  metadata = {
    ssh-keys = "jenkins:${var.ssh_public_key}"
  }
}

resource "google_compute_instance_group" "jenkins_master_group" {
  name        = "jenkins-master-group"
  zone        = var.zone
  instances   = [google_compute_instance.jenkins_master.self_link]
  named_port {
    name = "http"
    port = 8080
  }
}

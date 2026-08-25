resource "google_compute_global_address" "lb_ip" {
  name = "jenkins-lb-ip"
}

resource "google_compute_health_check" "jenkins_hc" {
  name               = "jenkins-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  tcp_health_check {
    port = 8080
  }
}

resource "google_compute_backend_service" "jenkins_backend" {
  name                  = "jenkins-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.jenkins_hc.id]

  backend {
    group           = google_compute_instance_group.jenkins_master_group.self_link
    capacity_scaler = 1.0
  }

  iap {
    oauth2_client_id     = var.iap_client_id
    oauth2_client_secret = var.iap_client_secret
  }
}

resource "google_compute_url_map" "jenkins_url_map" {
  name            = "jenkins-url-map"
  default_service = google_compute_backend_service.jenkins_backend.id
}

# Sử dụng Self-signed cert cho HTTPS Load Balancer
resource "tls_private_key" "default" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "tls_self_signed_cert" "default" {
  private_key_pem = tls_private_key.default.private_key_pem
  subject {
    common_name  = "jenkins.local"
    organization = "DevSecOps Lab"
  }
  validity_period_hours = 8760
  allowed_uses = ["key_encipherment", "digital_signature", "server_auth"]
}
resource "google_compute_ssl_certificate" "default" {
  name        = "jenkins-ssl-cert"
  private_key = tls_private_key.default.private_key_pem
  certificate = tls_self_signed_cert.default.cert_pem
}

resource "google_compute_target_https_proxy" "jenkins_https_proxy" {
  name             = "jenkins-https-proxy"
  url_map          = google_compute_url_map.jenkins_url_map.id
  ssl_certificates = [google_compute_ssl_certificate.default.id]
}

resource "google_compute_global_forwarding_rule" "jenkins_frontend" {
  name                  = "jenkins-frontend"
  target                = google_compute_target_https_proxy.jenkins_https_proxy.id
  port_range            = "443"
  ip_address            = google_compute_global_address.lb_ip.address
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

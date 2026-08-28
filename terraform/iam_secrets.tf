resource "google_service_account" "jenkins_sa" {
  account_id   = "jenkins-sa"
  display_name = "Service Account for Jenkins"
}

resource "google_secret_manager_secret" "jfrog_creds" {
  secret_id = "jfrog-credentials"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "jfrog_sa_access" {
  secret_id = google_secret_manager_secret.jfrog_creds.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

resource "google_secret_manager_secret" "sonar_creds" {
  secret_id = "sonar-credentials"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "sonar_sa_access" {
  secret_id = google_secret_manager_secret.sonar_creds.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.jenkins_sa.email}"
}

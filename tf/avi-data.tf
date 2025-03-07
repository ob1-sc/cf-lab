data "avi_applicationprofile" "system_secure_http" {
  name = "System-Secure-HTTP"
}

data "avi_applicationprofile" "system_l4_application" {
  name = "System-L4-Application"
}

data "avi_applicationprofile" "system_ssl_application" {
  name = "System-SSL-Application"
}
data "avi_sslprofile" "system_standard" {
    name = "System-Standard"
}
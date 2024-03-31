# Add firewall rules to allow traffic to your application's port and deny SSH access from the internet.

resource "google_compute_firewall" "allow_app_traffic" {
  name     = "${var.vpc_name}-allow-app-traffic"
  network  = google_compute_network.vpc.self_link
  priority = var.allow_app_traffic_priority

  allow {
    protocol = var.application_protocol
    ports    = var.application_ports
  }
  direction     = var.direction_ingress
  source_ranges = var.source_ranges_internet
  target_tags   = var.allow_internet
}

resource "google_compute_firewall" "deny_ssh" {
  name      = "${var.vpc_name}-deny-ssh"
  network   = google_compute_network.vpc.self_link
  direction = var.direction_ingress
  priority  = var.deny_ssh_priority
  deny {
    protocol = var.ssh_protocol
    ports    = var.ssh_ports
  }

  source_ranges = var.source_ranges_internet
}

resource "google_compute_firewall" "deny_all_tcp" {
  name      = "${var.vpc_name}-deny-all-tcp"
  network   = google_compute_network.vpc.self_link
  direction = var.direction_ingress
  priority  = var.deny_all_priority
  deny {
    protocol = var.tcp_protocol
  }

  // currently 0.0.0.0/0 implies all IPv4 addresses
  source_ranges = var.source_ranges_internet
}

resource "google_compute_firewall" "deny_all_udp" {
  name      = "${var.vpc_name}-deny-all-udp"
  network   = google_compute_network.vpc.self_link
  direction = var.direction_ingress
  priority  = var.deny_all_priority
  deny {
    protocol = var.udp_protocol
  }

  // currently 0.0.0.0/0 implies all IPv4 addresses
  source_ranges = var.source_ranges_internet
}

/** ALLOW HEALTH CHECK ==========================
An ingress rule, applicable to the instances being load balanced, 
that allows all TCP traffic from the Google Cloud health checking systems 
(in 130.211.0.0/22 and 35.191.0.0/16). 
This example uses the target tag load-balanced-backend to identify the 
VMs that the firewall rule applies to.
**/
resource "google_compute_firewall" "health_check" {
  name = "fw-allow-health-check"
  allow {
    # Use port on which webapp is running
    ports    = [var.var.app_port]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc.id
  priority      = 100
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["load-balanced-backend"]
  # add the above tags to the VMs generated by the auto scaler groups
}

/** ALLOW LOAD BALANCER PROXY =============================
An ingress rule, applicable to the instances being load balanced, 
that allows TCP traffic on ports 80, 443, and 8080 from the 
regional external Application Load Balancer's managed proxies. 

Uses tag to identify the VMs that the firewall rule applies to.

Without these firewall rules, the default deny ingress rule blocks 
incoming traffic to the backend instances.

The target tags define the backend instances. 
Without the target tags, the firewall rules apply to all of 
your backend instances in the VPC network. 
When you create the backend VMs, make sure to include 
the specified target tags, as shown in Creating a managed instance group.
**/

resource "google_compute_firewall" "allow_load_balancer_proxy" {
  name = "fw-allow-proxies"
  allow {
    # Use port on which webapp is running
    ports    = [var.var.app_port]
    protocol = "tcp"
  }
  direction = "INGRESS"
  network   = google_compute_network.vpc.id
  # We keep the priority lower than deny all tcp priority
  priority = 100
  # The source range should include the load balancer subnet in the list
  source_ranges = ["10.0.3.0/24"]
  target_tags   = ["load-balanced-backend"]
  # we need to add this tag to the managed VMs
}

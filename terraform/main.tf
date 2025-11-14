# --- VPC ---
resource "twc_vpc" "main" {
  name        = "netology-vpc"
  subnet_v4   = "192.168.0.0/16"
  description = "VPC for LAMP and NAT"
  location    = "ru-1"
}

# --- Floating IP для NAT ---
resource "twc_floating_ip" "nat_ip" {
  availability_zone = "spb-3"
  ddos_guard        = false
}

# --- NAT сервер ---
resource "twc_server" "nat" {
  name                      = "nat-instance"
  preset_id                 = 2447
  os_id                     = 99
  project_id                = var.project_id
  availability_zone         = "spb-3"
  ssh_keys_ids              = [var.ssh_key_id]
  floating_ip_id            = twc_floating_ip.nat_ip.id
  is_root_password_required = false

  local_network {
    id = twc_vpc.main.id
    ip = "192.168.10.254"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.ssh",
      "echo '${file(var.private_key_path)}' > /root/.ssh/id_rsa",
      "chmod 600 /root/.ssh/id_rsa",
      "sudo sysctl -w net.ipv4.ip_forward=1",
      "sudo apt-get update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent",
      "sudo iptables -t nat -A POSTROUTING -s 192.168.30.0/24 -o eth0 -j MASQUERADE",
      "sudo iptables -A FORWARD -s 192.168.30.0/24 -o eth0 -j ACCEPT",
      "sudo iptables -A FORWARD -d 192.168.30.0/24 -m state --state ESTABLISHED,RELATED -i eth0 -j ACCEPT",
      "sudo netfilter-persistent save"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(var.private_key_path)
      host        = twc_floating_ip.nat_ip.ip
    }
  }
}

# --- Object Storage Bucket ---
resource "twc_s3_bucket" "my_bucket" {
  name       = "dima-2025"
  type       = "private"
  project_id = var.project_id

  configuration {
    configurator_id = 73
    disk            = 1024
  }
}

# --- LAMP серверы ---
resource "twc_server" "lamp_group" {
  count             = 2
  name              = "lamp-server-${count.index + 1}"
  preset_id         = 2447
  os_id             = 99
  project_id        = var.project_id
  availability_zone = "spb-3"
  ssh_keys_ids      = [var.ssh_key_id]

  local_network {
    id = twc_vpc.main.id
    ip = "192.168.30.${count.index + 10}"
  }
}

# --- Floating IP для lb ---
resource "twc_floating_ip" "lb_ip" {
  availability_zone = "spb-3"
  ddos_guard        = false
}

# --- Load Balancer ---
resource "twc_lb" "lamp_lb" {
  name              = "lamp-lb"
  preset_id         = 391
  project_id        = var.project_id
  availability_zone = "spb-3"
  algo              = "roundrobin"
  maxconn           = 10000
  client_timeout    = 20000
  connect_timeout   = 20000
  server_timeout    = 20000
  httprequest_timeout = 20000
  is_keepalive      = false
  is_ssl            = false
  is_sticky         = false
  is_use_proxy      = false

  floating_ip_id = twc_floating_ip.lb_ip.id
  ips = [
    for s in twc_server.lamp_group : s.local_network[0].ip
  ]

  local_network {
    id = twc_vpc.main.id
    ip = "192.168.30.5"
  }

  health_check {
    fall    = 3
    inter   = 10
    path    = "/"
    port    = 80
    proto   = "tcp"
    rise    = 2
    timeout = 5
  }
}

# --- LB Rule для HTTP ---
resource "twc_lb_rule" "lamp_rule_http" {
  lb_id          = twc_lb.lamp_lb.id
  balancer_proto = "http"
  balancer_port  = 80
  server_proto   = "http"
  server_port    = 80
}

# --- LB Rule для HTTPS ---
resource "twc_lb_rule" "lamp_rule_https" {
  lb_id          = twc_lb.lamp_lb.id
  balancer_proto = "https"
  balancer_port  = 443
  server_proto   = "http"
  server_port    = 80
  ssl_cert_id    = twc_lb_ssl_cert.lamp_cert.id
}

# --- Outputs ---
output "lamp_servers" {
  value = [
    for s in twc_server.lamp_group : {
      name = s.name
      ip   = s.local_network[0].ip
    }
  ]
}

output "nat_ip" {
  value = twc_floating_ip.nat_ip.ip
}

output "lb_ip" {
  value = twc_floating_ip.lb_ip.ip
}

output "s3_bucket" {
  value = twc_s3_bucket.my_bucket.name
}

output "s3_file" {
  value = "myimage.png"
}


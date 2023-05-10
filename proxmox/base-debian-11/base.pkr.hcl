packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

locals {
  preseed = {
    username      = var.ssh_username
    password      = var.ssh_password
    root_password = var.root_password
  }
  ssh_public_key = file(var.ssh_public_key_path)
}

source "qemu" "base" {
  vm_name          = var.vm_name
  headless         = true
  shutdown_command = "echo '${var.ssh_password}' | sudo -S /sbin/shutdown -hP now"

  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  cpus      = 2
  disk_size = "65536"
  memory    = 1024
  qemuargs = [
    ["-m", "1024M"],
    ["-bios", "bios-256k.bin"],
    ["-display", "none"]
  ]

  ssh_username         = var.ssh_username
  ssh_password         = var.ssh_password
  ssh_private_key_file = var.ssh_private_key_path
  ssh_port             = 22
  ssh_wait_timeout     = "3600s"

  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/http/preseed.pkrtpl", local.preseed)
  }
  boot_wait    = "5s"
  boot_command = ["<esc><wait>install <wait> preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <wait>debian-installer=en_US.UTF-8 <wait>auto <wait>locale=en_US.UTF-8 <wait>kbd-chooser/method=us <wait>keyboard-configuration/xkb-keymap=us <wait>netcfg/get_hostname={{ .Name }} <wait>netcfg/get_domain=vagrantup.com <wait>fb=false <wait>debconf/frontend=noninteractive <wait>console-setup/ask_detect=false <wait>console-keymaps-at/keymap=us <wait>grub-installer/bootdev=default <wait><enter><wait>"]
}

source "proxmox-iso" "base" {
  proxmox_url = var.proxmox_url
  username    = var.proxmox_username
  password    = var.proxmox_password
  node        = var.proxmox_node

  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  iso_storage_pool = "local"
  unmount_iso      = true

  task_timeout             = "3m"
  insecure_skip_tls_verify = true

  vm_id   = var.vm_id
  vm_name = "${var.vm_name}-${formatdate("YYYY-MM-DD", timestamp())}"

  qemu_agent              = true
  cloud_init              = true
  cloud_init_storage_pool = var.cloud_init_storage_pool

  os              = "l26"
  cores           = var.cores
  sockets         = var.sockets
  memory          = var.memory
  scsi_controller = "virtio-scsi-pci"

  network_adapters {
    bridge = var.proxmox_bridge
    model  = "virtio"
  }

  disks {
    type              = "scsi"
    disk_size         = "5G"
    storage_pool      = var.disk_storage_pool
    format            = "raw"
  }

  ssh_host             = var.vm_ip
  ssh_username         = var.ssh_username
  ssh_password         = var.ssh_password
  ssh_private_key_file = var.ssh_private_key_path
  ssh_port             = 22
  ssh_timeout          = "3600s"

  http_interface = ""
  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/http/preseed.pkrtpl", local.preseed)
  }
  boot_wait = "10s"
  boot_command = [
    "<wait><esc><wait>",
    "install <wait>",

    # TODO http://[http:port]/preseed.cfg cannot be reached
    " preseed/url=http://raw.githubusercontent.com/kencx/homelab/169608d8f84d5b53aa0dacbad7ece7f5ad995888/packer/vagrant/http/preseed.cfg <wait>",
    "debian-installer=en_US.UTF-8 <wait>",
    "auto <wait>",
    "locale=en_US.UTF-8 <wait>",
    "kbd-chooser/method=us <wait>",
    "keyboard-configuration/xkb-keymap=us <wait>",

    # static network config
    "netcfg/disable_autoconfig=true <wait>",
    "netcfg/use_autoconfig=false <wait>",
    "netcfg/get_ipaddress=${var.vm_ip} <wait>",
    "netcfg/get_netmask=${var.vm_netmask} <wait>",
    "netcfg/get_gateway=${var.vm_gateway} <wait>",
    "netcfg/get_nameservers=${var.vm_nameserver} <wait>",
    "netcfg/confirm_static=true <wait>",
    "netcfg/get_hostname=${var.vm_name} <wait>",
    "netcfg/get_domain=base.com <wait>",

    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "console-keymaps-at/keymap=us <wait>",
    "grub-installer/bootdev=default <wait>",
    "<enter><wait>",
  ]
}

build {
  sources = [
    "source.proxmox-iso.base",
  ]

  # Make user ssh-ready for Ansible
  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    inline = [
      "HOME_DIR=/home/${var.ssh_username}/.ssh",
      "mkdir -m 0700 -p $HOME_DIR",
      "echo '${local.ssh_public_key}' >> $HOME_DIR/authorized_keys",
      "chown -R ${var.ssh_username}:${var.ssh_username} $HOME_DIR",
      "chmod 0600 $HOME_DIR/authorized_keys",
      "SUDOERS_FILE=/etc/sudoers.d/${var.ssh_username}",
      "echo '${var.ssh_username} ALL=(ALL) NOPASSWD: ALL' > $SUDOERS_FILE",
      "chmod 0440 $SUDOERS_FILE",
    ]
    expect_disconnect = true
  }

  provisioner "shell" {
    execute_command = "{{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    inline = [
      "apt install -y cloud-init",
      # wait for cloud-init to complete
      "/usr/bin/cloud-init status --wait",
      # install and start qemu-guest-agent
      "apt update && apt install -y qemu-guest-agent ",
      "systemctl enable qemu-guest-agent.service",
      "systemctl start --no-block qemu-guest-agent.service",
    ]
    expect_disconnect = true
  }

  # common post-provisioning
  provisioner "ansible" {
    playbook_file = "../ansible/common.yml"
    use_proxy = false
    extra_arguments = [
      "-e",
      "user=${var.ssh_username}",
      "-e",
      "ansible_become_password=${var.ssh_password}",
    ]
    galaxy_file = "../requirements.yml"
    user        = var.ssh_username
    ansible_env_vars = [
      "ANSIBLE_STDOUT_CALLBACK=yaml",
      "ANSIBLE_HOST_KEY_CHECKING=False",
    ]
  }
}
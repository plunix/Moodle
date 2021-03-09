source "azure-arm" "ubuntu-controllermoodleinps-vhd" {
  # basics
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"  
  subscription_id = "8c6de99e-e09d-4e56-869e-dcfd2d3ee2ed"
  tenant_id = "${var.tenant}"

  # output settings
  resource_group_name = "INPS-LMS1"
  storage_account = "moodlescripts"
  capture_container_name = "images"
  capture_name_prefix = "moodle-controller"  

  # base image settings
  os_type = "Linux"
  image_publisher = "Canonical"
  image_offer = "UbuntuServer"
  image_sku = "18.04-LTS"

  # temp image settings
  location = "West Europe"
  vm_size = "Standard_B2s"
}

source "azure-arm" "ubuntu-controllermoodleinps-managedimage" {
  # basics
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  subscription_id = "8c6de99e-e09d-4e56-869e-dcfd2d3ee2ed"
  tenant_id = "${var.tenant}"
  
  # base image settings
  os_type = "Linux"
  image_publisher = "Canonical"
  image_offer = "UbuntuServer"
  image_sku = "18.04-LTS"
  
  # temp image settings
  location = "West Europe"
  vm_size = "Standard_B2s"

  # output settings
  managed_image_name = "controller-moodleinps"
  managed_image_resource_group_name = "INPS-LMS1"
}

build {
  sources = [
    "sources.azure-arm.ubuntu-controllermoodleinps-vhd"
    #"sources.azure-arm.ubuntu-controllermoodleinps-managedimage"
  ]

  provisioner "shell" {
    scripts = [
      "scripts/controller.sh"
    ]

    environment_vars = [
      "phpVersion=${var.phpVer}",
      "moodleVersion=${var.moodleVer}"
    ]

    # Run provisioner as sudo
    execute_command = "echo 'packer' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
  }
}
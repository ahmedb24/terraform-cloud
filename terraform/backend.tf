terraform {
  cloud {
    organization = "mdz24"

    workspaces {
      name = "terraform-cloud-local"
    }
  }
}
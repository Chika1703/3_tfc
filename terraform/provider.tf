terraform {
  required_providers {
    twc = {
      source  = "tf.timeweb.cloud/timeweb-cloud/timeweb-cloud"
      version = ">= 0.2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.3"
    }
  }

  required_version = ">= 1.1.0"
}

provider "twc" {
  token = var.tw_token
}

provider "null" {}

provider "local" {}

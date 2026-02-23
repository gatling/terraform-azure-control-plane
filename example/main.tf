provider "azurerm" {
  features {}
}

# Create a control plane based on Azure Container App
# Reference: https://docs.gatling.io/reference/install/cloud/private-locations/azure/installation/
module "control-plane" {
  source              = "gatling/control-plane/azure"
  name                = "<Name>"
  description         = "My Azure control plane description"
  vault-name          = "<Vault>"
  token-secret-id     = "<TokenSecretIdentifier>"
  region              = "<Region>"
  resource-group-name = "<ResourceGroup>"

  # Configure Azure private locations
  # Reference: https://docs.gatling.io/reference/install/cloud/private-locations/azure/configuration/#control-plane-configuration-file
  locations = [
    {
      id           = "prl_azure"
      description  = "Private Location on Azure"
      region       = "westeurope"
      subscription = "<SubscriptionUUID>"
      network-id   = "/subscriptions/<SubscriptionUUID>/resourceGroups/<ResourceGroup>/providers/Microsoft.Network/virtualNetworks/<VNet>"
      subnet-name  = "<Subnet>"
      # image = {
      #   type  = "certified"
      #   java  = "latest"
      #   image = "/subscriptions/<SubscriptionUUID>/resourceGroups/<ResourceGroup>/providers/Microsoft.Compute/galleries/customImages/images/<Image>"
      # }
      # size                = "Standard_A4_v2"
      # engine              = "classic"
      # associate-public-ip = true
      # tags                = {}
      # system-properties   = {}
      # java-home           = "/usr/lib/jvm/zulu"
      # jvm-options         = []
      # enterprise-cloud = {
      #   Setup the proxy configuration for the private location
      #   Reference: https://docs.gatling.io/reference/install/cloud/private-locations/network/#configuring-a-proxy
      # }
    }
  ]

  # Configure a private package (control plane repository & server) based on Azure Blob Storage (optional)
  # Reference: https://docs.gatling.io/reference/install/cloud/private-locations/private-packages/#gcp-cloud-storage
  # Reference: https://docs.gatling.io/reference/install/cloud/private-locations/private-packages/#control-plane-server
  # private-package = {
  #   storage-account = "<StorageAccountName>"
  #   container       = "<Name>"
  #   path            = ""
  #   upload = {
  #     directory = "/tmp"
  #   }
  # }

  # container-app = {
  #   init = {
  #     image = "busybox"
  #   }
  #   cpu               = 1.0
  #   memory            = "2Gi"
  #   image             = "gatlingcorp/control-plane:latest"
  #   command           = []
  #   environment       = []
  #   expose-externally = true
  # }
  # # Configure git credentials for the control plane. Requires builder image: "gatlingcorp/control-plane:latest-builder"
  # # Reference: https://docs.gatling.io/reference/execute/cloud/user/build-from-sources/
  # git = {
  #   credentials = {
  #     username        = "<GitUsername>"
  #     token-secret-id = "<GitTokenSecretId>"
  #   }
  #   ssh = {
  #     storage-account-name = "<StorageAccountName>"
  #     file-share-name      = "<FileShareName>"
  #     file-name            = "<FileName>"
  #   }
  #   cache = {
  #     paths = ["/app/.m2", "/app/.gradle", "/app/.sbt", "/app/.npm"]
  #   }
  # }
  # enterprise-cloud = {
  #   Setup the proxy configuration for the private location
  #   Reference: https://docs.gatling.io/reference/install/cloud/private-locations/network/#configuring-a-proxy
  # }
  # server = {
  #   port        = 8080
  #   bindAddress = "0.0.0.0"
  #   certificate = {
  #     path     = "/path/to/certificate.p12"
  #     password = "password"
  #   }
  # }
}

variable "name" {
  description = "Name of the control plane"
  type        = string

  validation {
    condition     = length(var.name) > 0
    error_message = "The name of the control plane must not be empty."
  }
}

variable "description" {
  description = "Description of the control plane."
  type        = string
  default     = "My Azure control plane description"
}

variable "vault-name" {
  description = "Vault name where the control plane token secret is stored."
  type        = string

  validation {
    condition     = length(var.vault-name) > 0
    error_message = "Vault name must not be empty."
  }
}

variable "token-secret-id" {
  description = "Secret identifier where the control token plane is stored."
  type        = string

  validation {
    condition     = length(var.token-secret-id) > 0
    error_message = "Secret identifier must not be empty."
  }
}

variable "region" {
  description = "Region of the location."
  type        = string

  validation {
    condition     = length(var.region) > 0
    error_message = "Region must not be empty."
  }
}

variable "resource-group-name" {
  description = "Resource group name."
  type        = string

  validation {
    condition     = length(var.resource-group-name) > 0
    error_message = "Resource group must not be empty."
  }
}

variable "container-app" {
  description = "Container app settings."
  type = object({
    init = optional(object({
      image = optional(string, "busybox")
    }), {})
    cpu     = optional(number, 1.0)
    memory  = optional(string, "2Gi")
    image   = optional(string, "gatlingcorp/control-plane:latest")
    command = optional(list(string), [])
    secrets = optional(list(object({
      name        = optional(string)
      secret-name = optional(string)
    })), [])
    environment = optional(list(object({
      name        = optional(string)
      value       = optional(string)
      secret-name = optional(string)
    })), [])
    expose-externally = optional(bool, true)
  })
  default = {}
}

variable "git" {
  description = "Control plane git configuration."
  type = object({
    credentials = optional(object({
      username        = optional(string, "")
      token-secret-id = optional(string, "")
    }), {})
    ssh = optional(object({
      storage-account-name = optional(string, "")
      file-share-name      = optional(string, "")
      file-name            = optional(string, "")
    }), {}),
    cache = optional(object({
      paths = optional(list(string), [])
    }), {})
  })
  default = {}

  validation {
    condition = (
      length(var.git.credentials.username) == 0 ||
      length(var.git.credentials.token-secret-id) > 0
    )
    error_message = "When credentials.username is set, credentials.token-secret-id must also be provided."
  }
}

variable "locations" {
  description = "Configuration for the private locations."
  type = list(object({
    id          = string
    description = optional(string, "Private Location on Azure")
    region      = string
    engine      = optional(string, "classic")
    size        = optional(string, "Standard_A4_v2")
    image = optional(object({
      type  = optional(string, "certified")
      java  = optional(string, "latest")
      image = optional(string)
    }), {})
    subscription        = string
    network-id          = string
    subnet-name         = string
    associate-public-ip = optional(bool, true)
    tags                = optional(map(string), {})
    system-properties   = optional(map(string), {})
    java-home           = optional(string, null)
    jvm-options         = optional(list(string), [])
    enterprise-cloud    = optional(map(any), {})
  }))

  validation {
    condition     = length(var.locations) > 0
    error_message = "At least one private location must be specified."
  }

  validation {
    condition     = alltrue([for loc in var.locations : can(regex("^prl_[0-9a-z_]{1,26}$", loc.id))])
    error_message = "Private location ID must be prefixed by 'prl_', contain only numbers, lowercase letters, and underscores, and be at most 30 characters long."
  }

  validation {
    condition     = alltrue([for loc in var.locations : contains(["classic", "javascript"], loc.engine)])
    error_message = "The engine must be either 'classic' or 'javascript'."
  }

  validation {
    condition     = alltrue([for loc in var.locations : length(loc.region) > 0])
    error_message = "Region must not be empty."
  }

  validation {
    condition     = alltrue([for loc in var.locations : length(loc.subscription) > 0])
    error_message = "Subscription must not be empty."
  }

  validation {
    condition     = alltrue([for loc in var.locations : length(loc.network-id) > 0])
    error_message = "Virtual network name must not be empty."
  }

  validation {
    condition     = alltrue([for loc in var.locations : length(loc.subnet-name) > 0])
    error_message = "Subnet name must not be empty."
  }

  validation {
    condition     = alltrue([for loc in var.locations : loc.image.type != "custom" || loc.image.image != null])
    error_message = "If image.type is 'custom', then image.image must be specified."
  }
}

variable "private-package" {
  description = "Configuration for the private package (Azure Blob Storage-based)."
  type = object({
    storage-account = string
    container       = string
    path            = optional(string, "")
    upload = optional(object({
      directory = string
    }), { directory = "/tmp" })
  })
  default = null

  validation {
    condition     = var.private-package == null || length(var.private-package.storage-account) > 0
    error_message = "Storage account name must not be empty."
  }

  validation {
    condition     = var.private-package == null || length(var.private-package.container) > 0
    error_message = "Control plane name must not be empty."
  }
}

variable "enterprise-cloud" {
  type    = map(any)
  default = {}
}

variable "extra-content" {
  type    = map(any)
  default = {}
}

variable "server" {
  description = "Control Plane Repository Server configuration."
  type = object({
    port        = optional(number, 8080)
    bindAddress = optional(string, "0.0.0.0")
    certificate = optional(object({
      path     = optional(string)
      password = optional(string, null)
    }), null)
  })
  default = {}

  validation {
    condition     = var.server.port > 0 && var.server.port <= 65535
    error_message = "Server port must be between 1 and 65535."
  }
  validation {
    condition     = length(var.server.bindAddress) > 0
    error_message = "Server bindAddress must not be empty."
  }
}

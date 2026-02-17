locals {
  conf_path       = "/app/conf"
  ssh_path        = "/app/.ssh"
  file_share_path = "/app/.file-share"
  volume_name     = "control-plane-conf"
  ssh_volume_name = "ssh-key-vol"
  file_share_name = "file-share-vol"
  git = {
    ssh_enabled   = length(var.git.ssh.storage-account-name) > 0
    creds_enabled = length(var.git.credentials.token-secret-id) > 0
  }
  secrets = concat(
    [
      {
        name        = "CONTROL_PLANE_TOKEN"
        secret-name = "control-plane-token"
        secret-id   = var.token-secret-id
      }
    ],
    local.git.creds_enabled ? [
      {
        name        = "GIT_TOKEN"
        secret-name = "git-token"
        secret-id   = var.git.credentials.token-secret-id
      }
    ] : [],
    var.container-app.secrets
  )
  environment = concat(var.container-app.environment, [
    {
      name  = "AZURE_CLIENT_ID"
      value = azurerm_user_assigned_identity.gatling_identity.client_id
    }
  ])
  config_content = <<-EOF
    control-plane {
      token = $${?CONTROL_PLANE_TOKEN}
      description = "${var.description}"
      enterprise-cloud = ${jsonencode(var.enterprise-cloud)}
      locations = [%{for location in local.locations} ${jsonencode(location)}, %{endfor}]
      server = ${jsonencode(var.server)}
      %{if local.private-package != null}repository = ${jsonencode(local.private-package)}%{endif}
      %{for key, value in var.extra-content}${key} = "${value}"%{endfor}
      %{if local.git.ssh_enabled || local.git.creds_enabled}
      builder {
        %{if local.git.ssh_enabled}
        git.global.credentials.ssh {
          key-file = "${local.ssh_path}/${var.git.ssh.file-name}"
        }
        %{endif}
        %{if local.git.creds_enabled}
        git.global.credentials.https {
          %{if length(var.git.credentials.username) > 0}username = "${var.git.credentials.username}"%{endif}
          password = $${?GIT_TOKEN}
        }
        %{endif}
      }
      %{endif}
    }
  EOF
  mountPoints = concat(
    [
      {
        sourceVolume : local.volume_name
        containerPath : local.conf_path
      }
    ],
    local.git.ssh_enabled ? [
      {
        sourceVolume : local.ssh_volume_name
        containerPath : local.ssh_path
      }
    ] : [],
    [
      for cache_path in var.git.cache.paths : {
        sourceVolume  = local.volume_name
        containerPath = cache_path
      }
  ])
  init_commands = compact([
    "echo \"$CONFIG_CONTENT\" > ${local.conf_path}/control-plane.conf && chown -R 1001 ${local.conf_path} && chmod 400 ${local.conf_path}/control-plane.conf",
    local.git.ssh_enabled ? "cp ${local.file_share_path}/${var.git.ssh.file-name} ${local.ssh_path}/${var.git.ssh.file-name} && chown -R 1001 ${local.ssh_path} && chmod 400 ${local.ssh_path}/${var.git.ssh.file-name}" : "",
  ])
  init = {
    command = [
      "/bin/sh",
      "-c",
      join(" && ", local.init_commands)
    ]
    secrets = []
    environment = [
      {
        name  = "CONFIG_CONTENT"
        value = local.config_content
      }
    ]
    mountPoints = concat(
      [
        {
          sourceVolume : local.volume_name
          containerPath : local.conf_path
        }
      ],
      local.git.ssh_enabled ? [
        {
          sourceVolume : local.ssh_volume_name
          containerPath : local.ssh_path
        },
        {
          sourceVolume : local.file_share_name
          containerPath : local.file_share_path
        }
    ] : [])
  }
}

resource "azurerm_container_app_environment" "gatling_container_env" {
  name                = "${var.name}-env"
  resource_group_name = var.resource-group-name
  location            = var.region
}

resource "azurerm_container_app_environment_storage" "gatling_container_env_storage" {
  count                        = local.git.ssh_enabled ? 1 : 0
  name                         = local.file_share_name
  container_app_environment_id = azurerm_container_app_environment.gatling_container_env.id
  account_name                 = var.git.ssh.storage-account-name
  share_name                   = var.git.ssh.file-share-name
  access_key                   = data.azurerm_storage_account.gatling_storage_account[0].primary_access_key
  access_mode                  = "ReadOnly"
}

resource "azurerm_container_app" "gatling_container" {
  name                         = var.name
  resource_group_name          = var.resource-group-name
  container_app_environment_id = azurerm_container_app_environment.gatling_container_env.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.gatling_identity.id]
  }

  ingress {
    external_enabled = var.container-app.expose-externally
    target_port      = var.server.port
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  dynamic "secret" {
    for_each = local.secrets
    content {
      name                = secret.value.secret-name
      key_vault_secret_id = secret.value.secret-id
      identity            = azurerm_user_assigned_identity.gatling_identity.id
    }
  }

  template {
    min_replicas = 1
    max_replicas = 1

    init_container {
      name    = "conf-loader-init-container"
      image   = var.container-app.init.image
      cpu     = "0.25"
      memory  = "0.5Gi"
      command = local.init.command

      dynamic "env" {
        for_each = local.init.environment
        content {
          name        = env.value.name
          value       = lookup(env.value, "value", null)
          secret_name = lookup(env.value, "secret-name", null)
        }
      }

      dynamic "volume_mounts" {
        for_each = local.init.mountPoints
        content {
          name = volume_mounts.value.sourceVolume
          path = volume_mounts.value.containerPath
        }
      }
    }

    container {
      name    = "control-plane"
      image   = var.container-app.image
      cpu     = var.container-app.cpu
      memory  = var.container-app.memory
      command = var.container-app.command

      dynamic "env" {
        for_each = concat(local.environment, local.secrets)
        content {
          name        = env.value.name
          value       = lookup(env.value, "value", null)
          secret_name = lookup(env.value, "secret-name", null)
        }
      }

      dynamic "volume_mounts" {
        for_each = local.mountPoints
        content {
          name = volume_mounts.value.sourceVolume
          path = volume_mounts.value.containerPath
        }
      }
    }

    volume {
      name         = local.volume_name
      storage_type = "EmptyDir"
    }

    dynamic "volume" {
      for_each = local.git.ssh_enabled ? [1] : []
      content {
        name         = local.ssh_volume_name
        storage_type = "EmptyDir"
      }
    }

    dynamic "volume" {
      for_each = local.git.ssh_enabled ? [1] : []
      content {
        name         = local.file_share_name
        storage_name = local.file_share_name
        storage_type = "AzureFile"
      }
    }
  }

  depends_on = [
    azurerm_container_app_environment_storage.gatling_container_env_storage,
    azurerm_key_vault_access_policy.container_app_policy,
  ]
}

locals {
  locations       = [for loc in var.locations : merge(loc, { type = "azure" })]
  private-package = var.private-package != null ? merge(var.private-package, { type = "azure" }) : null
}

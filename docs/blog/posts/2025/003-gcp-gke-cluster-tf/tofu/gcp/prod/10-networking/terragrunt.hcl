include "backend" {
  path = find_in_parent_folders("backend.hcl")
}

include "gcp" {
  path = find_in_parent_folders("gcp.hcl")
}

inputs = {
}

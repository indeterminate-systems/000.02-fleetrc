# Contracts for the fleet. Everything in roles.ncl / environments.ncl is checked against these
# when `nickel export` runs, so a typo or a missing field fails before anything is generated.
{
  NonEmpty = std.contract.from_predicate (fun s => std.is_string s && s != ""),
  EnvVarName = std.contract.from_predicate (fun s =>
    std.is_string s && std.string.is_match "^[A-Z_][A-Z0-9_]*$" s),
  HostName = std.contract.from_predicate (fun s =>
    std.is_string s && std.string.is_match "^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$" s),

  # A role: what a session started from an environment should end up with.
  Role = {
    description | String,
    # nixpkgs attribute names, installed into /nix/var/nix/profiles/fleetrc
    tools | Array NonEmpty,
    # names of the secrets (environment variables) this role may receive. Values never live here.
    secrets | Array EnvVarName | default = [],
    # hosts the role needs when its environment's network is "limited"
    needs_hosts | Array HostName | default = [],
  },

  Network = [| 'unrestricted, 'limited |],

  # An environment as saved on claude.ai. `managed = false` means inventory only: recorded, not
  # deployed and not checked by the Yen rules yet.
  Environment = {
    id | String,
    managed | Bool | default = true,
    role | String | optional,
    network | Network,
    allowed_hosts | Array HostName | default = [],
    allow_package_managers | Bool | default = true,
    # env var NAMES actually saved on the environment (from get_environment; values are never read)
    env_var_names | Array EnvVarName | default = [],
    notes | Array String | default = [],
  },
}

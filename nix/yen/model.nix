# The fleet as Yen data, generated from generated/fleet.json (which Nickel exports).
# Only managed environments are modelled; inventory-only ones are left out until they get a role.
fleet:
{ yen, ... }:
let
  inherit (builtins)
    attrValues
    filter
    listToAttrs
    concatMap
    mapAttrs
    ;
  uniq =
    l:
    builtins.attrNames (
      listToAttrs (
        map (n: {
          name = n;
          value = null;
        }) l
      )
    );
  managed = filterAttrs (_: e: e.managed) fleet.environments;
  filterAttrs =
    f: s:
    listToAttrs (
      filter (x: f x.name x.value) (
        map (n: {
          name = n;
          value = s.${n};
        }) (builtins.attrNames s)
      )
    );
  roles = attrValues fleet.roles;
  envs = attrValues managed;
  allSecrets = uniq (concatMap (r: r.secrets) roles ++ concatMap (e: e.env_var_names) envs);
  allHosts = uniq (concatMap (r: r.needs_hosts) roles ++ concatMap (e: e.allowed_hosts) envs);
  named =
    names: v:
    listToAttrs (
      map (n: {
        name = n;
        value = v;
      }) names
    );
in
{
  yen.kinds.fleet.spawns = {
    role = _: yen.role;
    env = _: yen.env;
    secret = _: yen.secret;
    nethost = _: yen.nethost;
  };
  yen.kinds.secret = { };
  yen.kinds.nethost = { };
  yen.kinds.role.fields = {
    secrets = yen.lib.listOf yen.kinds.secret;
    needs = yen.lib.listOf yen.kinds.nethost;
  };
  yen.kinds.env.fields = {
    role = yen.kinds.role;
    network = yen.lib.enum [
      "unrestricted"
      "limited"
    ];
    secrets = yen.lib.listOf yen.kinds.secret;
    allows = yen.lib.listOf yen.kinds.nethost;
  };

  yen.fleet.main = { };
  yen.secret = named allSecrets { };
  yen.nethost = named allHosts { };
  yen.role = mapAttrs (_: r: {
    secrets = map (s: yen.secret.${s}) r.secrets;
    needs = map (h: yen.nethost.${h}) r.needs_hosts;
  }) fleet.roles;
  yen.env = mapAttrs (_: e: {
    role = yen.role.${e.role};
    network = e.network;
    secrets = map (s: yen.secret.${s}) e.env_var_names;
    allows = map (h: yen.nethost.${h}) e.allowed_hosts;
  }) managed;
}

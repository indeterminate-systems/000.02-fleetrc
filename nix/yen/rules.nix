# Fleet rules. Each is a mistake no single environment can see on its own.
{ yen, ... }:
let
  inherit (yen.facts) env role;
in
{
  # A secret is saved on an environment only if that environment's role names it.
  yen.invariants.secret-not-in-role =
    {
      E,
      S,
      R,
    }:
    {
      bad = [
        E
        S
      ];
      pos = [
        (env.secrets E S)
        (env.role E R)
      ];
      neg = [ (role.secrets R S) ];
    };

  # On a limited network, every host the role needs is on the environment's allowlist.
  yen.invariants.network-misses-role-host =
    {
      E,
      R,
      H,
    }:
    {
      bad = [
        E
        H
      ];
      pos = [
        (env.network E "limited")
        (env.role E R)
        (role.needs R H)
      ];
      neg = [ (env.allows E H) ];
    };
}

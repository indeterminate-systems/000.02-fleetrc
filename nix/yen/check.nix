# Evaluate the Yen model and rules; `verdict` is plain data, `drv` fails to build on any violation.
{
  yen,
  lib,
  fleet,
  extraModules ? [ ],
  runCommand,
}:
let
  result = (import yen).lib.eval {
    imports = [
      (import ./model.nix fleet)
      ./rules.nix
    ]
    ++ extraModules;
  };
  verdict = {
    inherit (result.check) ok violations incomplete;
    errors = map (e: e.code or e) result.errors;
  };
  json = builtins.toJSON verdict;
in
{
  inherit result verdict;
  drv =
    if verdict.ok && verdict.errors == [ ] then
      runCommand "fleetrc-yen-check" { } "echo ${lib.escapeShellArg json} > $out"
    else
      throw "fleetrc: Yen rules failed:\n${json}";
}

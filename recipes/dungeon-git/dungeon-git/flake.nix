{
  # dungeon (github:vic/dungeon), fetched entirely over git+https.
  # gen fetches its sub-libraries with builtins.fetchTree on `github:` lock nodes,
  # which this sandbox's proxy blocks; we pass gen a `src` that fetches the same revs via git.
  inputs.dungeon = { url = "git+https://github.com/vic/dungeon?shallow=1"; flake = false; };
  inputs.gen = { url = "git+https://github.com/sini/gen?rev=bcbc5ca579614643fa3433034fd0248b0d551f65&shallow=1"; flake = false; };
  outputs = { dungeon, gen, ... }: let
    lock = builtins.fromJSON (builtins.readFile "${gen}/flake.lock");
    resolve = segs: let
      following = node: inp: let v = (lock.nodes.${node}.inputs or { }).${inp};
        in if builtins.isString v then v else builtins.foldl' following lock.root v;
    in builtins.foldl' following lock.root segs;
    toGit = l: if l.type == "github" then {
      type = "git"; url = "https://github.com/${l.owner}/${l.repo}";
      inherit (l) rev narHash; shallow = true;
    } else l;
    src = segs: "${builtins.fetchTree (toGit lock.nodes.${resolve segs}.locked)}";
    imp = import ./github-as-git.nix;
    d = imp "${dungeon}/default.nix" { gen = imp gen { inherit src; }; };
  in {
    lib = d;
    flakeModule = d.flakeModule;
    flakeModules = { inherit (d.flakeModules) default dendritic; denTest = d.ciSurface.denTestModule; };
    namespace = d.namespace;
    flakeOutputs = d.ciSurface.flakeOutputs;
  };
}

# Import a Nix file so that every builtins.fetchTree / fetchTarball of a GitHub
# tarball inside it (and inside everything it imports) is fetched with git instead.
# Same rev, same narHash, same store path: only the transport changes.
let
  toGit = l:
    if builtins.isAttrs l && (l.type or null) == "github" then
      { type = "git"; url = "https://github.com/${l.owner}/${l.repo}"; inherit (l) rev; shallow = true; }
      // (if l ? narHash then { inherit (l) narHash; } else { })
    else l;
  archiveRe = "https://github.com/([^/]+)/([^/]+)/archive/([0-9a-f]{40})\\.tar\\.gz";
  fetchTree = a: builtins.fetchTree (toGit a);
  fetchTarball = a:
    let
      url = if builtins.isString a then a else a.url;
      m = builtins.match archiveRe url;
    in
      if m == null then builtins.fetchTarball a
      else (builtins.fetchTree ({ type = "git"; url = "https://github.com/${builtins.elemAt m 0}/${builtins.elemAt m 1}";
              rev = builtins.elemAt m 2; shallow = true; }
              // (if builtins.isAttrs a && a ? sha256 then { narHash = a.sha256; } else { }))).outPath;
  patchedBuiltins = builtins // { inherit fetchTree fetchTarball; };
  scope = { builtins = patchedBuiltins; inherit fetchTarball; import = imp; };
  imp = p: builtins.scopedImport scope (if builtins.pathExists "${p}/default.nix" && builtins.readFileType "${p}" == "directory" then "${p}/default.nix" else p);
in imp

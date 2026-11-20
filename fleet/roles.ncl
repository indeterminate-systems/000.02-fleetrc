let S = import "schema.ncl" in
{
  nix | S.Role = {
    description = "Nix work: building roles, pins, Nickel, NixOS-in-Docker experiments.",
    tools = ["nickel", "npins", "jq", "git", "nixfmt", "shellcheck"],
    # FLY_API_TOKEN is already saved on Nix-Portable; naming it here is what makes that legal.
    secrets = ["FLY_API_TOKEN"],
    needs_hosts = ["cache.nixos.org", "channels.nixos.org", "releases.nixos.org", "github.com"],
  },

  typst-cloudflare | S.Role = {
    description = "Typst documents published through Cloudflare (wrangler).",
    tools = ["typst", "wrangler", "nodejs", "jq", "git"],
    secrets = ["CLOUDFLARE_ACCOUNT_ID", "CLOUDFLARE_API_TOKEN"],
    needs_hosts = ["cache.nixos.org", "releases.nixos.org", "github.com", "api.cloudflare.com"],
  },
}

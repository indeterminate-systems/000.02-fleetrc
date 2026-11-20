# Inventory of claude.ai cloud environments, taken with get_environment on 2026-11-20.
let S = import "schema.ncl" in
{
  "Nix-Portable" | S.Environment = {
    id = "env_01Hhrb1WTHn2DAKpFRkn652i",
    role = "nix",
    network = 'unrestricted,
    env_var_names = ["FLY_API_TOKEN"],
    # The setup script held only this list of hosts as comments before fleetrc took over.
    notes = "Hosts noted in the previous setup script: huggingface.co, *.huggingface.co, *.hf.co, registry.ollama.ai, ollama.com, github.com, api.github.com, objects.githubusercontent.com, typesafe.ai, docs.typesafe.ai",
  },

  "typst+Cloudflare" | S.Environment = {
    id = "env_019PfPRc2Pnrbzka1N4TUPvX",
    role = "typst-cloudflare",
    network = 'unrestricted,
    env_var_names = ["CLOUDFLARE_ACCOUNT_ID", "CLOUDFLARE_API_TOKEN"],
  },

  "xD-dev" | S.Environment = {
    id = "env_0178UhLCsp9VVvSZ1TtgtRWx",
    managed = false,
    network = 'unrestricted,
  },

  "xdgprobe" | S.Environment = {
    id = "env_01Jz5dR5Q5GMbQMGPFav42yL",
    managed = false,
    network = 'limited,
    env_var_names = ["XDGPROBE"],
  },

  "Default" | S.Environment = {
    id = "env_01J2KSjw4r6Cngyn31NgY5AL",
    managed = false,
    network = 'unrestricted,
  },
}

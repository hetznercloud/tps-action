# TPS Action


GitHub Action to create temporary Hetzner Cloud API Tokens. This action uses the Temporary Project Service (hence the name) to create a new project and associated API Token for the CI run. It authenticates using the GitHub provided OIDC token for the pipeline run.


### This project is not an official Hetzner Cloud Integration and is intended to be used by our other repositories.

## Usage

```yaml
on:
  pull_request: {}
  push:
    branches: [main]

jobs:
  demo:
    permissions:
      # This is required so the pipeline can generate an oauth token.
      id-token: write
    runs-on: ubuntu-latest

    steps:
      - # We do not provide explicit releases for the action right now, so use
        # the main branch to be up to date, or lock to a specific commit.
        uses: hetznercloud/tps-action@main
        with:
          # Optional: If an explicit token is passed, it will be used instead
          # of TPS. This can be helpful to debug issues in another account,
          # or for usage from a fork where the oauth permissions are not available.
          token: ${{ secrets.HCLOUD_TOKEN  }}

      - uses: 3bit/setup-hcloud@v2

      - # The action set the environment variable HCLOUD_TOKEN, so all
        # subsequent steps in the same job can use it.
        run: hcloud server-type list
```

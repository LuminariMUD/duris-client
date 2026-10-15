# Contributing

Contributions to the Duris Mudlet package are welcome in [LuminariMUD/duris-client](https://github.com/LuminariMUD/duris-client). The package was originally created by Arjinius / Arjin.

Read the [Code of Conduct](CODE_OF_CONDUCT.md) and [license status](LICENSE.md) before contributing. Preserve existing author credits and identify the source and license of any material you add.

## Report a problem or propose a feature

Use the [issue forms](https://github.com/LuminariMUD/duris-client/issues/new/choose). Include the package version, Mudlet version, operating system, GMCP status, reproduction steps, and expected versus actual behavior. Remove passwords, login commands, and private messages from logs and screenshots. For security concerns, follow [SECURITY.md](SECURITY.md).

## Make a change

1. Fork this repository and create a branch from `master`.
2. For package changes, edit `src/`, the source of truth. Do not edit `duris-client.mpackage` directly. Use Mudlet/Geyser APIs without external Lua dependencies, and preserve the percentage-based layout and dark fantasy style described in [DESIGN.md](docs/DESIGN.md). Update that guide when layout, interactions, or architecture change. Repository documentation lives in the root Markdown files and `docs/`.
3. For package changes, bump `VERSION` and add a matching entry to `CHANGELOG.md`, following [RELEASING.md](docs/RELEASING.md). Repository-only documentation changes do not require a package version bump.
4. For package changes, install Python 3 and a Lua 5.1 compiler (`luac5.1`), then run:

   ```bash
   python3 build.py --check
   python3 build.py
   git diff --check
   ```

   The build has no Python package dependencies. The syntax check warns and skips Lua validation if no supported compiler is installed. Confirm that it actually ran. A full build also validates the assembled XML.

   For repository-only documentation changes, check links, examples, and `git diff --check`; no package rebuild is needed.

5. For runtime changes, follow [Linux development](docs/LINUX_DEVELOPMENT.md#automated-offline-tests): run `python3 scripts/mudlet_suite.py` with Mudlet 5.0+ and review the saved screenshots and Errors view. A zero exit code covers automated behavior; it does not approve appearance. Import the package into a separate live profile for affected server behavior and reconnect checks. The declared Mudlet 4.19.1 minimum requires its own manual portable-profile run.
6. For package changes, commit the changed sources, version/changelog, and rebuilt package together. For documentation-only changes, commit the documentation. Open a pull request against this repository's `master` branch. Describe the user-visible change and the validation performed; state explicitly when required Mudlet testing was unavailable.

See [AGENTS.md](AGENTS.md) for repository conventions and the [server fixture provenance](tests/mudlet/fixtures/README.md) for captured GMCP contracts. The [implementation log](docs/ongoing-projects/updates-upgrades.md) preserves the original server study. Documents copied from LuminariGUI are background references, as explained in [docs/README.md](docs/README.md).

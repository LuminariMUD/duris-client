# Security policy

## Reporting a vulnerability

Use GitHub's private [Report a vulnerability](https://github.com/LuminariMUD/duris-client/security/advisories/new) form for security concerns affecting this package. Include the affected package and Mudlet versions, reproduction steps, potential impact, and a minimal example with credentials and private player data removed.

Keep exploit details and sensitive logs out of public issues. Ordinary bugs and setup questions belong in the channels listed in [SUPPORT.md](SUPPORT.md).

## Version scope

Report against the [latest release](https://github.com/LuminariMUD/duris-client/releases/latest) when possible, and identify older affected versions if known. This fork does not maintain separate security backport branches or promise a fixed response time.

## Package data

The package runs Lua inside Mudlet, receives GMCP and game text, downloads zone maps from `www.newduris.com`, and saves local settings in the Mudlet profile. Automation is disabled by default. Saved automation settings may include login commands; do not include them in reports or share your entire profile.

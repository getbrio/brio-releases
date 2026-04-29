---
sidebar_position: 2
---

# Installation

The BRIO CLI is distributed as a single prebuilt binary. There is
nothing to compile and no Python toolchain required on the operator
workstation.

## Supported platforms

- macOS (Apple Silicon, `darwin-arm64`)
- macOS (Intel, `darwin-x86_64`)
- Linux (`linux-x86_64`)

## One-line install (recommended)

```bash
curl -fsSL https://github.com/getbrio/brio-releases/releases/latest/download/install.sh | bash
```

The installer:

- detects your OS + arch and downloads the matching binary
- places `brio` in `~/.local/bin` (per-user, no `sudo`)
- strips the `com.apple.quarantine` xattr on macOS so the binary launches
- prints the next step to add `~/.local/bin` to your `PATH` if it isn't already

Once installed, verify:

```bash
brio --help
```

## System-wide install

To install into a system path (e.g. `/usr/local/bin`) for all users on
the machine:

```bash
curl -fsSL https://github.com/getbrio/brio-releases/releases/latest/download/install.sh | bash -s -- --system
```

This requires `sudo`.

## Manual download

If you'd rather pin to a specific binary or your network blocks the
installer script, grab a binary directly from the
[releases page](https://github.com/getbrio/brio-releases/releases/latest):

```bash
# pick the asset that matches your machine
curl -fL -o brio \
  https://github.com/getbrio/brio-releases/releases/latest/download/brio-darwin-arm64

chmod +x brio
mv brio ~/.local/bin/brio
```

Available assets:

- `brio-darwin-arm64`
- `brio-darwin-x86_64`
- `brio-linux-x86_64`

## macOS — Gatekeeper

The binaries are unsigned for now. The installer strips quarantine
automatically. If you downloaded the binary by hand and macOS refuses
to launch it:

```bash
xattr -d com.apple.quarantine ~/.local/bin/brio
```

…or right-click the binary in Finder → **Open** → **Open**. Subsequent
runs are unblocked.

## Updating

Re-running the installer always pulls the latest release:

```bash
curl -fsSL https://github.com/getbrio/brio-releases/releases/latest/download/install.sh | bash
```

## Uninstall

```bash
rm ~/.local/bin/brio          # or /usr/local/bin/brio for system installs
brio logout                    # before removing the binary, to clear saved config
rm -rf ~/.config/brio
```

## Next

Head to [Configuration](./configuration) to sign in and approve your
device.

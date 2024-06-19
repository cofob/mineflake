<h1 align="center">Mineflake</h1>

<p align="center">
  <img src="/logo.png" alt="logo" width="256" height="256" />
</p>

Mineflake is a tool for creating and managing Minecraft servers declaratively. It is written in Rust and uses Nix for package management.

[![Support Ukraine](https://badgen.net/badge/support/UKRAINE/?color=0057B8&labelColor=FFD700)](https://www.gov.uk/government/news/ukraine-what-you-can-do-to-help)
[![license MIT](https://img.shields.io/static/v1?label=License&message=MIT&color=FE7D37)](https://github.com/nix-community/mineflake/blob/main/LICENSE)
[![matrix](https://img.shields.io/static/v1?label=Matrix&message=%23mineflake:matrix.org&color=GREEN)](https://matrix.to/#/#mineflake:matrix.org)
[![wakatime](https://wakatime.com/badge/user/ebd31081-494e-4581-b228-7619d0fe1080/project/c81c6e21-8431-4002-839f-b7e8da67c3ae.svg)](https://wakatime.com/@ebd31081-494e-4581-b228-7619d0fe1080/projects/vewdumcbno)
[![Cache derivations](https://github.com/nix-community/mineflake/actions/workflows/build.yml/badge.svg)](https://github.com/nix-community/mineflake/actions/workflows/build.yml)

---

**Source code**: [https://github.com/nix-community/mineflake](https://github.com/nix-community/mineflake)

---

## Quick start


### Installation

Mineflake can be used with Nix or without it. To use Mineflake without Nix, you need to install Rust and Cargo. To do so, run:

=== "With Nix"


    If you want to use Mineflake with Nix, you need to install Nix. To do so, run:

    ``` bash
    bash <(curl -L https://nixos.org/nix/install) # (1)
    nix run github:nix-community/mineflake -- --help # (2)
    ```

    1. This command installs Nix. If you want to install it manually, you can find more information on [Nix website](https://nixos.org/download.html).

    2. This doesn't install Mineflake to your system, it just runs it. So if you want to execute
    `mineflake apply` command, you need to run `nix run github:nix-community/mineflake -- apply` instead.

    ???+ tip "Faster builds (optional)"

        You can install Cachix to your system to significantly speed up builds:

        ``` bash
        nix-env -iA cachix -f https://cachix.org/api/v1/install
        ```

        And activate cache for Mineflake:

        ``` bash
        cachix use nix-community
        ```

    ??? warning "Note about usage with Nix"

        Mineflake uses flake feature of Nix (hence the name), so you need to enable flakes support.
        Wiki page about [Flakes](https://nixos.wiki/wiki/Flakes) has more information about it.

=== "With Executable"

    Go to [latest release page](https://github.com/nix-community/mineflake/releases/latest) and download
    the executable. Its name should be `mineflake-linux-X.Y.A` where `X.Y.A` - version. So, the script would be:

    ``` bash
    curl -L https://github.com/nix-community/mineflake/releases/download/vX.Y.A/mineflake-linux-X.Y.A --output mineflake
    chmod +x mineflake
    sudo mv mineflake /usr/local/bin # second arg can be any path, that is in $PATH enviroment variable
    mineflake --help
    ```

    ??? warning "If last command fails"

        On most systems, this wouldn't happen, although you need to add `/usr/local/bin` to your `PATH` environment variable.
        Add this to your `.bashrc` or just run the command, and it will be rollbacked after your logout:

        ```bash
        export PATH="$PATH:/usr/local/bin"
        ```

=== "With Cargo"

    ``` bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh # (1)
    cargo install mineflake # (2)
    mineflake --help
    ```

    1. This command installs Rust and Cargo. If you want to install it manually, you can find more information
    on [Rust website](https://www.rust-lang.org/tools/install).

    2. This command installs Mineflake CLI to your system. It's usually located in `~/.cargo/bin` directory.

    ??? warning "If last command fails"

        You need to add `~/.cargo/bin` to your `PATH` environment variable. To temporary fix this issue execute:

        ```bash
        export PATH="$PATH:~/.cargo/bin"
        ```

???+ info "Which method I should use?"

    If you are familiar with Nix, you should use Nix. If you are not, you should use Cargo.

    With Nix you get more control and simplier package management.
    Both methods have same package set and same features.

??? info "Windows support"

    Mineflake doesn't support Windows officially, but it can be used on Windows with some workarounds.

    There 2 ways to use Mineflake on Windows:

    1. Use WSL2. It's the easiest way to use Mineflake on Windows, as it's the same as using it on Linux. WSL also has [Nix support](https://github.com/nix-community/NixOS-WSL), so you can use Nix to install Mineflake.
    2. Install Rust and Cargo manually. You can find more information on [Rust website](https://www.rust-lang.org/tools/install).

### Note about configuration diffrences between Nix and non-Nix versions

All examples in this documentation are written for non-Nix version of Mineflake, but they are also valid for Nix version, with some exceptions:

- All packages are Nix derivations.
- You can't use files that are not in your Nix store/flake directory. For example, if you want to use `server.properties` file, you need to add it to your flake directory and use `./server.properties` path, instead of `/path/to/server.properties`.
- You can use functions and variables. For example, you can use `builtins.readFile` function to read file contents, or `mineflake.mkMfConfig` to easily add config entry.

Example of config for non-Nix version:

``` yaml linenums="1"
defaults:
  repo: &repo "https://raw.githubusercontent.com/nix-community/mineflake/8f442611468fc60cd07003447d6c7625e60a50e4/repo.json"

type: spigot

command: "java -Xms1G -Xmx1G -jar {} nogui"

package:
  type: local
  path: /path/to/paper

plugins:
  - type: repository
    repo: *repo
    name: luckperms

configs:
  - type: raw
    path: server.properties
    content: |
      enable-command-block=true
      enable-rcon=true
      rcon.password=123
      rcon.port=25575
```

Example of same config for Nix version:

``` nix linenums="1"
{ jdk, mineflake, ... }:

mineflake.buildMineflakeBin {
    type = "spigot";
    command = "${jre_headless}/bin/java -Xms1G -Xmx1G -jar {} nogui";
    package = mineflake.paper; # (1)
    plugins = with mineflake; [
        luckperms # (2)
    ];
    configs = [
        (mineflake.mkMfConfig "raw" "server.properties" ''
            enable-command-block=true
            enable-rcon=true
            rcon.password=123
            rcon.port=25575
        '') # (3)
    ];
}
```

1. Package is a derivation, so you need to use `mineflake.packagename` instead of `{ type: local, path: /path/to/packagename }`.

2. You can't use remote/repository packages. But for default repo all packages have derivations, so you can use them.

3. You can use functions. `mkMfConfig` is a function that creates config entry. It's easier and more readable than writing it manually.

### Run a simple paper server

To run a simple paper server, you need to create a file named `mineflake.yml` with the following content:

=== "Yaml (non-Nix)"

    ``` yaml linenums="1" title="mineflake.yml"
    defaults:
      repo: &repo "https://raw.githubusercontent.com/nix-community/mineflake/8f442611468fc60cd07003447d6c7625e60a50e4/repo.json"

    type: spigot

    command: "java -Xms1G -Xmx1G -jar {} nogui"

    package:
      type: local
      path: /path/to/paper

    plugins:
    - type: repository
      repo: *repo
      name: luckperms

    configs:
    - type: raw
      path: server.properties
      content: |
        enable-command-block=true
        enable-rcon=true
        rcon.password=123
        rcon.port=25575
    ```

=== "Nix"

    ``` nix linenums="1" title="server.nix"
    { jdk, mineflake, ... }:

    mineflake.buildMineflakeBin {
        type = "spigot";
        command = "c -Xms1G -Xmx1G -jar {} nogui";
        package = mineflake.paper;
        plugins = with mineflake; [
            luckperms
        ];
        configs = [
            (mineflake.mkMfConfig "raw" "server.properties" ''
                enable-command-block=true
                enable-rcon=true
                rcon.password=123
                rcon.port=25575
            '')
        ];
    }
    ```

=== "Json (non-Nix)"

    Mineflake can read json configurations too, but it's harder to write and read them.

    ``` json linenums="1" title="mineflake.json"
    {
        "type": "spigot",
        "command": "java -Xms1G -Xmx1G -jar {} nogui",
        "package": {
            "type": "local",
            "path": "/path/to/paper"
        },
        "plugins": [
            {
                "type": "repository",
                "repo": "https://raw.githubusercontent.com/nix-community/mineflake/8f442611468fc60cd07003447d6c7625e60a50e4/repo.json",
                "name": "luckperms"
            }
        ],
        "configs": [
            {
                "type": "raw",
                "path": "server.properties",
                "content": "enable-command-block=true\nenable-rcon=true\nrcon.password=123\nrcon.port=25575"
            }
        ]
    }
    ```

And then run `mineflake apply` command. It will download paper, luckperms and create a server.properties file with the specified content.

After that you can run `mineflake run` to start the server.

You can find more information about `mineflake.yml` file in [Configuration](configuration/overview.md) section.

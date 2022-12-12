# Contribution guide

This is a guide for contributing to the mineflake project. It is a work in progress,
and will be updated as the project evolves.

## Filling issues

If you have a problem with the project, or have a feature request, please file an issue
on the [issue tracker](https://github.com/nix-community/mineflake/issues). Please be as
descriptive as possible, and include any relevant information.

Please, dont post issues that are not related to the project. If you have a problem with
a specific plugin, please contact the plugin author.

Dont submit security issues here, send them to <cofob@riseup.net> or write me directly at
telegram ([@cofob](https://t.me/cofob)).

## Submitting pull requests

If you want to contribute to the project, you can submit a pull request. Please be as
descriptive as possible, and include any relevant information.

Please ensure that your pull request is properly formatted. See "Formatting" section below.

You can also submit a pull request to add yourself to the list of contributors in the
README.md file. Please include your contact information (GitHub link, Mastodon profile,
email, telegram or any other).

In pull requests, please dont include any unrelated changes. If you want to make a
cosmetic change, please submit a separate pull request.

Add description of your changes to the [CHANGELOG.md](CHANGELOG.md) file. Please follow
the format of other entries.

## Formatting

We use [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt) and rustfmt to
format the code. Before submitting a pull request, please run `nixpkgs-fmt .` and
if you changed rust code run `cd cli/ && cargo fmt && cd ..` in root folder.

You can also use editorconfig plugin for your editor to automatically change basic
code formatting.

Some files are sorted alphabetically. Please keep this order when adding new entries.

## Requesting plugin packaging

If you miss some plugin and want to request packaging of a plugin, first check if it
is already packaged or packaging issue is already filed. If it is not, please file an
issue with following information:

- Plugin name
- Plugin repository/website/SpitonMC link
- Plugin license

Then create issue with name `Package <plugin name>`.

## Adding/updating a plugin/server

If you want to add a plugin to the project, you can do it in two ways:

- Use binary release from [SpigotMC](https://www.spigotmc.org/resources/) or author repository.
  This is the easiest way to package a plugin if it is available only in binary form or if it
  hard to build from source. Please upload plugin jar to IPFS, as minecraft developers often
  remove old versions of plugins from their repositories. All CID's are pinned in our IPFS
  cluster automatically. You can use pinata, web3.storage, or any other hoster to upload your
  file. Include all required dependencies with jar file. If you using this method, use
  only binary releases from author, dont compile plugin from source by yourself.
- Build plugin from source. This is the best way to package a plugin if it is available in
  source form.

After you have packaged a plugin, you need to add its config files to the package.
After that, you can add the plugin to `default.nix` file in `pkgs/` folder.
Please ensure that all keys are sorted alphabetically, and plugin have its own folder.

Create a pull request with your changes with name in format `init/update: <plugin name> <version>`.

## Adding new features

If you want to add a new feature to the project, please create an issue first. This will
help us to discuss the feature and decide whether it is needed.

Please document your nix options and add comments to your code.

## Updating documentation

Documentation is stored in the `docs/` folder. We use markdown format. Please ensure that
your changes are passing markdownlint checks.

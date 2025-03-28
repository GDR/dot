Personal Nix Configuration for macOS
=====================================

[![NixOS Version](https://img.shields.io/badge/nixos-24.11-blue)](https://nixos.org/)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
![GitHub branch check runs](https://img.shields.io/github/check-runs/gdr/dot/master?cacheSeconds=5&link=https%3A%2F%2Fgithub.com%2FGDR%2Fdot%2Fsettings%2Factions)

Overview
--------

This repository contains my personal Nix configuration for managing packages, system configurations, and development environments on macOS using Nix and NixOS.

Table of Contents
-----------------

1. [Getting Started](#getting-started)
2. [Folder Structure](#folder-structure)
3. [Usage](#usage)
4. [Customization](#customization)
5. [Contributing](#contributing)
6. [License](#license)

Getting Started
---------------

To use this configuration, you'll need to have Nix installed on your macOS system. If you haven't already installed Nix, you can do so by following the instructions in the [Nix documentation](https://nixos.org/download.html).

Clone this repository to your local machine:

```bash
git clone https://github.com/gdr/dot.git
```

Folder Structure
----------------
flakes/: Contains the Nix flakes used for managing system configurations, packages, and environments.
config/: Stores various configuration files used by NixOS and other tools.
scripts/: Optional directory for storing any custom scripts used for managing or automating tasks related to Nix.

Usage
-----
### System Configuration
To apply system configurations, run:

```bash
nixos-rebuild switch --flake .#mac-italy
```
### Package Installation
To install packages, use the nix command with flakes:

```bash
nix develop github:gdr/dot#packages
```
### Development Environment
To set up a development environment, use flakes:

```bash
nix develop github:gdr/dot#development
```
Customization
-------------
Feel free to customize any aspect of this configuration to suit your needs. You can modify the configuration files, add or remove packages, or adjust system settings as required.

Contributing
------------
Contributions are welcome! If you have any improvements or suggestions, please feel free to open an issue or submit a pull request.

License
-------------
This project is licensed under the MIT License - see the [LICENSE](https://github.com/GDR/dot/blob/mac-italy/LICENSE) file for details.

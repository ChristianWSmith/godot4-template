# Godot 4 Template

A fast way to get the core of a project stood up.

## Getting Started
- Create a new repository using this repo template.
- Run `start.sh` using bash. Windows users will need to `choco install wget zip`.
- Remove whatever you don't need.
- Develop your game!


## Overview
This Godot 4 Template is a modular, manager-driven framework designed to streamline game development. It provides a full suite of systems out of the box, including audio, video, input, UI, scene management, game state, saves, and Steam integration, all coordinated via a centralized initialization manager.

Key features include:

- **Manager-based architecture:** Each subsystem is encapsulated in a dedicated manager, ensuring clean separation of concerns and easy extensibility.
- **Out-of-the-box CI/CD:** Automated testing and build pipelines ready to integrate with your workflow.
- **Steam integration:** Cloud saves, file reconciliation, and Steam API support are built in.
- **Code obfuscation:** GDMaim integration allows for secure, obfuscated builds without extra setup.
- **Godot Versioning:** Change the contents of `.godot-version`, and `start.sh`/`build.sh` will automatically start using it.
- **Git LFS:** Assets separated into `assets/src/` and `assets/bin/` so that your repo doesn't get clogged with binaries.
- **Event-driven design:** The EventBus system simplifies cross-manager communication and reactive programming.
- **Trait-based Polymorphism:** Basically a more robust version of duck-typing.
- **Example:** Small example "game" showcasing the usage of these features.

This template is intended to accelerate development while providing a solid, maintainable foundation for your Godot 4 projects.

# Thank You
- [GDMaim](https://github.com/cherriesandmochi/gdmaim)
- [GodotSteam](https://godotsteam.com/)
- [mrpoly](https://opengameart.org/users/mrpoly)
- [Dizzy Crow](https://opengameart.org/users/dizzy-crow)

# License
[MIT](./LICENSE)

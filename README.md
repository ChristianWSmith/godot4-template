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

## Init Process
Here's an overview of what happens during the startup of the game.  Extend as needed.

```
╰─ entrypoint.gd
   ├─ InitManager
   │  ├─ EventBus
   │  │  ╰─ Clears subscribers, waiters, and once wrappers
   │  ├─ Log
   │  │  ├─ Handles CLI arguments
   │  │  ╰─ Sets up log file if applicable
   │  ├─ Traits
   │  │  ╰─ Registers all classes that extend Trait as Traits
   │  ├─ SteamManager
   │  │  ├─ Connects to Steam
   │  │  ├─ Starts reconciliation background timer
   │  │  ╰─ Errors out if Steam is required
   │  ├─ VideoManager
   │  │  ╰─ Subscribes to changes in video settings
   │  ├─ SaveManager
   │  │  ├─ Loads local save slots
   │  │  ├─ Loads Steam save slots
   │  │  ├─ Migrates save versions if needed
   │  │  ╰─ Syncs with steam
   │  ├─ GameState
   │  │  ├─ Clears loaded data
   │  │  ╰─ Subscribes to scene changes for per-scene persistence
   │  ├─ InputManager
   │  │  ╰─ Subscribes to changes in input settings
   │  ├─ AudioManager
   │  │  ╰─ Subscribes to changes in audio settings
   │  ├─ SceneManager
   │  │  ├─ Sets up the loading screen
   │  │  ╰─ Sets up the global scene change fade layer
   │  ├─ UIManager
   │  │  ├─ Sets up global throbber
   │  │  ╰─ Loads all UI scenes
   │  ├─ GameplayManager
   │  │  ╰─ Subscribes to changes in gameplay settings
   │  ├─ GraphicsManager
   │  │  ├─ Sets up FPS label
   │  │  ╰─ Subscribes to changes in graphics settings
   │  ╰─ SettingsManager
   │     ├─ Loads local settings
   │     ├─ Loads Steam settings
   │     ├─ Performs migrations as needed
   │     ├─ Syncs with Steam
   │     ╰─ Emits settings changes, triggers subscribers
   ╰─ SceneManager
      ╰─ Changes scene to Launch Scene
```

# Thank You
- [GDMaim](https://github.com/cherriesandmochi/gdmaim)
- [GodotSteam](https://godotsteam.com/)
- [mrpoly](https://opengameart.org/users/mrpoly)
- [Dizzy Crow](https://opengameart.org/users/dizzy-crow)

# License
[MIT](./LICENSE)

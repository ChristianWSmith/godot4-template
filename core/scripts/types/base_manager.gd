## BaseManager
##
## Abstract base type for all system managers. Provides a common initialization
## entry point and shared behavior for derived managers used by the engine.
##
## Intended to be extended; this class itself performs only minimal setup.
extends Node
class_name BaseManager


## Initializes the manager and returns an [code]Error[/code] status.
## Derived managers should override this to perform their own setup logic.
func initialize() -> Error:
	print("[%s] Initializing..." % name)
	return OK

# Package

version       = "0.1.0"
author        = "Sergey Kospanov"
description   = "Idle life-sim game"
license       = "MIT"

bin = @["living_world"]
installExt = @["nim"]

# Dependencies

requires "nim >= 0.20.0"
requires "bcrypt 0.2.1"
requires "perlin 0.6.1"
requires "websocket#head"

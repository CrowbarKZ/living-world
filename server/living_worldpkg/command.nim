import json, tables
import planet


type
    Command = object
        name: string
        token: string
        data: JsonNode


func response(kind: string, success: bool, data: JsonNode): JsonNode =
    return %*{"kind": kind, "success": success, "data": data}


proc getPlanetData(command: Command, planets: TableRef[string, Planet]): JsonNode =
    var p: Planet = planets[command.token]
    p.process
    return response("full_update", true, %p)


proc processCommand*(commandStr: string, planets: TableRef[string, Planet]): JsonNode =
    ## processes command and returns Response
    var command: Command
    try:
        command = parseJson(commandStr).to(Command)
    except KeyError, JsonParsingError:
        echo "failed to parse command: ", commandStr, " ", getCurrentExceptionMsg()
        return response("info", false, %"bad_payload")

    if not (command.token in planets):
        return response("info", false, %"such client is not logged in")

    case command.name:
        of "get_planet_data":
            return getPlanetData(command, planets)
        # of "pause":
        #     p.pause
        # of "unpause":
        #     p.unpause
        # of "get_cell_info":
        #     let pos: Vector2 = (command["x"].getInt, command["y"].getInt)
        #     let response = %*{
        #         "type": "cell_info",
        #         "data": p.getCellJson(pos),
        #     }
        #     await ws.sendText($response)
        # of "change_cell":
        #     let pos: Vector2 = (command["x"].getInt, command["y"].getInt)
        #     p.setCellKind(command["kind"].getInt.CellKind, pos)
        # of "create_entity":
        #     let pos: Vector2 = (command["x"].getInt, command["y"].getInt)
        #     let kind: EntityKind = command["kind"].getInt.EntityKind;
        #     p.createEntity(kind, pos)
        else:
            return response("info", false, %"unknown_command")

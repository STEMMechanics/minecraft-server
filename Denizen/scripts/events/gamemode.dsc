gamemode_event:
    type: world
    debug: false
    events:
        on player changes gamemode:
            - wait 10t
            - choose <player.gamemode>:
                - case survival:
                    - execute as_server "pweather reset <player.name>"
                    - execute as_server "ptime reset <player.name>"
                - case adventure:
                    - execute as_server "pweather reset <player.name>"
                    - execute as_server "ptime reset <player.name>"
                - case spectator:
                    - execute as_server "pweather reset <player.name>"
                    - execute as_server "ptime reset <player.name>"

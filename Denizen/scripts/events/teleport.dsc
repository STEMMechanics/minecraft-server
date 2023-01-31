teleport_event:
    type: world
    debug: false
    events:
        on player teleports:
            - if <context.origin.world.if_null[null]> != <context.destination.world.if_null[null]> && <context.destination.world.name.if_null[null]> != world:
                - wait 40t
                - if <player.location.world.name.if_null[null]> != world:
                    - playsound <player> sound:ENTITY_EXPERIENCE_ORB_PICKUP pitch:1.2
                    - narrate "<dark_aqua>To teleport back to the lobby, use the command <white>/lobby"

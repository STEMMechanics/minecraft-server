lobby_cmd:
    type: command
    name: lobby
    description: Teleports you back to the lobby
    usage: /lobby
    aliases:
    - hub
    script:
    - if <player.location.world.name.starts_with[bw_].if_null[false]>:
        - execute as_player "bw leave"
    - else if <player.location.world.name.if_null[null]> == oneblock:
        - execute as_player "ob leave"
    - else if <player.location.world.name.if_null[null]> == bridge:
        - execute as_player "tb leave"
    - else:
        - execute as_server "tpp world <player.name>"
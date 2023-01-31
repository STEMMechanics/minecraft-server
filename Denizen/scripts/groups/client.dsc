groups_event:
    type: world
    debug: false
    events:
        on player joins:
            - wait 10t
            - if <player.is_online>:
                - if <player.name.starts_with[*]>:
                    - execute as_server "lp user <player.uuid> group add client_bedrock"
                - else:
                    - execute as_server "lp user <player.uuid> group add client_java"

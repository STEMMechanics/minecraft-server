infobar_events:
    type: world
    debug: false
    events:
        on scripts loaded:
            - run stemmech_feature_register def.id:infobar

        on player walks priority:1000:
            - ratelimit <player> 5t
            - if <player.has_flag[infobar.hide]>:
                - stop

            - define direction_map:<map[north=N;northeast=NE;east=E;southeast=SE;south=S;southwest=SW;west=W;northwest=NW]>
            - define new_direction:<[direction_map].get[<context.new_location.direction>].if_null[NA]>
            - if <[new_direction]> != <player.flag[infobar.direction].if_null[null]>:
                - flag <player> infobar.direction:<[new_direction]>
                - run infobar_update_single def:<player>|<context.new_location>

        after player logs in:
            # 2023-02-10 CLEANUP
            - flag <player> infobar:!
            # END-CLEANUP

            - ~run infobar_update_player_world def:<player>|<player.location>
            - run infobar_update_single def:<player>|<player.location>

        after player teleports:
            - ~run infobar_update_player_world def:<player>|<context.destination>
            - run infobar_update_single def:<player>|<context.destination>

        on system time secondly every:3:
            - run infobar_update

infobar_initalize:
    type: task
    debug: false
    script:
        - foreach <server.online_players> as:target_player:
            - run infobar_update_player_world def:<[target_player]>

        - run stemmech_feature_set_ready def.id:infobar

        - ~run stemmech_feature_wait_until_ready def.id:tabcomplete def.path:<script>|tabcomplete

    tabcomplete:
        - run tabcomplete_completion def:infobar|show
        - run tabcomplete_completion def:infobar|hide
        - run tabcomplete_completion def:infobar|toggle

infobar_update:
    type: task
    debug: false
    definitions: target_player
    script:
        - define player_list:<server.online_players>

        - if <[target_player].exists>:
            - define player_list:<list[<[target_player]>]>

        - foreach <[player_list]> as:target_player:
            - run infobar_update_single def:<[target_player]>

infobar_update_single:
    type: task
    debug: false
    definitions: target_player|target_location
    script:
        - if !<[target_player].is_online> || <[target_player].has_flag[infobar.hide]>:
            - stop

        - if !<[target_location].exists>:
            - define target_location:<[target_player].location>

        - define world:<[target_player].flag[infobar.world].if_null[NA]>
        - define direction:<[target_player].flag[infobar.direction].if_null[NA]>

        - define time:<[target_location].world.flag[stemmech.time].get[12h].if_null[0]>.<[target_location].world.flag[stemmech.time].get[15m].if_null[0]><[target_location].world.flag[stemmech.time].get[ap].if_null[]>

        - define bossbar_id:<[target_player].uuid>_infobar
        - define "bossbar_title:<&chr[E80A]> <[world]> <&chr[E381]> <[time]> <&chr[E388]> <[direction]>"

        - if !<[target_player].bossbar_ids.contains[<[bossbar_id]>].if_null[false]>:
            - if <server.current_bossbars.contains[<[bossbar_id]>]>:
                - bossbar remove <[bossbar_id]>
            - bossbar create <[bossbar_id]> color:white title:<[bossbar_title]> players:<[target_player]>
        - else:
            - bossbar update <[bossbar_id]> title:<[bossbar_title]> players:<[target_player]>

infobar_update_player_world:
    type: task
    debug: false
    definitions: target_player|target_location
    script:
        - if <[target_player].has_flag[infobar.hide]>:
            - stop

        - if !<[target_location].exists>:
            - define target_location:<[target_player].location>

        - define world_name:<[target_location].world.name>
        - if <[world_name]> == world:
            - define world_name:lobby

        - flag <[target_player]> infobar.world:<[world_name].replace_text[_].with[<&sp>].to_titlecase>

infobar:
    type: command
    debug: false
    name: infobar
    description: Shows/Hides the Info Bar
    usage: /infobar
    permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
    tab complete:
        - if <proc[stemmech_feature_is_ready].context[infobar|tabcomplete]>:
            - define command:infobar
            - determine <proc[tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
    script:
        - if !<context.server.if_null[false]>:
            - if !<player.has_flag[infobar.hide]>:
                - flag player infobar.hide
                - if <player.bossbar_ids.contains[<player.uuid>_infobar]>:
                    - bossbar remove <player.uuid>_infobar
            - else:
                - flag player infobar.hide:!
                - run infobar_update
        - else:
            - narrate <server.flag[stemmech.messages.command_only_players]>
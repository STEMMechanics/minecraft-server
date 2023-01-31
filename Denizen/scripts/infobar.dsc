stemmechw_infobar:
    type: world
    debug: false
    events:
        on scripts loaded:
            - run stemmecht_infobar_load

        on player walks priority:1000:
            - ratelimit <player> 5t
            - if <player.has_flag[stemmech.infobar.hide]>:
                - stop

            - define direction_map:<map[north=N;northeast=NE;east=E;southeast=SE;south=S;southwest=SW;west=W;northwest=NW]>
            - define new_direction:<[direction_map].get[<context.new_location.direction>].if_null[NA]>
            - if <[new_direction]> != <player.flag[stemmech.infobar.direction].if_null[null]>:
                - flag <player> stemmech.infobar.direction:<[new_direction]>
                - run stemmecht_infobar_update_single def:<player>|<context.new_location>

        after player logs in:
            - ~run stemmecht_infobar_update_player_world def:<player>|<player.location>
            - run stemmecht_infobar_update_single def:<player>|<player.location>

        after player teleports:
            - ~run stemmecht_infobar_update_player_world def:<player>|<context.destination>
            - run stemmecht_infobar_update_single def:<player>|<context.destination>

        on system time secondly every:3:
            - run stemmecht_infobar_update

stemmecht_infobar_load:
    type: task
    debug: false
    script:
            - foreach <server.online_players> as:target_player:
                - run stemmecht_infobar_update_player_world def:<[target_player]>

            - if <server.scripts.parse[name].contains[stemmechw_tabcomplete]>:
                - waituntil max:10s <server.has_flag[stemmech.feature.tabcomplete].or[<server.has_flag[stemmech.fail.tabcomplete]>]>
                - if <server.has_flag[stemmech.feature.tabcomplete]>:
                    - run stemmecht_tabcomplete_completion def:infobar|show
                    - run stemmecht_tabcomplete_completion def:infobar|hide
                    - run stemmecht_tabcomplete_completion def:infobar|toggle

stemmecht_infobar_update:
    type: task
    debug: false
    definitions: target_player
    script:
        - define player_list:<server.online_players>

        - if <[target_player].exists>:
            - define player_list:<list[<[target_player]>]>

        - foreach <[player_list]> as:target_player:
            - run stemmecht_infobar_update_single def:<[target_player]>

stemmecht_infobar_update_single:
    type: task
    debug: false
    definitions: target_player|target_location
    script:
        - if !<[target_player].is_online> || <[target_player].has_flag[stemmech.infobar.hide]>:
            - stop

        - if !<[target_location].exists>:
            - define target_location:<[target_player].location>

        - define world:<[target_player].flag[stemmech.infobar.world].if_null[NA]>
        - define direction:<[target_player].flag[stemmech.infobar.direction].if_null[NA]>

        - define time:<[target_location].world.flag[stemmech.common.time].get[12h].if_null[0]>.<[target_location].world.flag[stemmech.common.time].get[15m].if_null[0]><[target_location].world.flag[stemmech.common.time].get[ap].if_null[]>

        - define bossbar_id:<[target_player].uuid>_infobar
        - define "bossbar_title:<&chr[E80A]> <[world]> <&chr[E381]> <[time]> <&chr[E388]> <[direction]>"

        - if !<[target_player].bossbar_ids.contains[<[bossbar_id]>].if_null[false]>:
            - if <server.current_bossbars.contains[<[bossbar_id]>]>:
                - bossbar remove <[bossbar_id]>
            - bossbar create <[bossbar_id]> color:white title:<[bossbar_title]> players:<[target_player]>
        - else:
            - bossbar update <[bossbar_id]> title:<[bossbar_title]> players:<[target_player]>

stemmecht_infobar_update_player_world:
    type: task
    debug: false
    definitions: target_player|target_location
    script:
        - if <[target_player].has_flag[stemmech.infobar.hide]>:
            - stop

        - if !<[target_location].exists>:
            - define target_location:<[target_player].location>

        - define world_name:<[target_location].world.name>
        - if <[world_name]> == world:
            - define world_name:lobby

        - flag <[target_player]> stemmech.infobar.world:<[world_name].replace_text[_].with[<&sp>].to_titlecase>

stemmechc_infobar:
    type: command
    debug: false
    name: infobar
    description: Shows/Hides the Info Bar
    usage: /infobar
    permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
    tab complete:
        - if <server.scripts.parse[name].contains[stemmechw_tabcomplete]>:
            - define command:infobar
            - determine <proc[stemmechp_tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
    script:
        - if !<context.server.if_null[false]>:
            - if !<player.has_flag[stemmech.infobar.hide]>:
                - flag player stemmech.infobar.hide
                - if <player.bossbar_ids.contains[<player.uuid>_infobar]>:
                    - bossbar remove <player.uuid>_infobar
            - else:
                - flag player stemmech.infobar.hide:!
                - run stemmecht_infobar_update
        # - else:
        #     - narrate <server.flag[stemmech.core.message.command_only_players]>
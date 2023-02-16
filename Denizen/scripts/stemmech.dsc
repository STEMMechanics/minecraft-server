stemmech_events:
    type: world
    debug: false
    events:
        on scripts loaded:
            - run stemmech_initalize

        on system time secondly server_flagged:stemmech.loaded:
            - flag server stemmech.epoch:++
            - foreach <server.worlds> as:target_world:
                - flag <[target_world]> stemmech.time:<proc[stemmech_world_time_map].context[<[target_world]>]>

        on system time minutely every:10 server_flagged:stemmech.loaded:
            - flag server stemmech.log_time:<util.time_now.format[YYYY-MM-dd]>
            - run stemmech_yaml_save_all

        on system time hourly server_flagged:stemmech.loaded:
            - flag server stemmech.log_time:<util.time_now.format[YYYY-MM-dd]>


stemmech_initalize:
    type: task
    debug: false
    script:
        - flag server stemmech:!

        - flag server "stemmech.messages.command_only_players:This command is only available for players"
        - flag server stemmech.log_time:<util.time_now.format[YYYY-MM-dd]>

        - flag server stemmech.loaded

stemmech_feature_register:
    type: task
    debug: false
    definitions: id|initalize|requires
    script:
        - wait 2t
        - if <queue.definitions.contains[id]>:
            - waituntil max:1s <server.has_flag[stemmech.loaded]>
            - if <server.has_flag[stemmech.loaded]>:
                - if <[requires].exists>:
                    - waituntil max:5s <proc[stemmech_feature_is_ready].context[<[requires]>]>
                    - if !<proc[stemmech_feature_is_ready].context[<[requires]>]>:
                        - announce to_console "<red><[id]>: Timeout waiting for dependencies to be ready"
                        - stop

                - flag server stemmech.features.<[id]>:loading
                - if <util.scripts.parse[name].contains[<[id]>_initalize]>:
                    - run <[initalize].exists.if_true[<[initalize]>].if_false[<[id]>_initalize]> def.id:<[id]>
            - else:
                - announce to_console "<red><[id]>: Timeout waiting for STEMMech to load"

stemmech_feature_set_ready:
    type: task
    debug: false
    definitions: id|state
    script:
        - if <queue.definitions.contains[id]>:
            - if !<[state].exists> || <[state].is_in[true|ready]>:
                - flag server stemmech.features.<[id]>:ready
            - else:
                - flag server stemmech.features.<[id]>:failed

stemmech_feature_is_ready:
    type: procedure
    debug: false
    script:
        - define id_list:<queue.definition_map.exclude[raw_context].values.if_null[<list>]>
        - if <[id_list].size> > 0:
            - foreach <[id_list]>:
                - if <server.flag[stemmech.features.<[value]>].equals[ready].if_null[false]> == false:
                    - determine false
            - determine true
        - determine false

stemmech_feature_has_failed:
    type: procedure
    debug: false
    definitions: id
    script:
        - determine <server.flag[stemmech.features.<[id]>].equals[failed].if_null[false]>

stemmech_feature_wait_until_ready:
    type: task
    debug: false
    definitions: id|task|script|path
    script:
        - if <[id].exists> && <server.has_flag[stemmech.features.<[id]>]>:
            - waituntil <server.flag[stemmech.features.<[id]>].equals[loading].not> max:1s
            
            - if <[task].exists>:
                - run <[task]>
            - else if <[script].exists> && <[path].exists>:
                - run <[script]> path:<[path]>
            - else if <[path].exists> && <[path].object_type> == LIST && <[path].size> >= 2:
                - run <[path].get[1]> path:<[path].get[2]>

            - determine <server.flag[stemmech.features.<[id]>].equals[ready]>
        - determine false

stemmech_yaml_load:
    type: task
    debug: false
    definitions: id|type
    script:
        - if !<[type].exists>:
            - define type:config

        - if <yaml.list.contains[<[id]>]>:
            - yaml id:<[id]> unload
        - if <util.has_file[<[type]>/<[id]>.yml]>:
            - yaml id:<[id]> load:<[type]>/<[id]>.yml
        - else:
            - yaml id:<[id]> create
        
        - if !<server.has_flag[stemmech.yaml.<[id]>]>:
            - flag server stemmech.yaml.<[id]>:<[type]>/<[id]>.yml

stemmech_yaml_save:
    type: task
    debug: false
    definitions: id
    script:
        - if <server.has_flag[stemmech.yaml.<[id]>]>:
            - yaml id:<[id]> savefile:<server.flag[stemmech.yaml.<[id]>]>

stemmech_yaml_save_all:
    type: task
    debug: false
    script:
        - foreach <server.flag[stemmech.yaml].if_null[<map>]>:
            - yaml id:<[key]> savefile:<[value]>

stemmech_world_time_formatted:
    type: procedure
    debug: false
    definitions: target_world
    script:
        - define world_time:<proc[stemmech_world_time_map].context[<[target_world]>]>
        - determine <[world_time].get[h]>:<[world_time].get[m]>

stemmech_world_time_map:
    type: procedure
    debug: false
    definitions: target_world
    script:
        - define world_time:<duration[<[target_world].time.duration.in_seconds.mul[72]>s].add[6h]>
        - define hours:<[world_time].in_hours.round_down>
        - define mins:<[world_time].in_minutes.round_down.sub[<[hours].mul[60]>]>

        - define apm:AM
        - if <[hours]> > 23:
            - define hours:-:24
        - define 12h:<[hours]>
        - if <[hours]> < 10:
            - define hours:0<[hours]>
        - if <[12h]> > 12:
            - define 12h:<[12h].sub[12]>
            - define apm:PM

        - if <[mins]> < 10:
            - define mins:0<[mins]>

        - define 15m:<[mins].div[15].round_down.mul[15]>
        - if <[15m]> == 0:
            - define 15m:00

        - determine <map[h=<[hours]>;m=<[mins]>;15m=<[15m]>;12h=<[12h]>;ap=<[apm]>]>

stemmech_determination_mapper:
    type: procedure
    debug: false
    script:
        - define determination:<queue.definition_map.exclude[raw_context]>
        - define data:<map>

        - if <[determination]> != null && <[determination].size> > 0:
            - foreach <[determination]>:
                - if <[value].object_type> == element:
                    - if <[value].contains[:]>:
                        - define data:<[data].with[<[value].before[:]>].as[<[value].after[:]>]>
                    - else if <[value].is_decimal>:
                        - define data:<[data].with[decimal].as[<[value]>]>
                    - else if <[value]> == cancelled:
                        - define data:<[data].with[cancelled].as[true]>
                    - else:
                        - define data:<[data].with[text].as[<[value]>]>
                - else:
                    - define data:<[data].with[<[value].object_type>].as[<[value]>]>

        - determine <[data]>
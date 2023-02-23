hologram_data:
    type: data
    debug: false
    offsets:
        hologram_base: 0.2
        hologram_line: 0.4

hologram_events:
    type: world
    debug: false
    events:
        on scripts loaded:
            - run stemmech_feature_register def.id:hologram
        
        on player walks:
            - if <proc[stemmech_feature_is_ready].context[hologram].if_null[false]>:
                - run hologram_spawn_update def.player:<player>

hologram_initalize:
    type: task
    debug: false
    script:
        - run stemmech_feature_set_ready def.id:hologram

hologram_delete:
    type: task
    debug: false
    definitions: id
    script:
        - flag server hologram.list.<[id]>:!
        - foreach <server.players.filter[has_flag[hologram.list.<[id]>]]>:
            - foreach <[value].flag[hologram.list.<[id]>]>:
                - remove <[value]>
            - flag <[value]> hologram.list.<[id]>:!

hologram_create:
    type: task
    debug: false
    definitions: id|location|lines
    script:
        - if <server.has_flag[hologram.list.<[id]>]>:
            - ~run hologram_delete def.id:<[id]>

        # - define defs:<queue.definition_map.exclude[raw_context].values.parse[escaped]>
        # - define id:<[defs].get[1]>
        # - define location:<[defs].get[2]>
        # - define lines:<[defs].remove[1|2]>

        - flag server hologram.list.<[id]>.location:<[location].round>
        - flag server hologram.list.<[id]>.lines:<[lines]>

        - foreach <server.online_players>:
            - run hologram_spawn_update def:<[value]>

hologram_update:
    type: task
    debug: false
    definitions: id|lines
    script:
        - if <server.has_flag[hologram.list.<[id]>]>:
            - foreach <server.players.filter[has_flag[hologram.list.<[id]>]]> as:target_player:
                - foreach <[target_player].flag[hologram.list.<[id]>].if_null[<list>]>:
                    - define removal_list:<[value].filter_tag[<[target_player].fake_entities.contains[<[filter_value]>]>]>
                    - remove <[removal_list]>
                - flag <[value]> hologram.list.<[id]>:!

            - flag server hologram.list.<[id]>.lines:<[lines]>

            - foreach <server.online_players>:
                - run hologram_spawn_update def:<[value]>

hologram_spawn_update:
    type: task
    debug: false
    definitions: player
    script:
        - define configuration:<script[hologram_data].data_key[]>

        # iterate holograms in the same world as the player and the player should see them (100 blocks away)
        - foreach <server.flag[hologram.list].filter_tag[<[filter_value].get[location].world.equals[<[player].location.world>].and[<[filter_value].get[location].distance_squared[<[player].location>].is_less_than[500]>]>].if_null[<map>]> key:id as:hologram_data:
            # remove entire id if any are despawned
            - if !<[player].has_flag[hologram.list.<[id]>]> || <[player].flag[hologram.list.<[id]>].filter[is_spawned.equals[false]].count.if_null[0]> > 0:
                - foreach <[player].flag[hologram.list.<[id]>].if_null[<list>]>:
                    - remove <[value]>
                - flag <[player]> hologram.list.<[id]>:!

                - define spawned_stands <list>
                - foreach <[hologram_data].get[lines]> as:line:
                    - define stand <entity[armor_stand].with[marker=true;visible=false;invulnerable=true;custom_name_visible=true;custom_name=<[line]>]>
                    - define offset <[loop_index].mul[<[configuration.offsets.hologram_line]>].add[<[configuration.offsets.hologram_base]>]>
                    - fakespawn <[stand]> <[hologram_data].get[location].below[<[offset]>]> d:5m save:stand players:<server.online_players>
                    - define spawned_stands:->:<entry[stand].faked_entity>
                
                - flag <[player]> hologram.list.<[id]>:<[spawned_stands]>

pvp_events:
    type: world
    debug: false
    events:
        on scripts loaded:
            - run stemmech_feature_register def.id:pvp

        on player teleports:
            - if <context.destination.world.name> == pvp:
                - if <context.origin.world.name> != pvp:
                    - if <player.has_flag[pvp]>:
                        - narrate "You need to wait <player.flag_expiration[pvp].duration_since[<util.time_now>].formatted> before you can re-enter PvP"
                        - determine DESTINATION:<world[world].spawn_location>
                    - else if !<server.has_flag[pvp.ready]>:
                        - narrate "The PvP world is still being setup..."
                        - determine DESTINATION:<world[world].spawn_location>
                    - else:
                        - wait 10t
                        - inventory clear
                        - heal
                        - feed
                        - if <world[pvp].players.size> == 1:
                            - run pvp_shopkeepers_setup
            - else if <context.origin.world.name> == pvp:
                - flag <player> pvp expire:1m
                - run pvp_restore
            
        on player dies:
            - if <player.location.world.name> == pvp:
                - flag <player> pvp expire:1m

        on player respawns flagged:pvp:
            - if <player.location.world.name> == pvp:
                - execute as_server "tpp world <player.name>"
                - run pvp_restore

        on player quits:
            - if <player.location.world.name> == pvp:
                - flag <player> pvp expire:1m
                - run pvp_restore

        on player joins:
            - wait 10t
            - if <player.location.world.name> == pvp:
                - execute as_server "tpp world <player.name>"
        
        on system time secondly every:5:
            - if <world[pvp].players.size.if_null[0]> > 0:
                - foreach <server.flag[pvp.spawners.copper].if_null[<list>]>:
                    - define loc:<location[<[value]>].add[-2,-2,-2].to_cuboid[<location[<[value]>].add[2,2,2]>].spawnable_blocks.random.if_null[<location[<[value]>]>]>
                    - drop copper_ingot <[loc]>

        on system time minutely:
            - if <world[pvp].players.size.if_null[0]> > 0:
                - foreach <server.flag[pvp.spawners.iron].if_null[<list>]>:
                    - define loc:<location[<[value]>].add[-2,-2,-2].to_cuboid[<location[<[value]>].add[2,2,2]>].spawnable_blocks.random.if_null[<location[<[value]>]>]>
                    - drop iron_ingot <[loc]>

        on system time minutely every:5:
            - if <world[pvp].players.size.if_null[0]> > 0:
                - foreach <server.flag[pvp.spawners.gold].if_null[<list>]>:
                    - define loc:<location[<[value]>].add[-2,-2,-2].to_cuboid[<location[<[value]>].add[2,2,2]>].spawnable_blocks.random.if_null[<location[<[value]>]>]>
                    - drop gold_ingot <[loc]>
        
        # on system time minutely every:10:
        #     - if <world[pvp].players.size> > 0:
        #         - run pvp_shopkeepers_setup

pvp_initalize:
    type: task
    debug: false
    script:
        - ~run stemmech_yaml_load def.id:pvp
        - run stemmech_feature_set_ready def.id:pvp
        
        - ~run stemmech_feature_wait_until_ready def.id:tabcomplete def.path:<script>|tabcomplete
    
    tabcomplete:
        - run tabcomplete_completion def:pvp|spawner|add|copper
        - run tabcomplete_completion def:pvp|spawner|add|iron
        - run tabcomplete_completion def:pvp|spawner|add|gold
        - run tabcomplete_completion def:pvp|spawner|remove
        - run tabcomplete_completion def:pvp|shopkeeper|add
        - run tabcomplete_completion def:pvp|shopkeeper|remove

pvp_restore:
    type: task
    debug: false
    script:
        - wait 10t
        - if <world[pvp].players.size> == 0:
            - flag server pvp.ready:!
            - execute as_server "worlds delete pvp"
            - wait 10t
            - execute as_server "worlds copy pvp_template pvp"
            - wait 10t
            - execute as_server "worlds load pvp"
            - wait 10t
            - flag server pvp.ready

pvp_shopkeepers_setup:
    type: task
    debug: false
    script:
        - foreach <server.flag[pvp.shopkeepers]> as:shopkeeper_data:
            - if <[shopkeeper_data].keys.contains[npc]>:
                - if !<server.npcs.contains[<[shopkeeper_data].get[npc]>]>:
                    - flag server pvp.shopkeepers[<[loop_index]>]:<[shopkeeper_data].exclude[npc]>
                - else if !<[shopkeeper_data].get[npc].is_spawned>:
                    - spawn <[shopkeeper_data].get[npc]> <[shopkeeper_data].get[location]>

            - if !<[shopkeeper_data].keys.contains[npc]>:
                - create villager Shopkeeper <[shopkeeper_data].get[location]> save:result

                - define new_shopkeeper_data:<[shopkeeper_data].with[npc].as[<entry[result].created_npc>]>
                - flag server pvp.shopkeepers[<[loop_index]>]:<[new_shopkeeper_data]>

                - assignment set script:pvp_shopkeepers npc:<entry[result].created_npc>
                - adjust <entry[result].created_npc> lookclose:true

pvp_shopkeepers:
    type: assignment
    debug: false
    actions:
        on click:
            - define trades:<list[]>

            - foreach <yaml[pvp].read[pvp.shops]> key:category as:items:
                - foreach <[items]>:
                    - define item:<item[<[value].get[item]>].if_null[null]>
                    - if <[item]> != null:
                        - define inputs:<list>
                        
                        - if <[value].keys.contains[display-name]>:
                            - adjust def:item display:<[value].get[display-name]>
                        - if <[value].keys.contains[quantity]>:
                            - adjust def:item quantity:<[value].get[quantity]>
                        - if <[value].keys.contains[enchants]>:
                            - adjust def:item enchantments:<[value].get[enchants].to_map[,]>

                        - if <[value].keys.contains[potion-type]>:
                            - define potion_effects:<map[type=<[value].get[potion-type]>]>
                            - if <[value].keys.contains[potion-upgraded]> && <[value].get[potion-upgraded]>:
                                - define potion_effects:<[potion_effects].with[upgraded].as[true]>
                            - if <[value].keys.contains[potion-extended]> && <[value].get[potion-extended]>:
                                - define potion_effects:<[potion_effects].with[extended].as[true]>

                            - adjust def:item potion_effects:<[potion_effects]>

                        - foreach <[value].get[cost]>:
                            - define inputs:->:<[key]>[quantity=<[value]>]

                        - define trades:->:trade[result=<[item]>;inputs=<[inputs]>;max_uses=9999]

            - opentrades <[trades]> "title:Shopkeeper"

pvp_command:
    type: command
    debug: false
    name: pvp
    description: PvP world commands
    usage: /pvp
    permission: stemmech.pvp
    permission message: <&8>[<&c><&l>!<&8>] <&c>You do not have access to that command
    tab complete:
        - if <proc[stemmech_feature_is_ready].context[pvp|tabcomplete]>:
            - define command:pvp
            - determine <proc[tabcomplete].context[<list[<[command]>].include_single[<context.raw_args.escaped>]>]>
    script:
        - choose <context.args.get[1].if_null[null]>:
            - case spawner:
                - choose <context.args.get[2].if_null[null]>:
                    - case add:
                        - define type:<context.args.get[3].if_null[null]>
                        - if <[type].is_in[copper|iron|gold]>:
                            - flag server pvp.spawners.<[type]>:->:<player.location.simple>
                            - narrate "Spawner added"
                    - case rem remove:
                        - define count:0
                        - foreach <server.flag[pvp.spawners]> key:spawner_type as:spawner_location_list:
                            - foreach <[spawner_location_list]> as:spawner_location:
                                - if <player.location.distance_squared[<[spawner_location]>]> <= 10:
                                    - flag server pvp.spawners.<[spawner_type]>:<server.flag[pvp.spawners.<[spawner_type]>].remove[<[loop_index]>]>
                                    - define count:++
                        - narrate "Removed <[count]> spawners"
            - case shopkeeper:
                - choose <context.args.get[2].if_null[null]>:
                    - case add:
                        - define shopkeeper_data:<map[location=<player.location>]>
                        - flag server pvp.shopkeepers:->:<[shopkeeper_data]>
                        - narrate "Shopkeeper added"
                        - run pvp_shopkeepers_setup
                    - case rem remove:
                        - foreach <server.flag[pvp.shopkeepers]> as:shopkeeper_data:
                            - if <player.location.distance_squared[<[shopkeeper_data].get[location]>]> <= 10:
                                - if <[shopkeeper_data].keys.contains[npc]>:
                                    - remove <[shopkeeper_data].get[npc]>
                                - flag server pvp.shopkeepers:<server.flag[pvp.shopkeepers].remove[<[loop_index]>]>
                                - define count:++
                        - narrate "Removed <[count]> shopkeepers"

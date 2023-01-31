stemmechd_pvp:
    type: data
    shopkeepers:
        iron_axe:
            copper_ingot: 3
        iron_sword:
            copper_ingot: 3
        iron_axe:
            copper_ingot: 3
        iron_axe:
            copper_ingot: 3
        tnt:
            iron_ingot: 1
        flint_and_steel:
            copper_ingot: 2

stemmechw_pvp:
    type: world
    debug: false
    events:
        on player teleports:
            - if <context.destination.world.name> == pvp:
                - if <context.origin.world.name> != pvp:
                    - if <player.has_flag[stemmech.pvp]>:
                        - narrate "You need to wait <player.flag_expiration[stemmech.pvp].duration_since[<util.time_now>].formatted> before you can re-enter PvP"
                        - determine DESTINATION:<world[world].spawn_location>
                    - else if !<server.has_flag[stemmech.pvp.ready]>:
                        - narrate "The PvP world is still being setup..."
                        - determine DESTINATION:<world[world].spawn_location>
                    - else:
                        - wait 10t
                        - inventory clear
                        - heal
                        - feed
                        - if <world[pvp].players.size> == 1:
                            - run stemmecht_pvp_shopkeepers_setup
            - else if <context.origin.world.name> == pvp:
                - flag <player> stemmech.pvp expire:1m
                - run stemmecht_pvp_restore
            
        on player dies:
            - if <player.location.world.name> == pvp:
                - flag <player> stemmech.pvp expire:1m

        on player respawns flagged:stemmech.pvp:
            - if <player.location.world.name> == pvp:
                - execute as_server "tpp world <player.name>"
                - run stemmecht_pvp_restore

        on player quits:
            - if <player.location.world.name> == pvp:
                - flag <player> stemmech.pvp expire:1m
                - run stemmecht_pvp_restore

        on player joins:
            - wait 10t
            - if <player.location.world.name> == pvp:
                - execute as_server "tpp world <player.name>"
        
        on system time secondly every:5:
            - if <world[pvp].players.size.if_null[0]> > 0:
                - foreach <server.flag[stemmech.pvp.spawners.copper].if_null[<list>]>:
                    - define loc:<location[<[value]>].add[-2,-2,-2].to_cuboid[<location[<[value]>].add[2,2,2]>].spawnable_blocks.random.if_null[<location[<[value]>]>]>
                    - drop copper_ingot <[loc]>

        on system time minutely:
            - if <world[pvp].players.size.if_null[0]> > 0:
                - foreach <server.flag[stemmech.pvp.spawners.iron].if_null[<list>]>:
                    - define loc:<location[<[value]>].add[-2,-2,-2].to_cuboid[<location[<[value]>].add[2,2,2]>].spawnable_blocks.random.if_null[<location[<[value]>]>]>
                    - drop iron_ingot <[loc]>

        on system time minutely every:5:
            - if <world[pvp].players.size.if_null[0]> > 0:
                - foreach <server.flag[stemmech.pvp.spawners.gold].if_null[<list>]>:
                    - define loc:<location[<[value]>].add[-2,-2,-2].to_cuboid[<location[<[value]>].add[2,2,2]>].spawnable_blocks.random.if_null[<location[<[value]>]>]>
                    - drop gold_ingot <[loc]>
        
        on system time minutely every:10:
            - if <world[pvp].players.size> > 0:
                - run stemmecht_pvp_shopkeepers_setup

stemmecht_pvp_restore:
    type: task
    debug: false
    script:
        - wait 10t
        - if <world[pvp].players.size> == 0:
            - flag server stemmech.pvp.ready:!
            - execute as_server "worlds delete pvp"
            - wait 10t
            - execute as_server "worlds copy pvp_template pvp"
            - wait 10t
            - execute as_server "worlds load pvp"
            - wait 10t
            - flag server stemmech.pvp.ready

stemmecht_pvp_shopkeepers_setup:
    type: task
    debug: false
    script:
        - foreach <server.flag[stemmech.pvp.shopkeepers]> as:shopkeeper_data:
            - if <[shopkeeper_data].keys.contains[npc]>:
                - if !<server.npcs.contains[<[shopkeeper_data].get[npc]>]>:
                    - flag server stemmech.pvp.shopkeepers[<[loop_index]>]:<[shopkeeper_data].exclude[npc]>
                - else if !<[shopkeeper_data].get[npc].is_spawned>:
                    - spawn <[shopkeeper_data].get[npc]> <[shopkeeper_data].get[location]>

            - if !<[shopkeeper_data].keys.contains[npc]>:
                - create villager Shopkeeper <[shopkeeper_data].get[location]> save:result

                - define new_shopkeeper_data:<[shopkeeper_data].with[npc].as[<entry[result].created_npc>]>
                - flag server stemmech.pvp.shopkeepers[<[loop_index]>]:<[new_shopkeeper_data]>

                - assignment set script:stemmecha_pvp_shopkeepers npc:<entry[result].created_npc>
                - adjust <entry[result].created_npc> lookclose:true

stemmecha_pvp_shopkeepers:
    type: assignment
    debug: false
    actions:
        on click:
            - define trades:<list[]>

            - foreach <script[stemmechd_pvp].data_key[shopkeepers]> key:item_name as:item_trades:
                - if <[item_trades].keys.size> == 1:
                    - define trades:->:trade[result=<[item_name]>;inputs=<[item_trades].keys.get[1]>[quantity=<[item_trades].values.get[1]>];max_uses=9999]
                - else:
                    - define trades:->:trade[result=<[item_name]>;inputs=<[item_trades].keys.get[1]>[quantity=<[item_trades].values.get[1]>]|<[item_trades].keys.get[2]>[quantity=<[item_trades].values.get[2]>];max_uses=9999]

            - opentrades <[trades]> "title:Shopkeeper"

stemmechc_pvp_command:
    type: command
    debug: false
    name: pvp
    description: PvP world commands
    usage: /pvp
    permission: stemmech.pvp
    script:
        - choose <context.args.get[1].if_null[null]>:
            - case spawner:
                - choose <context.args.get[2].if_null[null]>:
                    - case add:
                        - define type:<context.args.get[3].if_null[null]>
                        - if <[type].is_in[copper|iron|gold]>:
                            - flag server stemmech.pvp.spawners.<[type]>:->:<player.location.simple>
                            - narrate "Spawner added"
                    - case rem remove:
                        - define count:0
                        - foreach <server.flag[stemmech.pvp.spawners]> key:spawner_type as:spawner_location_list:
                            - foreach <[spawner_location_list]> as:spawner_location:
                                - if <player.location.distance_squared[<[spawner_location]>]> <= 10:
                                    - flag server stemmech.pvp.spawners.<[spawner_type]>:<server.flag[stemmech.pvp.spawners.<[spawner_type]>].remove[<[loop_index]>]>
                                    - define count:++
                        - narrate "Removed <[count]> spawners"
            - case shopkeeper:
                - choose <context.args.get[2].if_null[null]>:
                    - case add:
                        - define shopkeeper_data:<map[location=<player.location>]>
                        - flag server stemmech.pvp.shopkeepers:->:<[shopkeeper_data]>
                        - narrate "Shopkeeper added"
                        - run stemmecht_pvp_shopkeepers_setup
                    - case rem remove:
                        - foreach <server.flag[stemmech.pvp.shopkeepers]> as:shopkeeper_data:
                            - if <player.location.distance_squared[<[shopkeeper_data].get[location]>]> <= 10:
                                - if <[shopkeeper_data].keys.contains[npc]>:
                                    - remove <[shopkeeper_data].get[npc]>
                                - flag server stemmech.pvp.shopkeepers:<server.flag[stemmech.pvp.shopkeepers].remove[<[loop_index]>]>
                                - define count:++
                        - narrate "Removed <[count]> shopkeepers"

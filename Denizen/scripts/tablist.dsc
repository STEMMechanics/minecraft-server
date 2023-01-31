stemmechw_tablist:
    type: world
    debug: false
    events:
        on system time secondly:
            - if <paper.tick_times.get[1].in_seconds> <= 0.02:
                - foreach <server.online_players>:
                    - define prefix:<[value].chat_prefix.parse_color.if_null[null]>

                    - define tps:<server.recent_tps.get[1].round_to_precision[0.1]>
                    - if <[tps].length> == 2:
                        - define tps:<[tps]>.0
                    - if <[tps]> >= 18:
                        - define tps:<&a><[tps]>
                    - else if <[tps]> >= 15:
                        - define tps:<&f><[tps]>
                    - else:
                        - define tps:<&c><[tps]>

                    - define ping:<[value].ping>
                    - if <[ping]> <= 50:
                        - define ping:<&a><[ping]>
                    - else if <[ping]> <= 100:
                        - define ping:<&e><[ping]>
                    - else:
                        - define ping:<&c><[ping]>

                    - if <[prefix]> == null:
                        - define prefix:<empty>

                    - define world_prefix:<[value].location.world.name>
                    - choose <[value].location.world.name.if_null[null]>:
                        - case world:
                            - define world_prefix:<&chr[E80C]>
                        - case bw_amazon:
                            - define world_prefix:<&chr[E80C]>
                        - case bw_western:
                            - define world_prefix:<&chr[E80D]>
                        - case oneblock:
                            - define world_prefix:<&chr[E465]>
                        - case plots:
                            - define world_prefix:<&chr[E448]>
                        - case survival:
                            - define world_prefix:<&chr[E3E7]>

                    - adjust <[value]> player_list_name:<&sp><[world_prefix]><&sp><[prefix]><[value].name>
                    - adjust <[value]> "tab_list_info:<&nl><&f>STEM<&3>Mechanics<&r><&sp><&nl>|<&nl><&e>TPS: <&f><[tps]> <&7>- <&e>Online: <&f><server.online_players.size> <&7>- <&e>Ping: <&f><[ping]>ms"

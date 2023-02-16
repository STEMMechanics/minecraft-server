api_events:
    type: world
    debug: false
    events:
        on scripts loaded server_flagged:api:
            - run stemmech_feature_register def.id:api
        
        on webserver web request port:8532 server_flagged:api:
            - define code:200
            - define accept:ACCEPT
            - define response:<map>
            - define body:<map>

            - define ip:<context.remote_address>
            - if <context.remote_address.contains_text[<&lb>]>:
                - define ip:<context.remote_address.after[<&lb>].before[<&rb>]>
            - else:
                - define ip:<context.remote_address.after[/].before[:]>

            - define token:<context.headers.get[Authorization].get[1].after[Bearer ].if_null[]>
            - if <[token].is_in[<yaml[api].read[api.receive.tokens].values.if_null[<list>]>]>:
                - define path:<context.path.after[/].split[/]>
                - define matching:<server.flag[api.path.<context.method>].deep_keys.parse[split[.]].filter[size.equals[<[path].size>]]>
                - foreach <[path]>:
                    - define direct_match:<[matching].filter[get[<[loop_index]>].equals[<[value]>]]>
                    - if <[direct_match].size> > 0:
                        - define matching:<[direct_match]>
                    - else:
                        - define matching:<[matching].filter[get[<[loop_index]>].starts_with[$]]>
                - define matching_path:<[matching].first.if_null[null]>
                - if <[matching_path]> != null:
                    - define handler:<server.flag[api.path.<context.method>.<[matching_path].separated_by[.]>]>
                    - define query:<context.query>
                    - foreach <[matching_path]>:
                        - if <[value].starts_with[$]>:
                            - define query:<[query].with[<[value].after[$]>].as[<[path].get[<[loop_index]>]>]>

                    - if <context.method> == POST:
                        - choose <context.headers.get[Content-Type].get[1].if_null[null]>:
                            - case application/x-www-form-urlencoded:
                                - define body:<context.body.split[&].to_map[=].if_null[<map>]>
                            - case application/json:
                                - define body:<util.parse_yaml[<context.body>].if_null[<map>]>

                    - ~run <[handler]> def.query:<[query]> def.body:<[body]> save:result
                    - define handler_result_map:<proc[stemmech_determination_mapper].context[<entry[result].created_queue.determination.if_null[<list>]>]>

                    - define code:<[handler_result_map].get[decimal].if_null[200]>
                    - define response:<[handler_result_map].get[map].if_null[<map>]>
                - else:
                    - define code:404
                    - define "response:<map[message=Handler not found]>"
            - else:
                - define accept:DENY
                - define code:401
                - define response:<map[message=Unauthorized]>

            - determine passively code:<[code]>
            - determine passively headers:[Content-Type=application/json]
            - determine passively RAW_TEXT_CONTENT:<[response].to_json>

            - ~log "<[ip]>: <[accept]> <context.method> <[code]> <context.path> <context.query> <context.headers> <[body]>" file:/logs/<server.flag[stemmech.log_time]>-api.log

api_initalize:
    type: task
    debug: false
    script:
        - if <server.has_flag[api.started]>:
            - webserver stop port:8532
        
        - flag server api:!

        - ~run stemmech_yaml_load def.id:api
        - webserver start port:8532
        - flag server api.started

        - run stemmech_feature_set_ready def.id:api

        - run api_register def.method:GET def.task:api_path_query def.path:/server/query
        - run api_register def.method:POST def.task:api_path_reload def.path:/server/reload
        - run api_register def.method:POST def.task:api_path_restart def.path:/server/restart

api_register:
    type: task
    debug: false
    definitions: method|task|path
    script:
        - flag server api.path.<[method]>.<[path].replace_text[/].with[.]>:<[task]>

drustcraftt_api_query:
    type: task
    debug: false
    definitions: query|body
    script:
        - define result:<map>
        - define result:<[result].with[minecraft].as[<server.version.replace[regex:.+\(MC:<&sp>([0-9.]*)\)].with[$1]>]>
        - define result:<[result].with[drustcraft].as[<proc[drustcraftp_core_version]>]>
        - define result:<[result].with[players].as[<server.online_players.size>]>
        - define result:<[result].with[max_players].as[<server.max_players>]>
        - define result:<[result].with[tps].as[<server.recent_tps.get[1].round>]>
        - define result:<[result].with[mspt].as[<paper.tick_times.parse[in_seconds].average.mul[1000].round_to[2]>].if_null[-1]>

        - define player_list:<list>
        - foreach <server.online_players>:
            - define player_list:|:<map[name=<[value].name>;player=<[value].uuid>;ping=<[value].ping>]>
        - define result:<[result].with[list].as[<[player_list]>]>

        - determine passively 200
        - determine <[result]>

api_path_reload:
    type: task
    debug: false
    definitions: query|body
    script:
        - run <script> path:later delay:5s
        - determine passively 200
        - determine "<map[message=The server is scheduled to reload]>"
    later:
        - announce to_console "Drustcraft Engine reloading..."
        - ~run stemmech_yaml_save_all
        - wait 1s
        - reload
        - execute as_server "iareload"
        - wait 1s
        - execute as_server "iazip"

api_path_restart:
    type: task
    debug: false
    definitions: query|body
    script:
        - if !<server.has_flag[api.restart]>:
            - run <script> path:restart delay:10s
            - determine passively 200
            - determine "<map[message=The server is scheduled to restart]>"

        - determine passively 202
        - determine "<map[message=The server is already scheduled to restart]>"

    restart:
        - flag server api.restart:true

        - define delay:15
        - repeat <[delay]> as:number:
            - if <server.online_players.size> == 0:
                - repeat stop

            - define remaining:<[delay].sub[<[number]>]>
            - narrate "<&e>[SERVER] Server restart in <[remaining]> minute<[remaining].is_more_than[1].if_true[s].if_false[]>..." targets:<server.online_players>
            - wait 1m

        - ~run stemmech_yaml_save_all
        - adjust server restart
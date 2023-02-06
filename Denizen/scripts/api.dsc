stemmechw_api:
    type: world
    debug: false
    events:
        on scripts loaded server_flagged:stemmech.api:
            - run stemmecht_api_load
        
        on webserver web request:port:<server.flag[stemmech.api.port]> server_flagged:stemmech.api:
            - 

stemmecht_api_load:
    type: task
    debug: false
    script:
        - if <server.has_flag[stemmech.api.port]>:
            - webserver stop port:<server.flag[stemmech.api.port]>
        
        - flag server stemmech.api:!

        - if <yaml.list.contains[stemmech_api]>:
            - yaml id:stemmech_api unload
        
        - if !<util.has_file[config/api.yml]>:
            - yaml id:stemmech_api load:config/api.yml
        - else:
            - yaml id:stemmech_api create

        - flag server stemmech.api.port:<yaml[stemmech_api].read[api.port].if_null[8532]>
        - webserver start port:<server.flag[stemmech.api.port]>

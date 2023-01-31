stemmechw_common:
    type: world
    debug: false
    events:
        on system time secondly:
            - flag server stemmech.common.epoch:++
            - foreach <server.worlds> as:target_world:
                - flag <[target_world]> stemmech.common.time:<proc[stemmechp_common_world_time_mapped].context[<[target_world]>]>

stemmechp_common_world_time_formatted:
    type: procedure
    debug: false
    definitions: target_world
    script:
        - define world_time:<proc[stemmechp_common_world_time_mapped].context[<[target_world]>]>
        - determine <[world_time].get[h]>:<[world_time].get[m]>

stemmechp_common_world_time_mapped:
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
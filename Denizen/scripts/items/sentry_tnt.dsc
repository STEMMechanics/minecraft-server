sentry_tnt:
    type: item
    material: tnt
    mechanisms:
        custom_model_data: 15000
    display name: <aqua>Sentry TNT
    lore:
    - <white>TNT that explodes when it detects
    - <white>another player
    recipes:
        1:
            type: shaped
            input:
            - air|sculk_sensor|air
            - redstone|flint_and_steel|redstone
            - spider_eye|tnt|spider_eye

sentry_tnt_events:
    type: world
    debug: false
    events:
        on player places tnt:
            - if <context.item_in_hand.custom_model_data> == 15000:
                - flag <context.location> sentry_tnt.owner:<player>

        on player walks:
            - ratelimit <player> 20t
            - define sentry_tnt_list:<player.location.find_blocks_flagged[sentry_tnt].within[10]>
            - foreach <[sentry_tnt_list]>:
                - if <[value].flag[sentry_tnt.owner]> != <player>:
                    - if <player.location.line_of_sight[<[value].round_down>]> || <[value].distance[<player.location>].is_less_than[4].and[<player.is_sneaking.not>]>:
                        - flag <[value]> sentry_tnt:!
                        - if <[value].material.name> == tnt:
                            - modifyblock <[value]> air
                            - drop primed_tnt <[value]>

        on block explodes:
            - if <context.location.has_flag[sentry_tnt]>:
                - flag <[value]> sentry_tnt:!
        
        on player breaks block:
            - if <context.location.has_flag[sentry_tnt]>:
                - flag <[value]> sentry_tnt:!

        on entity picks up tnt:
            - if <context.location.has_flag[sentry_tnt]>:
                - flag <[value]> sentry_tnt:!

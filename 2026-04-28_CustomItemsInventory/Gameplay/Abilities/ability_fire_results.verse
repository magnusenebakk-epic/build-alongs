ability_fire_success<public> := class<concrete>{}


ability_fire_error<public> := class<computes>:


ability_on_cooldown_error<public> := class<concrete><computes>(ability_fire_error){}


ability_cost_failed_error<public> := class<concrete><computes>(ability_fire_error){}

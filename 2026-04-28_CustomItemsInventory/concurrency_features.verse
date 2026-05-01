
using { /Verse.org/Concurrency }


Concurrency<public> := module:

    subscribable_event<public>(t:type) := class(awaitable(t), signalable(t)):
        Event<protected> : event(t) = event(t){}

        (subscribable_event:)Subscribe<public>(Callback:type{_(:t):void}):subscription_task(t)=
            subscription_task(t) {
                Callback := Callback
                Event := Event
            }.Listen()

        Signal<override>(Payload:t):void=
            Event.Signal(Payload)

        Await<override>()<suspends>:t=
            Event.Await()

    subscription_task<public>(t:type) := class<internal>:
        Callback : type{_(:t):void}
        Event : event(t)

        CancelEvent<private> : event() = event(){}
        Cancel<public>():void=
            CancelEvent.Signal()

        Listen<internal>():subscription_task(t)=
            spawn. CallbackLoop()
            Self

        CallbackLoop<private>()<suspends>:void=
            race:
                CancelEvent.Await()
                loop:
                    Payload := Event.Await()
                    Callback(Payload)

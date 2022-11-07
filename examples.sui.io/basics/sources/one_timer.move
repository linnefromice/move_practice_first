module basics::one_timer {
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    struct CreatorCapability has key {
        id: UID
    }
    
    // This functionis only called once on module publish
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            CreatorCapability { id: object::new(ctx) },
            tx_context::sender(ctx)
        )
    }
}

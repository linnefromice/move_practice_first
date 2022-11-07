module basics::object {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;

    struct Object has key {
        id: UID
    }

    // Non-entry functions are also allowed to have return values.
    public fun create(ctx: &mut TxContext): Object {
        Object { id: object::new(ctx) }
    }

    // Entrypoints can't have reeturn values as they can only be called
    // directly in transaction and the returned value can't be used
    entry fun create_and_transfer(to: address, ctx: &mut TxContext) {
        transfer::transfer(create(ctx), to);
    }
}

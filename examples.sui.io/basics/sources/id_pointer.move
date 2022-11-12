module patterns::lock_and_key {
    use std::option::{Self, Option};
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    const ELockIsEmpty: u64 = 0;
    const EKeyMismatch: u64 = 1;
    const ELockIsFull: u64 = 2;

    struct Lock<T: store + key> has key {
        id: UID,
        locked: Option<T>
    }

    struct Key<phantom T: store + key> has key, store {
        id: UID,
        for: ID
    }

    public fun key_for<T: store + key>(key: &Key<T>): ID {
        key.for
    }

    public entry fun create<T: store + key>(obj: T, ctx: &mut TxContext) {
        let id = object::new(ctx);
        let for = object::uid_to_inner(&id);

        transfer::share_object(Lock<T> {
            id,
            locked: option::some(obj)
        });

        transfer::transfer(
            Key<T> {
                for,
                id: object::new(ctx)
            },
            tx_context::sender(ctx)
        );
    }

    public entry fun lock<T: store + key>(
        obj: T,
        lock: &mut Lock<T>,
        key: &Key<T>
    ) {
        assert!(option::is_none(&lock.locked), ELockIsFull);
        assert!(&key.for == object::borrow_id(lock), EKeyMismatch);

        option::fill(&mut lock.locked, obj);
    }

    public entry fun unlock<T: store + key>(
        lock: &mut Lock<T>,
        key: &Key<T>
    ): T {
        assert!(option::is_some(&lock.locked), ELockIsEmpty);
        assert!(&key.for == object::borrow_id(lock), EKeyMismatch);

        option::extract(&mut lock.locked)
    }

    public fun take<T: store + key>(
        lock: &mut Lock<T>,
        key: &Key<T>,
        ctx: &mut TxContext
    ) {
        transfer::transfer(unlock(lock, key), tx_context::sender(ctx));
    }
}

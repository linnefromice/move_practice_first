module tutorial_trusted_swap::trusted_swap {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::sui::{SUI};
    use sui::tx_context::{Self, TxContext};

    const MIN_FEE: u64 = 1000;

    struct Object has key, store {
        id: UID,
        scarcity: u8,
        style: u8
    }

    struct ObjectWrapper has key {
        id: UID,
        original_owner: address,
        to_swap: Object,
        fee: Balance<SUI>,
    }

    public entry fun create_object(scarcity: u8, style: u8, ctx: &mut TxContext) {
        let object = Object {
            id: object::new(ctx),
            scarcity,
            style,
        };
        transfer::transfer(object, tx_context::sender(ctx));
    }

    public entry fun transfer_object(object: Object, recipient: address) {
        transfer::transfer(object, recipient)
    }

    public entry fun request_swap(object: Object, fee: Coin<SUI>, service_address: address, ctx: &mut TxContext) {
        assert!(coin::value(&fee) >= MIN_FEE, 0);
        let wrapper = ObjectWrapper {
            id: object::new(ctx),
            original_owner: tx_context::sender(ctx),
            to_swap: object,
            fee: coin::into_balance(fee)
        };
        transfer::transfer(wrapper, service_address);
    }

    public entry fun execute_swap(wrapper1: ObjectWrapper, wrapper2: ObjectWrapper, ctx: &mut TxContext) {
        assert!(wrapper1.to_swap.scarcity == wrapper2.to_swap.scarcity, 0);
        assert!(wrapper1.to_swap.style != wrapper2.to_swap.style, 0);

        // Unpack both wrappers, cross send them to the other owner.
        let ObjectWrapper {
            id: id1,
            original_owner: original_owner1,
            to_swap: object1,
            fee: fee1
        } = wrapper1;
        let ObjectWrapper {
            id: id2,
            original_owner: original_owner2,
            to_swap: object2,
            fee: fee2
        } = wrapper2;

        // Perform the swap.
        transfer::transfer(object1, original_owner2);
        transfer::transfer(object2, original_owner1);

        // Service provider takes the fee.
        let service_address = tx_context::sender(ctx);
        balance::join(&mut fee1, fee2);
        transfer::transfer(coin::from_balance(fee1, ctx), service_address);

        // Effectively delete the wrapper objects.
        object::delete(id1);
        object::delete(id2);
    }
}
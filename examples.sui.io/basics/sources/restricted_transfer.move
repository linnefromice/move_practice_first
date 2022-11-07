module basics::restricted_transfer {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    const EWrongAmount: u64 = 0;

    struct GovernmentCapability has key { id: UID }

    struct TitleDeed has key {
        id: UID,
        signature: u64
        // ... some additonal field
    }

    struct LandRegistry has key {
        id: UID,
        balance: Balance<SUI>,
        fee: u64
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            GovernmentCapability { id: object::new(ctx) },
            tx_context::sender(ctx)
        );

        transfer::share_object(
            LandRegistry {
                id: object::new(ctx),
                balance: balance::zero<SUI>(),
                fee: 10000
            }
        );
    }

    /// Only owner of the `GovernmentCapability` can perform this action
    public entry fun issue_title_deed(
        _: &GovernmentCapability,
        for: address,
        ctx: &mut TxContext
    ) {
        transfer::transfer(
            TitleDeed {
                id: object::new(ctx),
                signature: 1
            },
            for
        );
    }

    /// A custom transfer function.
    /// Required due to `TitleDead` not having a `store` ability.
    /// All transfer of `TitleDeed`s have to go through this function and pay a fee to the `LandRegistry`
    public entry fun transfer_ownership(
        registry: &mut LandRegistry,
        paper: TitleDeed,
        fee: Coin<SUI>,
        to: address
    ) {
        assert!(coin::value(&fee) == registry.fee, EWrongAmount);

        // add a payment to the LandRegistry balance
        balance::join(&mut registry.balance, coin::into_balance(fee));

        // finally call the transfer function
        transfer::transfer(paper, to);
    }
}

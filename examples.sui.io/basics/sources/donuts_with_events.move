module basics::donuts_with_events {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::{SUI};
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use sui::event;

    const ENotEnough: u64 = 0;

    struct ShopOwnerCap has key { id: UID }

    struct Donut has key { id: UID }

    struct DonutShop has key {
        id: UID,
        price: u64,
        balance: Balance<SUI>
    }

    // ===== Events =====
    struct DonutBought has copy, drop { id: ID }
    struct ProfitsCollected has copy, drop { amount: u64 }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            ShopOwnerCap { id: object::new(ctx) },
            tx_context::sender(ctx)
        );

        transfer::share_object(
            DonutShop {
                id: object::new(ctx),
                price: 1000,
                balance: balance::zero()
            }
        )
    }

    public entry fun buy_donut(
        shop: &mut DonutShop,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(coin::value(payment) >= shop.price, ENotEnough);

        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, shop.price);
        let id = object::new(ctx);

        balance::join(&mut shop.balance, paid);

        event::emit(DonutBought { id: object::uid_to_inner(&id) });
        transfer::transfer(Donut { id }, tx_context::sender(ctx));
    }
    
    public entry fun eat_donut(d: Donut) {
        let Donut { id } = d;
        object::delete(id);
    }
    
    public entry fun collect_profits(
        _: &ShopOwnerCap,
        shop: &mut DonutShop,
        ctx: &mut TxContext
    ) {
        let amount = balance::value(&shop.balance);
        let profits = coin::take(&mut shop.balance, amount, ctx);

        event::emit(ProfitsCollected { amount });
        transfer::transfer(profits, tx_context::sender(ctx));
    }
}

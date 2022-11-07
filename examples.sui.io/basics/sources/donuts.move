module basics::donuts {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    const ENotEnough: u64 = 0;

    struct ShopOwnerCap has key { id: UID }

    struct Donut has key { id: UID }

    struct DonutShop has key {
        id: UID,
        price: u64,
        balance: Balance<SUI>
    }

    // Init function is often ideal place for initializing a shared object as it is called only once.
    // To share an object `transfer::share_object` is used
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            ShopOwnerCap { id: object::new(ctx) },
            tx_context::sender(ctx)
        );

        // Share the object to make it accessible to everyone
        transfer::share_object(DonutShop {
            id: object::new(ctx),
            price: 1000,
            balance: balance::zero()
        });
    }

    // Entry function available to everyone who owns a Coin
    public entry fun buy_donut(
        shop: &mut DonutShop,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(coin::value(payment) >= shop.price, ENotEnough);

        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, shop.price);

        balance::join(&mut shop.balance, paid);

        transfer::transfer(
            Donut { id: object::new(ctx) },
            tx_context::sender(ctx)
        )
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

        transfer::transfer(profits, tx_context::sender(ctx));
    }
}

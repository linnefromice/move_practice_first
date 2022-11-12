module patterns::trade_in {
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::sui::SUI;
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};

    const MODEL_ONE_PRICE: u64 = 10000;
    const MODEL_TWO_PRICE: u64 = 20000;
    const EWrongModel: u64 = 1;
    const EIncorrectAmount: u64 = 2;

    struct Phone has key, store { id: UID, model: u8 }

    struct Receipt { price: u64 }

    public fun buy_phone(model: u8, ctx: &mut TxContext): (Phone, Receipt) {
        assert!(model == 1 || model == 2, EWrongModel);
        let price = if (model == 1) MODEL_ONE_PRICE else MODEL_TWO_PRICE;

        (
            Phone { id: object::new(ctx), model },
            Receipt { price }
        )
    }

    public fun pay_full(receipt: Receipt, payment: Coin<SUI>) {
        let Receipt { price } = receipt;
        assert!(coin::value(&payment) == price, EIncorrectAmount);
        
        transfer::transfer(payment, @patterns);
    }

    public fun trade_in(receipt: Receipt, old_phone: Phone, payment: Coin<SUI>) {
        let Receipt { price } = receipt;
        let tradein_price = if (old_phone.model == 1) MODEL_ONE_PRICE else MODEL_TWO_PRICE;
        let to_pay = price - (tradein_price / 2);

        assert!(coin::value(&payment) == to_pay, EIncorrectAmount);

        transfer::transfer(old_phone, @patterns);
        transfer::transfer(payment, @patterns);
    }
}

#[test_only]
module various::coin_test {
    use sui::coin;
    use sui::transfer;
    use sui::test_scenario;

    struct COIN_TEST has drop {}

    #[test]
    fun test_create_coin() {
        let owner = @0x1;
        let tc = test_scenario::begin(owner);
        let tc_mut = &mut tc;

        test_scenario::next_tx(tc_mut, owner);
        {
            let treasury = coin::create_currency(COIN_TEST {}, 9, test_scenario::ctx(tc_mut));
            transfer::transfer(treasury, owner);
        };
        test_scenario::end(tc);
    }
}


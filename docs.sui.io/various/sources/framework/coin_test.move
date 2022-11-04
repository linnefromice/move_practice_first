#[test_only]
module various::coin_test {
    use sui::balance;
    use sui::coin;
    use sui::object;
    use sui::transfer;
    use sui::test_scenario;
    use sui::tx_context;
    use various::math64;

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

    #[test]
    fun test_balance() {
        let owner = @0xDEF;
        let account1 = @0x111;
        let tc = test_scenario::begin(owner);
        let tc_mut = &mut tc;
        let dec9 = math64::pow(10, 9);

        test_scenario::next_tx(tc_mut, owner);
        {
            let ctx = test_scenario::ctx(tc_mut);
            let treasury_cap = coin::create_currency(COIN_TEST {}, 9, ctx);
            let supply_mut = coin::supply_mut(&mut treasury_cap);
            let balance = balance::increase_supply(supply_mut, 100 * dec9);
            let coin = coin::from_balance(balance, ctx);
            transfer::transfer(treasury_cap, owner);
            transfer::transfer(coin, account1);
        };
        test_scenario::next_tx(tc_mut, owner);
        {
            assert!(test_scenario::has_most_recent_for_address<coin::TreasuryCap<COIN_TEST>>(owner), 0);
            assert!(test_scenario::has_most_recent_for_address<coin::Coin<COIN_TEST>>(account1), 0);
            
            let treasury_cap = test_scenario::take_from_address<coin::TreasuryCap<COIN_TEST>>(&tc, owner);
            assert!(coin::total_supply(&treasury_cap) == 100 * dec9, 0);
            // test_scenario::return_to_sender(&tc, treasury_cap);
            test_scenario::return_to_address(owner, treasury_cap);
            
            let coin = test_scenario::take_from_address<coin::Coin<COIN_TEST>>(&tc, account1);
            assert!(coin::value(&coin) == 100 * dec9, 0);
            test_scenario::return_to_address(account1, coin);
        };
        test_scenario::end(tc);
    }

    #[test]
    fun test_coin() {
        let owner = @0xDEF;
        let account1 = @0x111;
        let tc = test_scenario::begin(owner);
        let tc_mut = &mut tc;
        let dec9 = math64::pow(10, 9);

        test_scenario::next_tx(tc_mut, owner);
        {
            let ctx = test_scenario::ctx(tc_mut);
            let treasury_cap = coin::create_currency(COIN_TEST {}, 9, ctx);
            transfer::transfer(treasury_cap, owner);
        };
        // coin::mint
        test_scenario::next_tx(tc_mut, owner);
        let (id1, id2) = {
            let treasury_cap = test_scenario::take_from_address<coin::TreasuryCap<COIN_TEST>>(tc_mut, owner);
            let ctx = test_scenario::ctx(tc_mut);
            
            coin::mint_and_transfer(&mut treasury_cap, 1000 * dec9, account1, ctx);
            let id1 = object::id_from_address(tx_context::last_created_object_id(ctx));
            coin::mint_and_transfer(&mut treasury_cap, 2000 * dec9, account1, ctx);
            let id2 = object::id_from_address(tx_context::last_created_object_id(ctx));
            
            assert!(coin::total_supply(&treasury_cap) == 3000 * dec9, 0);

            test_scenario::return_to_address(owner, treasury_cap);
            (id1, id2)
        };
        // coin::join
        test_scenario::next_tx(tc_mut, owner);
        {
            let coin1 = test_scenario::take_from_address_by_id<coin::Coin<COIN_TEST>>(tc_mut, account1, id1);
            let coin2 = test_scenario::take_from_address_by_id<coin::Coin<COIN_TEST>>(tc_mut, account1, id2);
            assert!(coin::value(&coin1) == 1000 * dec9, 0);
            assert!(coin::value(&coin2) == 2000 * dec9, 0);
            coin::join(&mut coin1, coin2);
            assert!(coin::value(&coin1) == 3000 * dec9, 0);
            test_scenario::return_to_address(account1, coin1);
        };
        // coin::split
        test_scenario::next_tx(tc_mut, owner);
        {
            let treasury_cap = test_scenario::take_from_address<coin::TreasuryCap<COIN_TEST>>(tc_mut, owner);
            let coin = test_scenario::take_from_address_by_id<coin::Coin<COIN_TEST>>(tc_mut, account1, id1);
            let ctx = test_scenario::ctx(tc_mut);
            let splitted_coin = coin::split(&mut coin, 2500 * dec9, ctx);
            assert!(coin::value(&coin) == 500 * dec9, 0);
            assert!(coin::value(&splitted_coin) == 2500 * dec9, 0);
            coin::burn_<COIN_TEST>(&mut treasury_cap, splitted_coin);
            assert!(coin::total_supply(&treasury_cap) == 500 * dec9, 0);
            test_scenario::return_to_address(owner, treasury_cap);
            test_scenario::return_to_address(account1, coin);
        };
        test_scenario::end(tc);
    }
}


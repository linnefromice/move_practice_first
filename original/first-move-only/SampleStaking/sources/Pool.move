module SampleStaking::Pool {
  use std::signer;

  use SampleStaking::BaseCoin::{
    Self,
    Coin
  };
  use SampleStaking::StakingCoin::{
    Self,
    StakingCoin,
  };
  use SampleStaking::GovCoin::{
    Self,
    GovCoin,
  };

  struct Pool has key {
    staking_coin: Coin<StakingCoin>,
    gov_coin: Coin<GovCoin>,
  }

  public entry fun create_pool(owner: &signer) {
    let max_supply = 1000000000;

    StakingCoin::publish_coin(owner);
    let staking_coin = BaseCoin::extract_all<StakingCoin>(owner);

    GovCoin::publish_coin(owner);
    GovCoin::mint(owner, max_supply);
    let gov_coin = BaseCoin::extract_all<GovCoin>(owner);

    move_to(owner, Pool {
      staking_coin,
      gov_coin
    });
  }

  public entry fun deposit(account: &signer, amount: u64) acquires Pool {
    let account_address = signer::address_of(account);
    let pool = borrow_global_mut<Pool>(@SampleStaking);

    let acc_staking_coin = BaseCoin::withdraw<StakingCoin>(account_address, amount);
    BaseCoin::merge<StakingCoin>(&mut pool.staking_coin, acc_staking_coin);

    if (!BaseCoin::is_exist<GovCoin>(account_address)) GovCoin::publish_coin(account);
    let gov_coin = BaseCoin::extract<GovCoin>(&mut pool.gov_coin, amount);
    BaseCoin::deposit<GovCoin>(account_address, gov_coin);
  }

  public entry fun withdraw(account: &signer, amount: u64) acquires Pool {
    let account_address = signer::address_of(account);
    let pool = borrow_global_mut<Pool>(@SampleStaking);

    let acc_gov_coin = BaseCoin::withdraw<GovCoin>(account_address, amount);
    BaseCoin::merge<GovCoin>(&mut pool.gov_coin, acc_gov_coin);

    let staking_coin = BaseCoin::extract<StakingCoin>(&mut pool.staking_coin, amount);
    BaseCoin::deposit<StakingCoin>(account_address, staking_coin);
  }

  #[test(owner = @SampleStaking)]
  public fun test_create_pool(owner: &signer) acquires Pool {
    create_pool(owner);
    assert!(exists<Pool>(signer::address_of(owner)), 0);
    let pool = borrow_global<Pool>(@SampleStaking);
    let staking_coin_value = BaseCoin::balance_of_internal<StakingCoin>(&pool.staking_coin);
    assert!(staking_coin_value == 0, 0);
    let gov_coin_value = BaseCoin::balance_of_internal<GovCoin>(&pool.gov_coin);
    assert!(gov_coin_value == 1000000000, 0);
  }

  #[test(owner = @SampleStaking, user = @0x2)]
  public fun test_deposit(owner: &signer, user: &signer) acquires Pool {
    let owner_address = signer::address_of(owner);
    let user_address = signer::address_of(user);

    // Preparations
    create_pool(owner);
    StakingCoin::publish_coin(user);
    StakingCoin::mint(user, 1000);

    assert!(!BaseCoin::is_exist<GovCoin>(user_address), 0);

    // Execure & Confirm: 1st
    deposit(user, 200);
    assert!(BaseCoin::is_exist<GovCoin>(user_address), 0);
    assert!(BaseCoin::balance_of<GovCoin>(user_address) == 200, 0);
    let pool = borrow_global<Pool>(owner_address);
    assert!(BaseCoin::balance_of_internal<StakingCoin>(&pool.staking_coin) == 200, 0);
    assert!(BaseCoin::balance_of_internal<GovCoin>(&pool.gov_coin) == 999999800, 0);

    // Execure & Confirm: 2nd
    deposit(user, 800);
    assert!(BaseCoin::balance_of<GovCoin>(user_address) == 1000, 0);
    let pool = borrow_global<Pool>(owner_address);
    assert!(BaseCoin::balance_of_internal<StakingCoin>(&pool.staking_coin) == 1000, 0);
    assert!(BaseCoin::balance_of_internal<GovCoin>(&pool.gov_coin) == 999999000, 0);
  }

  #[test(owner = @SampleStaking, user = @0x2)]
  public fun test_withdraw(owner: &signer, user: &signer) acquires Pool {
    let owner_address = signer::address_of(owner);
    let user_address = signer::address_of(user);

    // Preparations
    create_pool(owner);
    StakingCoin::publish_coin(user);
    StakingCoin::mint(user, 100000);
    deposit(user, 90000);

    // Execure & Confirm: 1st
    withdraw(user, 10000);
    let pool = borrow_global<Pool>(owner_address);
    assert!(BaseCoin::balance_of<GovCoin>(user_address) == 80000, 0);
    assert!(BaseCoin::balance_of_internal<StakingCoin>(&pool.staking_coin) == 80000, 0);
    assert!(BaseCoin::balance_of_internal<GovCoin>(&pool.gov_coin) == 999920000, 0);

    // Execure & Confirm: 2nd
    withdraw(user, 55000);
    let pool = borrow_global<Pool>(owner_address);
    assert!(BaseCoin::balance_of<GovCoin>(user_address) == 25000, 0);
    assert!(BaseCoin::balance_of_internal<StakingCoin>(&pool.staking_coin) == 25000, 0);
    assert!(BaseCoin::balance_of_internal<GovCoin>(&pool.gov_coin) == 999975000, 0);
  }
}
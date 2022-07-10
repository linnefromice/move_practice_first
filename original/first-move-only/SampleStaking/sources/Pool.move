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
    let staking_coin = BaseCoin::extract_coin<StakingCoin>(owner);

    GovCoin::publish_coin(owner);
    GovCoin::mint(owner, max_supply);
    let gov_coin = BaseCoin::extract_coin<GovCoin>(owner);

    move_to(owner, Pool {
      staking_coin,
      gov_coin
    });
  }

  #[test(owner = @SampleStaking)]
  public fun test_create_pool(owner: &signer) acquires Pool {
    create_pool(owner);
    assert!(exists<Pool>(signer::address_of(owner)), 0);
    let pool = borrow_global<Pool>(@SampleStaking);
    let staking_coin_value = BaseCoin::get_fields<StakingCoin>(&pool.staking_coin);
    assert!(staking_coin_value == 0, 0);
    let gov_coin_value = BaseCoin::get_fields<GovCoin>(&pool.gov_coin);
    assert!(gov_coin_value == 1000000000, 0);
  }
}
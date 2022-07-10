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
    StakingCoin::mint(owner, max_supply);
    let staking_coin = BaseCoin::extract_coin<StakingCoin>(owner);

    GovCoin::publish_coin(owner);
    let gov_coin = BaseCoin::extract_coin<GovCoin>(owner);

    move_to(owner, Pool {
      staking_coin,
      gov_coin
    });
  }

  #[test(user = @0x2)]
  public fun test_create_pool(user: &signer) {
    create_pool(user);
    assert!(exists<Pool>(signer::address_of(user)), 0);
  }
}
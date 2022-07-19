module HandsonSecond::StakingMod {
  use Std::Signer;
  use HandsonSecond::BaseCoin::{Self, Coin};

  struct Pool<phantom CoinType> has key {
    staking_coin: Coin<CoinType>
  }

  public fun publish_pool<CoinType>(owner: &signer, amount: u64) {
    let owner_address = Signer::address_of(owner);
    let withdrawed = BaseCoin::withdraw<CoinType>(owner_address, amount);
    move_to(owner, Pool<CoinType> {
      staking_coin: withdrawed
    });
  }

  #[test_only]
  use HandsonSecond::Coins;
  #[test(account = @0x1)]
  fun test_prerequisite(account: &signer) {
    let account_address = Signer::address_of(account);
    assert!(!BaseCoin::is_exist<Coins::RedCoin>(account_address), 0);
    assert!(!BaseCoin::is_exist<Coins::BlueCoin>(account_address), 0);
    BaseCoin::publish<Coins::RedCoin>(account);
    BaseCoin::publish<Coins::BlueCoin>(account);
    assert!(BaseCoin::value<Coins::RedCoin>(account_address) == 0, 0);
    assert!(BaseCoin::value<Coins::BlueCoin>(account_address) == 0, 0);
    assert!(BaseCoin::is_exist<Coins::RedCoin>(account_address), 0);
    assert!(BaseCoin::is_exist<Coins::BlueCoin>(account_address), 0);
  }
  #[test(owner_red = @0x11, owner_blue = @0x21)]
  fun test_publish_pool(owner_red: &signer, owner_blue: &signer) acquires Pool {
    BaseCoin::publish<Coins::RedCoin>(owner_red);
    BaseCoin::publish<Coins::BlueCoin>(owner_blue);
    let user_red_address = Signer::address_of(owner_red);
    let user_blue_address = Signer::address_of(owner_blue);
    BaseCoin::mint<Coins::RedCoin>(user_red_address, 11);
    BaseCoin::mint<Coins::BlueCoin>(user_blue_address, 22);

    publish_pool<Coins::RedCoin>(owner_red, 1);
    publish_pool<Coins::BlueCoin>(owner_blue, 2);
    assert!(exists<Pool<Coins::RedCoin>>(user_red_address), 0);
    assert!(!exists<Pool<Coins::BlueCoin>>(user_red_address), 0);
    assert!(!exists<Pool<Coins::RedCoin>>(user_blue_address), 0);
    assert!(exists<Pool<Coins::BlueCoin>>(user_blue_address), 0);

    let pool_red = borrow_global<Pool<Coins::RedCoin>>(user_red_address);
    let pool_blue = borrow_global<Pool<Coins::BlueCoin>>(user_blue_address);
    assert!(BaseCoin::value_internal<Coins::RedCoin>(&pool_red.staking_coin) == 1, 0);
    assert!(BaseCoin::value_internal<Coins::BlueCoin>(&pool_blue.staking_coin) == 2, 0);
    assert!(BaseCoin::value<Coins::RedCoin>(user_red_address) == 10, 0);
    assert!(BaseCoin::value<Coins::BlueCoin>(user_blue_address) == 20, 0);
  }
}

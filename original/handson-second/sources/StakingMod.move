module HandsonSecond::StakingMod {
  use Std::Signer;
  use HandsonSecond::BaseCoin::{Self, Coin};
  use HandsonSecond::Config;
  use HandsonSecond::LPCoinMod;

  struct Pool<phantom CoinType> has key {
    staking_coin: Coin<CoinType>
  }

  public(script) fun publish_pool_script<CoinType>(owner: &signer, amount: u64) {
    publish_pool<CoinType>(owner, amount);
  }
  public fun publish_pool<CoinType>(owner: &signer, amount: u64) {
    let owner_address = Signer::address_of(owner);
    Config::assert_admin(owner_address);
    let withdrawed = BaseCoin::withdraw<CoinType>(owner_address, amount);
    move_to(owner, Pool<CoinType> {
      staking_coin: withdrawed
    });
  }

  public(script) fun deposit_script<CoinType>(owner: &signer, amount: u64) acquires Pool {
    let owner_address = Signer::address_of(owner);
    deposit<CoinType>(owner_address, amount);
  }
  public(script) fun deposit_defective_script<CoinType>(from: address, amount: u64) acquires Pool {
    deposit<CoinType>(from, amount);
  }
  public fun deposit<CoinType>(from: address, amount: u64) acquires Pool {
    let withdrawed = BaseCoin::withdraw<CoinType>(from, amount);
    let pool_ref = borrow_global_mut<Pool<CoinType>>(Config::owner_address());
    BaseCoin::deposit_internal<CoinType>(&mut pool_ref.staking_coin, withdrawed);

    // For LPCoin
    // if (!LPCoinMod::is_exist(from)) LPCoinMod::new(from);
    LPCoinMod::mint(from, amount);
  }

  public(script) fun withdraw_script<CoinType>(owner: &signer, amount: u64) acquires Pool {
    let owner_address = Signer::address_of(owner);
    withdraw<CoinType>(owner_address, amount);
  }
  public(script) fun withdraw_defective_script<CoinType>(from: address, amount: u64) acquires Pool {
    withdraw<CoinType>(from, amount);
  }
  public fun withdraw<CoinType>(from: address, amount: u64) acquires Pool {
    let pool_ref = borrow_global_mut<Pool<CoinType>>(Config::owner_address());
    let withdrawed = BaseCoin::withdraw_internal<CoinType>(&mut pool_ref.staking_coin, amount);
    BaseCoin::deposit<CoinType>(from, withdrawed);

    // For LPCoin
    // if (!LPCoinMod::is_exist(from)) LPCoinMod::new(from);
    LPCoinMod::burn(from, amount);
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
  #[test(owner = @HandsonSecond)]
  fun test_publish_pool(owner: &signer) acquires Pool {
    BaseCoin::publish<Coins::RedCoin>(owner);
    BaseCoin::publish<Coins::BlueCoin>(owner);
    let owner_address = Signer::address_of(owner);
    BaseCoin::mint<Coins::RedCoin>(owner_address, 11);
    BaseCoin::mint<Coins::BlueCoin>(owner_address, 22);

    publish_pool<Coins::RedCoin>(owner, 1);
    publish_pool<Coins::BlueCoin>(owner, 2);
    assert!(exists<Pool<Coins::RedCoin>>(owner_address), 0);
    assert!(exists<Pool<Coins::BlueCoin>>(owner_address), 0);

    let pool_red = borrow_global<Pool<Coins::RedCoin>>(owner_address);
    let pool_blue = borrow_global<Pool<Coins::BlueCoin>>(owner_address);
    assert!(BaseCoin::value_internal<Coins::RedCoin>(&pool_red.staking_coin) == 1, 0);
    assert!(BaseCoin::value_internal<Coins::BlueCoin>(&pool_blue.staking_coin) == 2, 0);
    assert!(BaseCoin::value<Coins::RedCoin>(owner_address) == 10, 0);
    assert!(BaseCoin::value<Coins::BlueCoin>(owner_address) == 20, 0);
  }
  #[test(not_owner = @0x1)]
  #[expected_failure(abort_code = 101)]
  fun test_publish_pool_by_no_owner(not_owner: &signer) {
    publish_pool<Coins::RedCoin>(not_owner, 1);
  }
  #[test(owner = @HandsonSecond, user = @0x1)]
  fun test_deposit(owner: &signer, user: &signer) acquires Pool {
    BaseCoin::publish<Coins::RedCoin>(owner);
    BaseCoin::publish<Coins::RedCoin>(user);
    let owner_address = Signer::address_of(owner);
    let user_address = Signer::address_of(user);
    BaseCoin::mint<Coins::RedCoin>(owner_address, 10);
    BaseCoin::mint<Coins::RedCoin>(user_address, 90);

    LPCoinMod::initialize(owner);
    LPCoinMod::new(user);

    publish_pool<Coins::RedCoin>(owner, 10);
    deposit<Coins::RedCoin>(user_address, 15);
    let pool_ref = borrow_global<Pool<Coins::RedCoin>>(owner_address);
    assert!(BaseCoin::value_internal<Coins::RedCoin>(&pool_ref.staking_coin) == 25, 0);
    assert!(BaseCoin::value<Coins::RedCoin>(user_address) == 75, 0);
    assert!(LPCoinMod::value(user_address) == 15, 0);
  }
  #[test(owner = @HandsonSecond, user = @0x1)]
  fun test_withdraw(owner: &signer, user: &signer) acquires Pool {
    BaseCoin::publish<Coins::BlueCoin>(owner);
    BaseCoin::publish<Coins::BlueCoin>(user);
    let owner_address = Signer::address_of(owner);
    let user_address = Signer::address_of(user);
    BaseCoin::mint<Coins::BlueCoin>(owner_address, 10);
    BaseCoin::mint<Coins::BlueCoin>(user_address, 90);

    LPCoinMod::initialize(owner);
    LPCoinMod::new(user);

    publish_pool<Coins::BlueCoin>(owner, 10);
    deposit<Coins::BlueCoin>(user_address, 30);
    withdraw<Coins::BlueCoin>(user_address, 25);
    let pool_ref = borrow_global<Pool<Coins::BlueCoin>>(owner_address);
    assert!(BaseCoin::value_internal<Coins::BlueCoin>(&pool_ref.staking_coin) == 15, 0);
    assert!(BaseCoin::value<Coins::BlueCoin>(user_address) == 85, 0);
    assert!(LPCoinMod::value(user_address) == 5, 0);
  }
}

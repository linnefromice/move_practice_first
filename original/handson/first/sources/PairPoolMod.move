module Handson::PairPoolMod {
  use AptosFramework::Coin;

  struct PairPool<phantom X, phantom Y> has key {
    x: Coin::Coin<X>,
    y: Coin::Coin<Y>,
  }

  // consts: Errors
  const E_INVALID_VALUE: u64 = 1;

  public fun add_pair_pool<X, Y>(owner: &signer) {
    let x = Coin::withdraw<X>(owner, 10); // Coin<X>
    let y = Coin::withdraw<Y>(owner, 10); // Coin<Y>
    move_to(owner, PairPool<X, Y> {
      x,
      y
    })
  }

  public fun deposit<X, Y>(account: &signer, x_amount: u64, y_amount: u64) acquires PairPool {
    assert!(x_amount > 0 || y_amount > 0, E_INVALID_VALUE);
    // let account_address = Signer::address_of(account);
    let admin_address = @Handson;
    let pool = borrow_global_mut<PairPool<X, Y>>(admin_address);

    if (x_amount > 0) {
      let coin = Coin::withdraw<X>(account, x_amount);
      Coin::merge<X>(&mut pool.x, coin);
    };
    if (y_amount > 0) {
      let coin = Coin::withdraw<Y>(account, y_amount);
      Coin::merge<Y>(&mut pool.y, coin);
    };
  }

  #[test_only]
  use Std::Signer;
  #[test_only]
  use Std::ASCII;
  #[test_only]
  use AptosFramework::Coin::{BurnCapability,MintCapability};
  #[test_only]
  struct CoinX {}
  #[test_only]
  struct CoinY {}
    #[test_only]
  struct FakeCapabilities<phantom CoinType> has key {
    mint_cap: MintCapability<CoinType>,
    burn_cap: BurnCapability<CoinType>,
  }
  #[test_only]
  fun register_test_coins(owner: &signer) {
    let (x_mint_cap, x_burn_cap) = Coin::initialize<CoinX>(
      owner,
      ASCII::string(b"Coin X"),
      ASCII::string(b"X"),
      10,
      false
    );
    let (y_mint_cap, y_burn_cap) = Coin::initialize<CoinY>(
      owner,
      ASCII::string(b"Coin Y"),
      ASCII::string(b"Y"),
      10,
      false
    );
    Coin::register_internal<CoinX>(owner);
    Coin::register_internal<CoinY>(owner);

    move_to(owner, FakeCapabilities<CoinX>{
      mint_cap: x_mint_cap,
      burn_cap: x_burn_cap,
    });
    move_to(owner, FakeCapabilities<CoinY>{
      mint_cap: y_mint_cap,
      burn_cap: y_burn_cap,
    });
  }
  #[test(owner = @Handson)]
  fun test_add_pair_pool(owner: &signer) acquires FakeCapabilities, PairPool {
    register_test_coins(owner);
    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    let coin_x = Coin::mint<CoinX>(10, &x_capabilities.mint_cap); // Coin<CoinX>
    let coin_y = Coin::mint<CoinY>(10, &y_capabilities.mint_cap); // Coin<CoinY>
    Coin::deposit<CoinX>(owner_address, coin_x);
    Coin::deposit<CoinY>(owner_address, coin_y);

    add_pair_pool<CoinX, CoinY>(owner);
    let owner_address = Signer::address_of(owner);
    assert!(exists<PairPool<CoinX, CoinY>>(owner_address), 0);
    let pool_ref = borrow_global<PairPool<CoinX, CoinY>>(owner_address);
    assert!(Coin::value(&pool_ref.x)== 10, 0);
    assert!(Coin::value(&pool_ref.y) == 10, 0);
  }

  #[test(owner = @Handson, user = @0x1)]
  fun test_deposit(owner: &signer, user: &signer) acquires FakeCapabilities, PairPool {
    register_test_coins(owner);
    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    let coin_x = Coin::mint<CoinX>(10, &x_capabilities.mint_cap); // Coin<CoinX>
    let coin_y = Coin::mint<CoinY>(10, &y_capabilities.mint_cap); // Coin<CoinY>
    Coin::deposit<CoinX>(owner_address, coin_x);
    Coin::deposit<CoinY>(owner_address, coin_y);

    let user_address = Signer::address_of(user);
    let coin_x = Coin::mint<CoinX>(100, &x_capabilities.mint_cap); // Coin<CoinX>
    let coin_y = Coin::mint<CoinY>(100, &y_capabilities.mint_cap); // Coin<CoinY>
    Coin::register_internal<CoinX>(user);
    Coin::register_internal<CoinY>(user);
    Coin::deposit<CoinX>(user_address, coin_x);
    Coin::deposit<CoinY>(user_address, coin_y);

    add_pair_pool<CoinX, CoinY>(owner);
    let pool_ref = borrow_global<PairPool<CoinX, CoinY>>(owner_address);
    assert!(Coin::value(&pool_ref.x)== 10, 0);
    assert!(Coin::value(&pool_ref.y) == 10, 0);

    deposit<CoinX, CoinY>(user, 30, 60);
    let pool_ref = borrow_global<PairPool<CoinX, CoinY>>(owner_address);
    assert!(Coin::value(&pool_ref.x)== 40, 0);
    assert!(Coin::value(&pool_ref.y) == 70, 0);
    assert!(Coin::balance<CoinX>(user_address) == 70, 0);
    assert!(Coin::balance<CoinY>(user_address) == 40, 0);
  }
}
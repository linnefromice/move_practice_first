module SampleStaking::PoolModule {
  use Std::ASCII;
  use Std::Signer;
  use AptosFramework::Coin;
  use SampleStaking::LiquidityProviderTokenModule;

  struct PairPool<phantom X, phantom Y> has key {
    name: ASCII::String,
    lptoken_info: LiquidityProviderTokenModule::LPTokenInfo<X, Y>,
    x: Coin::Coin<X>,
    y: Coin::Coin<Y>,
  }

  // consts: Errors
  const E_INVALID_VALUE: u64 = 1;
  const E_NOT_OWNER_ADDRESS: u64 = 101;

  // functions: Asserts
  fun assert_admin(signer: &signer) {
    assert!(Signer::address_of(signer) == @SampleStaking, E_NOT_OWNER_ADDRESS);
  }
  fun assert_greater_than_zero(value: u64) {
    assert!(value > 0, E_INVALID_VALUE);
  }
  fun assert_hold_more_than_amount<CoinType>(account_address: address, value: u64) {
    assert!(Coin::balance<CoinType>(account_address) >= value, E_INVALID_VALUE);
  }

  public fun add_pair_pool<X, Y>(owner: &signer, name: vector<u8>, x_amount: u64, y_amount: u64) {
    assert_admin(owner);
    assert_greater_than_zero(x_amount);
    assert_greater_than_zero(y_amount);
    let owner_address = Signer::address_of(owner);
    assert_hold_more_than_amount<X>(owner_address, x_amount);
    assert_hold_more_than_amount<Y>(owner_address, y_amount);
    let x = Coin::withdraw<X>(owner, x_amount);
    let y = Coin::withdraw<Y>(owner, y_amount);
    move_to(owner, PairPool<X, Y> {
      name: ASCII::string(name),
      lptoken_info: LiquidityProviderTokenModule::initialize<X, Y>(owner),
      x,
      y
    });
  }

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
  public fun register_test_coins(owner: &signer) {
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

  #[test(owner = @SampleStaking)]
  public fun test_add_pair_pool(owner: &signer) acquires PairPool, FakeCapabilities {
    register_test_coins(owner);
    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    let coin_x = Coin::mint<CoinX>(10000, &x_capabilities.mint_cap);
    let coin_y = Coin::mint<CoinY>(10000, &y_capabilities.mint_cap);
    Coin::deposit<CoinX>(owner_address, coin_x);
    Coin::deposit<CoinY>(owner_address, coin_y);

    // Execute
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 2000, 6000);
    // Check: PairPool
    assert!(exists<PairPool<CoinX, CoinY>>(owner_address), 0);
    let pool = borrow_global<PairPool<CoinX, CoinY>>(owner_address);
    assert!(pool.name == ASCII::string(b"Pool X Y"), 0);
    assert!(LiquidityProviderTokenModule::total_supply_internal<CoinX, CoinY>(&pool.lptoken_info) == 0, 0);
    assert!(Coin::value<CoinX>(&pool.x) == 2000, 0);
    assert!(Coin::value<CoinY>(&pool.y) == 6000, 0);
    // Check: owner
    assert!(Coin::balance<CoinX>(owner_address) == 8000, 0);
    assert!(Coin::balance<CoinY>(owner_address) == 4000, 0);
  }

  #[test(owner = @0x1)]
  #[expected_failure(abort_code = 101)]
  public fun test_add_pair_pool_when_not_admin(owner: &signer) {
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 9999, 9999);
  }
  #[test(owner = @SampleStaking)]
  #[expected_failure(abort_code = 1)]
  public fun test_add_pair_pool_when_x_is_zero(owner: &signer) {
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 0, 9999);
  }
  #[test(owner = @SampleStaking)]
  #[expected_failure(abort_code = 1)]
  public fun test_add_pair_pool_when_y_is_zero(owner: &signer) {
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 9999, 0);
  }
  #[test(owner = @SampleStaking)]
  #[expected_failure(abort_code = 1)]
  public fun test_add_pair_pool_when_x_is_insufficient(owner: &signer) acquires FakeCapabilities {
    register_test_coins(owner);
    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    let coin_x = Coin::mint<CoinX>(1, &x_capabilities.mint_cap);
    let coin_y = Coin::mint<CoinY>(1, &y_capabilities.mint_cap);
    Coin::deposit<CoinX>(owner_address, coin_x);
    Coin::deposit<CoinY>(owner_address, coin_y);
    // Execute
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 5, 1);
  }
  #[test(owner = @SampleStaking)]
  #[expected_failure(abort_code = 1)]
  public fun test_add_pair_pool_when_y_is_insufficient(owner: &signer) acquires FakeCapabilities {
    register_test_coins(owner);
    let owner_address = Signer::address_of(owner);
    let x_capabilities = borrow_global<FakeCapabilities<CoinX>>(owner_address);
    let y_capabilities = borrow_global<FakeCapabilities<CoinY>>(owner_address);
    let coin_x = Coin::mint<CoinX>(1, &x_capabilities.mint_cap);
    let coin_y = Coin::mint<CoinY>(1, &y_capabilities.mint_cap);
    Coin::deposit<CoinX>(owner_address, coin_x);
    Coin::deposit<CoinY>(owner_address, coin_y);
    // Execute
    add_pair_pool<CoinX, CoinY>(owner, b"Pool X Y", 1, 5);
  }
}
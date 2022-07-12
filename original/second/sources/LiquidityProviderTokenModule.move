module SampleStaking::LiquidityProviderTokenModule {
  use Std::Signer;

  struct LPTokenInfo<phantom X, phantom Y> has key, store, drop {
    total_supply: u64,
  }
  struct LPToken<phantom X, phantom Y> has key, store, drop {
    value: u64,
  }

  // consts
  const OWNER: address = @SampleStaking;
  // consts: Errors
  const E_NOT_OWNER_ADDRESS: u64 = 101;
  const E_NO_LPTOKEN: u64 = 102;
  const E_INSUFFICIENT: u64 = 103;
  // functions: Asserts
  fun assert_admin(signer: &signer) {
    assert!(Signer::address_of(signer) == OWNER, E_NOT_OWNER_ADDRESS);
  }
  fun assert_no_lptoken<X, Y>(account_address: address) {
    assert!(exists<LPToken<X, Y>>(account_address), E_NO_LPTOKEN);
  }
  fun assert_insufficient_value<X, Y>(token: &LPToken<X, Y>, value: u64) {
    assert!(token.value >= value, E_INSUFFICIENT);
  }

  // functions: control LPTokenInfo
  public fun initialize<X, Y>(owner: &signer): LPTokenInfo<X, Y> {
    assert_admin(owner);
    LPTokenInfo<X, Y> { total_supply: 0 }
  }

  public fun total_supply_internal<X, Y>(res: &LPTokenInfo<X, Y>): u64 {
    res.total_supply
  }

  // functions: control LPToken
  public fun new<X, Y>(to: &signer) {
    move_to(to, LPToken<X, Y> { value: 0 });
  }
  public fun is_exists<X, Y>(to: address): bool {
    exists<LPToken<X, Y>>(to)
  }
  public fun value_internal<X, Y>(coin: &LPToken<X, Y>): u64 {
    coin.value
  }
  public fun value<X, Y>(account: address): u64 acquires LPToken {
    let coin = borrow_global<LPToken<X, Y>>(account);
    value_internal(coin)
  }
  public fun mint_to<X, Y>(
    // owner: &signer,
    to: address,
    amount: u64,
    info: &mut LPTokenInfo<X, Y>
  ) acquires LPToken {
    // assert_admin(owner);
    assert_no_lptoken<X, Y>(to);
    let value = &mut borrow_global_mut<LPToken<X, Y>>(to).value;
    *value = *value + amount;
    let total_supply = &mut info.total_supply;
    *total_supply = *total_supply + amount;
  }
  public fun burn_from<X, Y>(
    to: address,
    amount: u64,
    info: &mut LPTokenInfo<X, Y>
  ) acquires LPToken {
    assert_no_lptoken<X, Y>(to);
    let lptoken = borrow_global_mut<LPToken<X, Y>>(to);
    assert_insufficient_value<X, Y>(lptoken, amount);
    lptoken.value = lptoken.value - amount;
    let total_supply = &mut info.total_supply;
    *total_supply = *total_supply - amount;
  }

  #[test_only]
  struct CoinX {}
  #[test_only]
  struct CoinY {}
  // Test: About LPTokenInfo
  #[test(owner = @SampleStaking)]
  fun test_initialize(owner: &signer) {
    let info = initialize<CoinX, CoinY>(owner);
    assert!(info == LPTokenInfo<CoinX, CoinY>{ total_supply: 0 }, 0);
  }
  #[test(owner = @0x1)]
  #[expected_failure(abort_code = 101)]
  fun test_initialize_when_not_owner(owner: &signer) {
    initialize<CoinX, CoinY>(owner);
  }
  // Test: About LPToken
  #[test(owner = @SampleStaking, user1 = @0x1, user2 = @0x2)]
  fun test_mint_to(owner: &signer, user1: &signer, user2: &signer) acquires LPToken {
    let info = initialize<CoinX, CoinY>(owner);
    new<CoinX, CoinY>(user1);
    new<CoinX, CoinY>(user2);

    let user1_address = Signer::address_of(user1);
    mint_to<CoinX, CoinY>(user1_address, 100, &mut info);
    let user1_coin = borrow_global<LPToken<CoinX, CoinY>>(user1_address);
    assert!(user1_coin.value == 100, 0);
    assert!(info.total_supply == 100, 0);

    let user2_address = Signer::address_of(user2);
    mint_to<CoinX, CoinY>(user2_address, 2000, &mut info);
    let user2_coin = borrow_global<LPToken<CoinX, CoinY>>(user2_address);
    assert!(user2_coin.value == 2000, 0);
    assert!(info.total_supply == 2100, 0);
  }
  #[test(owner = @SampleStaking, user1 = @0x1, user2 = @0x2)]
  fun test_burn_from(owner: &signer, user1: &signer, user2: &signer) acquires LPToken {
    let info = initialize<CoinX, CoinY>(owner);
    new<CoinX, CoinY>(user1);
    new<CoinX, CoinY>(user2);

    let user1_address = Signer::address_of(user1);
    mint_to<CoinX, CoinY>(user1_address, 100, &mut info);
    let user2_address = Signer::address_of(user2);
    mint_to<CoinX, CoinY>(user2_address, 100, &mut info);

    burn_from<CoinX, CoinY>(user1_address, 15, &mut info);
    let user1_coin = borrow_global<LPToken<CoinX, CoinY>>(user1_address);
    assert!(user1_coin.value == 85, 0);
    assert!(info.total_supply == 185, 0);
    burn_from<CoinX, CoinY>(user2_address, 30, &mut info);
    let user2_coin = borrow_global<LPToken<CoinX, CoinY>>(user2_address);
    assert!(user2_coin.value == 70, 0);
    assert!(info.total_supply == 155, 0);
  }
}

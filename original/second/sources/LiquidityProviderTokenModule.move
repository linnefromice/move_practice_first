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
  // functions: Asserts
  fun assert_admin(signer: &signer) {
    assert!(Signer::address_of(signer) == OWNER, E_NOT_OWNER_ADDRESS);
  }
  fun assert_no_lptoken<CoinTypeX, CoinTypeY>(account_address: address) {
    assert!(exists<LPToken<CoinTypeX, CoinTypeY>>(account_address), E_NO_LPTOKEN);
  }

  // functions: control LPTokenInfo
  public fun initialize<CoinTypeX, CoinTypeY>(owner: &signer): LPTokenInfo<CoinTypeX, CoinTypeY> {
    assert_admin(owner);
    LPTokenInfo<CoinTypeX, CoinTypeY> { total_supply: 0 }
  }

  public fun total_supply_internal<CoinTypeX, CoinTypeY>(res: &LPTokenInfo<CoinTypeX, CoinTypeY>): u64 {
    res.total_supply
  }

  // functions: control LPToken
  public fun new<CoinTypeX, CoinTypeY>(to: &signer) {
    move_to(to, LPToken<CoinTypeX, CoinTypeY> { value: 0 });
  }
  public fun mint_to<CoinTypeX, CoinTypeY>(
    owner: &signer,
    to: address,
    amount: u64,
    info: &mut LPTokenInfo<CoinTypeX, CoinTypeY>
  ) acquires LPToken {
    assert_admin(owner);
    assert_no_lptoken<CoinTypeX, CoinTypeY>(to);
    let to_token = borrow_global_mut<LPToken<CoinTypeX, CoinTypeY>>(to);
    to_token.value = to_token.value + amount;
    let total_supply = &mut info.total_supply;
    *total_supply = *total_supply + amount;
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
    mint_to<CoinX, CoinY>(owner, user1_address, 100, &mut info);
    let user1_coin = borrow_global<LPToken<CoinX, CoinY>>(user1_address);
    assert!(user1_coin.value == 100, 0);
    assert!(info.total_supply == 100, 0);

    let user2_address = Signer::address_of(user2);
    mint_to<CoinX, CoinY>(owner, user2_address, 2000, &mut info);
    let user2_coin = borrow_global<LPToken<CoinX, CoinY>>(user2_address);
    assert!(user2_coin.value == 2000, 0);
    assert!(info.total_supply == 2100, 0);
  }
}

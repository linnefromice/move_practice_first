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
  // functions: Asserts
  fun assert_admin(signer: &signer) {
    assert!(Signer::address_of(signer) == OWNER, E_NOT_OWNER_ADDRESS);
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
  public fun new<CoinTypeX, CoinTypeY>(): LPToken<CoinTypeX, CoinTypeY> {
    LPToken<CoinTypeX, CoinTypeY> { value: 0 }
  }

  #[test_only]
  struct CoinX {}
  #[test_only]
  struct CoinY {}
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
}

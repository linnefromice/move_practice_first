module SampleStaking::LiquidityProviderTokenModule {
  struct LPTokenInfo<phantom X, phantom Y> has key, store, drop {
    total_supply: u64,
  }
  struct LPToken<phantom X, phantom Y> has key, store, drop {
    value: u64,
  }

  // consts
  const OWNER: address = @SampleStaking;

  // functions: control LPTokenInfo
  public fun initialize<CoinTypeX, CoinTypeY>(): LPTokenInfo<CoinTypeX, CoinTypeY> {
    LPTokenInfo<CoinTypeX, CoinTypeY> { total_supply: 0 }
  }

  public fun total_supply_internal<CoinTypeX, CoinTypeY>(res: &LPTokenInfo<CoinTypeX, CoinTypeY>): u64 {
    res.total_supply
  }

  // functions: control LPToken
  public fun new<CoinTypeX, CoinTypeY>(): LPToken<CoinTypeX, CoinTypeY> {
    LPToken<CoinTypeX, CoinTypeY> { value: 0 }
  }
}

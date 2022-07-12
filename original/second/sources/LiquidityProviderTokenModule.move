module SampleStaking::LiquidityProviderTokenModule {
  struct LiquidityProviderToken<phantom X, phantom Y> has store, drop {
    total_supply: u64,
  }

  public fun new<CoinTypeX, CoinTypeY>(): LiquidityProviderToken<CoinTypeX, CoinTypeY> {
    LiquidityProviderToken<CoinTypeX, CoinTypeY> { total_supply: 0 }
  }

  public fun total_supply<CoinTypeX, CoinTypeY>(token: &LiquidityProviderToken<CoinTypeX, CoinTypeY>): u64 {
    token.total_supply
  }
}
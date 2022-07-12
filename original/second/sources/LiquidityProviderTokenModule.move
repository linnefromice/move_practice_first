module SampleStaking::LiquidityProviderTokenModule {
  struct LiquidityProviderToken<phantom X, phantom Y> has store {}

  public fun new<CoinTypeX, CoinTypeY>(): LiquidityProviderToken<CoinTypeX, CoinTypeY> {
    LiquidityProviderToken<CoinTypeX, CoinTypeY> { }
  }
}
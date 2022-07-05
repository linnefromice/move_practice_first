module Sample::BaseToken {
  struct Coin<phantom CoinType> has key {
    value: u64
  }

  public fun publish_coin<CoinType>(account: &signer) {
    let coin = Coin<CoinType> { value: 0 };
    move_to(account, coin);
  }
}

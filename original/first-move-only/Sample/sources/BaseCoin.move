module Sample::BaseCoin {
  use std::signer;

  struct Coin<phantom CoinType> has key {
    value: u64
  }

  public fun publish_coin<CoinType>(account: &signer) {
    let coin = Coin<CoinType> { value: 0 };
    move_to(account, coin);
  }

  #[test_only]
  struct TestCoin {}

  #[test(user = @0x2)]
  fun test_publish_coin(user: &signer) {
    publish_coin<TestCoin>(user);
    let user_address = signer::address_of(user);
    assert!(exists<Coin<TestCoin>>(user_address), 0);
  }
}

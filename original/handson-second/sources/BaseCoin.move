module HandsonSecond::BaseCoin {
  use Std::Signer;

  const EALREADY_HAS_COIN: u64 = 1;

  struct Coin<phantom CoinType> has key {
    value: u64
  }

  public fun publish<CoinType>(account: &signer) {
    let coin = Coin<CoinType> { value: 0 };
    let account_address = Signer::address_of(account);
    assert!(!exists<Coin<CoinType>>(account_address), EALREADY_HAS_COIN);
    move_to(account, coin);
  }

  #[test_only]
  struct TestCoin {}
  #[test(account = @0x1)]
  fun test_publish(account: &signer) {
    publish<TestCoin>(account);
    let account_address = Signer::address_of(account);
    assert!(exists<Coin<TestCoin>>(account_address), 0);
  }
}
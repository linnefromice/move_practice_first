module Sample::BaseCoin {
  use std::signer;

  const EALREADY_HAS_COIN: u64 = 1;

  struct Coin<phantom CoinType> has key {
    value: u64
  }

  public fun publish_coin<CoinType>(account: &signer) {
    let coin = Coin<CoinType> { value: 0 };
    let account_address = signer::address_of(account);
    assert!(!exists<Coin<CoinType>>(account_address), EALREADY_HAS_COIN);
    move_to(account, coin);
  }

  #[test_only]
  struct TestCoin {}
  #[test_only]
  struct DummyCoin {}

  #[test(user = @0x2)]
  fun test_publish_coin(user: &signer) {
    publish_coin<TestCoin>(user);
    let user_address = signer::address_of(user);
    assert!(exists<Coin<TestCoin>>(user_address), 0);
    assert!(!exists<Coin<DummyCoin>>(user_address), 0);
    publish_coin<DummyCoin>(user);
    assert!(exists<Coin<DummyCoin>>(user_address), 0);
  }
  #[test(user = @0x2)]
  #[expected_failure(abort_code = 1)]
  fun test_not_double_publish_coin(user: &signer) {
    publish_coin<TestCoin>(user);
    publish_coin<TestCoin>(user);
  }
}

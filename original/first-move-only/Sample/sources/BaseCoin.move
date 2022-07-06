module Sample::BaseCoin {
  use std::signer;

  const EALREADY_HAS_COIN: u64 = 1;
  const EINVALID_VALUE: u64 = 2;
  const ENOT_HAS_COIN: u64 = 3;

  struct Coin<phantom CoinType> has key {
    value: u64
  }

  public fun publish_coin<CoinType>(account: &signer) {
    let coin = Coin<CoinType> { value: 0 };
    let account_address = signer::address_of(account);
    assert!(!exists<Coin<CoinType>>(account_address), EALREADY_HAS_COIN);
    move_to(account, coin);
  }

  public fun mint<CoinType>(account: &signer, amount: u64) acquires Coin {
    assert!(amount > 0, EINVALID_VALUE);
    let account_address = signer::address_of(account);
    assert!(exists<Coin<CoinType>>(account_address), ENOT_HAS_COIN);
    let coin_ref = borrow_global_mut<Coin<CoinType>>(account_address);
    coin_ref.value = coin_ref.value + amount;
  }

  public fun transfer<CoinType>(from: &signer, to: address, amount: u64) acquires Coin {
    let from_address = signer::address_of(from);
    let from_coin_ref = borrow_global_mut<Coin<CoinType>>(from_address);
    from_coin_ref.value = from_coin_ref.value - amount;
    let to_coin_ref = borrow_global_mut<Coin<CoinType>>(to);
    to_coin_ref.value = to_coin_ref.value + amount;
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

  #[test(user = @0x2)]
  fun test_mint(user: &signer) acquires Coin {
    publish_coin<TestCoin>(user);
    mint<TestCoin>(user, 100);
    let user_address = signer::address_of(user);
    let coin_ref = borrow_global<Coin<TestCoin>>(user_address);
    assert!(coin_ref.value == 100, 0);
  }
  #[test(user = @0x2)]
  #[expected_failure(abort_code = 2)]
  fun test_mint_when_use_insufficient_arg(user: &signer) acquires Coin {
    mint<TestCoin>(user, 0);
  }
  #[test(user = @0x2)]
  #[expected_failure(abort_code = 3)]
  fun test_mint_when_no_resource(user: &signer) acquires Coin {
    mint<TestCoin>(user, 100);
  }

  #[test(from = @0x2, to = @0x3)]
  fun test_transfer(from: &signer, to: &signer) acquires Coin {
    publish_coin<TestCoin>(from);
    publish_coin<TestCoin>(to);
    mint<TestCoin>(from, 100);
    let from_address = signer::address_of(from);
    let to_address = signer::address_of(to);
    transfer<TestCoin>(from, to_address, 70);
    assert!(borrow_global<Coin<TestCoin>>(from_address).value == 30, 0);
    assert!(borrow_global<Coin<TestCoin>>(to_address).value == 70, 0);
    transfer<TestCoin>(from, to_address, 20);
    assert!(borrow_global<Coin<TestCoin>>(from_address).value == 10, 0);
    assert!(borrow_global<Coin<TestCoin>>(to_address).value == 90, 0);
    transfer<TestCoin>(from, to_address, 10);
    assert!(borrow_global<Coin<TestCoin>>(from_address).value == 0, 0);
    assert!(borrow_global<Coin<TestCoin>>(to_address).value == 100, 0);
  }
}

module SampleStaking::BaseCoin {
  use std::signer;

  const EALREADY_HAS_COIN: u64 = 1;
  const EINVALID_VALUE: u64 = 2;
  const ENOT_HAS_COIN: u64 = 3;

  struct Coin<phantom CoinType> has key, store, drop {
    value: u64
  }

  public fun publish_coin<CoinType>(account: &signer) {
    let coin = Coin<CoinType> { value: 0 };
    let account_address = signer::address_of(account);
    assert!(!exists<Coin<CoinType>>(account_address), EALREADY_HAS_COIN);
    move_to(account, coin);
  }

  public fun extract_coin<CoinType>(account: &signer): Coin<CoinType> acquires Coin {
    move_from<Coin<CoinType>>(signer::address_of(account))
  }

  public fun mint<CoinType>(account: &signer, amount: u64) acquires Coin {
    assert!(amount > 0, EINVALID_VALUE);
    let account_address = signer::address_of(account);
    assert!(exists<Coin<CoinType>>(account_address), ENOT_HAS_COIN);
    let coin_ref = borrow_global_mut<Coin<CoinType>>(account_address);
    coin_ref.value = coin_ref.value + amount;
  }

  public fun transfer<CoinType>(from: &signer, to: address, amount: u64) acquires Coin {
    assert!(amount > 0, EINVALID_VALUE);
    let from_address = signer::address_of(from);
    assert!(exists<Coin<CoinType>>(from_address), ENOT_HAS_COIN);
    assert!(exists<Coin<CoinType>>(to), ENOT_HAS_COIN);
    let from_coin_ref = borrow_global_mut<Coin<CoinType>>(from_address);
    assert!(from_coin_ref.value >= amount, EINVALID_VALUE);
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
  fun test_extract_coin(user: &signer) acquires Coin {
    publish_coin<TestCoin>(user);
    let coin = extract_coin<TestCoin>(user);
    assert!(coin == Coin<TestCoin> { value: 0 }, 0);
    assert!(!exists<Coin<TestCoin>>(signer::address_of(user)), 0);
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
  #[test(from = @0x2, to = @0x3)]
  #[expected_failure(abort_code = 2)]
  fun test_transfer_when_use_insufficient_arg(from: &signer, to: &signer) acquires Coin {
    transfer<TestCoin>(from, signer::address_of(to), 0);
  }
  #[test(from = @0x2, to = @0x3)]
  #[expected_failure(abort_code = 3)]
  fun test_transfer_when_no_coin_in_from(from: &signer, to: &signer) acquires Coin {
    publish_coin<TestCoin>(to);
    transfer<TestCoin>(from, signer::address_of(to), 1);
  }
  #[test(from = @0x2, to = @0x3)]
  #[expected_failure(abort_code = 3)]
  fun test_transfer_when_no_coin_in_to(from: &signer, to: &signer) acquires Coin {
    publish_coin<TestCoin>(from);
    transfer<TestCoin>(from, signer::address_of(to), 1);
  }
  #[test(from = @0x2, to = @0x3)]
  #[expected_failure(abort_code = 2)]
  fun test_transfer_when_amount_over_balance(from: &signer, to: &signer) acquires Coin {
    publish_coin<TestCoin>(from);
    publish_coin<TestCoin>(to);
    mint<TestCoin>(from, 10);
    transfer<TestCoin>(from, signer::address_of(to), 20);
  }
}
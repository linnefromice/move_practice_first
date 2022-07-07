module Mega::SampleCoin {
  use std::Signer as signer;

  const EALREADY_HAS_COIN: u64 = 1;
  const EINVALID_VALUE: u64 = 2;
  const ENOT_HAS_COIN: u64 = 3;

  struct SampleCoin has key {
    value: u64
  }

  public fun publish_coin(account: &signer) {
    let coin = SampleCoin { value: 0 };
    let account_address = signer::address_of(account);
    assert!(!exists<SampleCoin>(account_address), EALREADY_HAS_COIN);
    move_to(account, coin);
  }

  public fun mint(account: &signer, amount: u64) acquires SampleCoin {
    assert!(amount > 0, EINVALID_VALUE);
    let account_address = signer::address_of(account);
    assert!(exists<SampleCoin>(account_address), ENOT_HAS_COIN);
    let coin_ref = borrow_global_mut<SampleCoin>(account_address);
    coin_ref.value = coin_ref.value + amount;
  }

  public fun transfer(from: &signer, to: address, amount: u64) acquires SampleCoin {
    assert!(amount > 0, EINVALID_VALUE);
    let from_address = signer::address_of(from);
    assert!(exists<SampleCoin>(from_address), ENOT_HAS_COIN);
    assert!(exists<SampleCoin>(to), ENOT_HAS_COIN);
    let from_coin_ref = borrow_global_mut<SampleCoin>(from_address);
    assert!(from_coin_ref.value >= amount, EINVALID_VALUE);
    from_coin_ref.value = from_coin_ref.value - amount;
    let to_coin_ref = borrow_global_mut<SampleCoin>(to);
    to_coin_ref.value = to_coin_ref.value + amount;
  }

  #[test(user = @0x2)]
  fun test_publish_coin(user: &signer) acquires SampleCoin {
    publish_coin(user);
    let user_address = signer::address_of(user);
    assert!(exists<SampleCoin>(user_address), 0);
    let coin_ref = borrow_global<SampleCoin>(user_address);
    assert!(coin_ref.value == 0, 0);
  }
  #[test(user = @0x2)]
  #[expected_failure(abort_code = 1)]
  fun test_not_double_publish_coin(user: &signer) {
    publish_coin(user);
    publish_coin(user);
  }

  #[test(user = @0x2)]
  fun test_mint(user: &signer) acquires SampleCoin {
    publish_coin(user);
    mint(user, 100);
    let user_address = signer::address_of(user);
    let coin_ref = borrow_global<SampleCoin>(user_address);
    assert!(coin_ref.value == 100, 0);
  }
  #[test(user = @0x2)]
  #[expected_failure(abort_code = 2)]
  fun test_mint_when_use_insufficient_arg(user: &signer) acquires SampleCoin {
    mint(user, 0);
  }
  #[test(user = @0x2)]
  #[expected_failure(abort_code = 3)]
  fun test_mint_when_no_resource(user: &signer) acquires SampleCoin {
    mint(user, 100);
  }

  #[test(from = @0x2, to = @0x3)]
  fun test_transfer(from: &signer, to: &signer) acquires SampleCoin {
    publish_coin(from);
    publish_coin(to);
    mint(from, 100);
    let from_address = signer::address_of(from);
    let to_address = signer::address_of(to);
    transfer(from, signer::address_of(to), 70);
    assert!(borrow_global<SampleCoin>(from_address).value == 30, 0);
    assert!(borrow_global<SampleCoin>(to_address).value == 70, 0);
    transfer(from, signer::address_of(to), 20);
    assert!(borrow_global<SampleCoin>(from_address).value == 10, 0);
    assert!(borrow_global<SampleCoin>(to_address).value == 90, 0);
    transfer(from, signer::address_of(to), 10);
    assert!(borrow_global<SampleCoin>(from_address).value == 0, 0);
    assert!(borrow_global<SampleCoin>(to_address).value == 100, 0);
  }
  #[test(from = @0x2, to = @0x3)]
  #[expected_failure(abort_code = 2)]
  fun test_transfer_when_use_insufficient_arg(from: &signer, to: &signer) acquires SampleCoin {
    transfer(from, signer::address_of(to), 0);
  }
  #[test(from = @0x2, to = @0x3)]
  #[expected_failure(abort_code = 3)]
  fun test_transfer_when_no_coin_in_from(from: &signer, to: &signer) acquires SampleCoin {
    publish_coin(to);
    transfer(from, signer::address_of(to), 1);
  }
  #[test(from = @0x2, to = @0x3)]
  #[expected_failure(abort_code = 3)]
  fun test_transfer_when_no_coin_in_to(from: &signer, to: &signer) acquires SampleCoin {
    publish_coin(from);
    transfer(from, signer::address_of(to), 1);
  }
  #[test(from = @0x2, to = @0x3)]
  #[expected_failure(abort_code = 2)]
  fun test_transfer_when_amount_over_balance(from: &signer, to: &signer) acquires SampleCoin {
    publish_coin(from);
    publish_coin(to);
    mint(from, 10);
    transfer(from, signer::address_of(to), 20);
  }
}

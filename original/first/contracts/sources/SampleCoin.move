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
}

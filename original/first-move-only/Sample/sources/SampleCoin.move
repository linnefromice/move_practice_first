module Sample::SampleCoin {
  use std::signer;

  const EALREADY_HAS_COIN: u64 = 1;
  const ENOT_HAS_COIN: u64 = 2;

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
    let account_address = signer::address_of(account);
    assert!(exists<SampleCoin>(account_address), ENOT_HAS_COIN);
    let coin_ref = borrow_global_mut<SampleCoin>(account_address);
    coin_ref.value = coin_ref.value + amount;
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

  #[test(user = @0x2, )]
  fun test_mint(user: &signer) acquires SampleCoin {
    publish_coin(user);
    let amount = 100;
    mint(user, amount);
    let user_address = signer::address_of(user);
    let coin_ref = borrow_global<SampleCoin>(user_address);
    assert!(coin_ref.value == 100, 0);
  }
}

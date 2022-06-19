module 0xCAFE::MyOddCoin {
  use std::signer;
  use 0xCAFE::BaseCoin;

  struct MyOddCoin has drop {}

  const ENOT_ODD: u64 = 0;

  public fun setup_and_mint(account: &signer, amount: u64) {
    BaseCoin::publish_balance<MyOddCoin>(account);
    BaseCoin::mint<MyOddCoin>(signer::address_of(account), amount);
  }

  public fun transfer(from: &signer, to: address, amount: u64) {
    assert!(amount % 2 == 1, ENOT_ODD);
    BaseCoin::transfer<MyOddCoin>(from, to, amount);
  }

  #[test(from = @0x42, to = @0x10)]
  fun test_odd_success(from: signer, to: signer) {
    setup_and_mint(&from, 42);
    setup_and_mint(&to, 10);

    transfer(&from, @0x10, 7);

    assert!(BaseCoin::balance_of<MyOddCoin>(@0x42) == 35, 0);
    assert!(BaseCoin::balance_of<MyOddCoin>(@0x10) == 17, 0);
  }

  #[test(from = @0x42, to = @0x10)]
  #[expected_failure]
  fun test_not_odd_failure(from: signer, to: signer) {
    setup_and_mint(&from, 42);
    setup_and_mint(&to, 10);
    transfer(&from, @0x10, 8);
  }
}
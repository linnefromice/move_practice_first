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
}
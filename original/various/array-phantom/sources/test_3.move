#[test_only]
module array_phantom::test_3 {
  use std::signer;

  struct Coin<phantom T> has key {
    value: u64,
  }

  struct RedCoin has store { }
  struct BlueCoin has store { }
  struct GreenCoin has store { }
  struct YellowCoin has store { }

  fun publish_coin<T: store>(account: &signer, value: u64) {
    move_to(account, Coin<T> { value });
  }

  #[test(account = @0x1)]
  fun test_scenario(account: &signer) acquires Coin {
    publish_coin<RedCoin>(account, 10);
    publish_coin<BlueCoin>(account, 20);
    publish_coin<GreenCoin>(account, 30);
    publish_coin<YellowCoin>(account, 40);

    let account_address = signer::address_of(account);
    let balance = 0;
    balance = balance + borrow_global<Coin<RedCoin>>(account_address).value;
    balance = balance + borrow_global<Coin<BlueCoin>>(account_address).value;
    balance = balance + borrow_global<Coin<GreenCoin>>(account_address).value;
    balance = balance + borrow_global<Coin<YellowCoin>>(account_address).value;
    assert!(balance == 100, 0);
  }
}
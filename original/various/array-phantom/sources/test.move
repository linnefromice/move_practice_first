#[test_only]
module array_phantom::test {
  use std::signer;
  use std::string;

  struct Balance<phantom T> has key, store {
    value: u64
  }
  struct CoinInfo<T> has key, store {
    info: T,
    balance: Balance<T>,
  }

  struct RedCoin has store {
    red: string::String,
  }
  struct BlueCoin has store {
    blue: string::String,
  }
  struct GreenCoin has store {
    green: string::String,
  }

  fun generate<T>(
    info: T
  ): CoinInfo<T> {
    CoinInfo<T> { info, balance: Balance<T> { value: 0 } }
  }

  fun initialize(account: &signer) {
    move_to(account, generate<RedCoin>(RedCoin { red: string::utf8(b"red coin") }));
    move_to(account, generate<BlueCoin>(BlueCoin { blue: string::utf8(b"blue coin") }));
    move_to(account, generate<GreenCoin>(GreenCoin { green: string::utf8(b"green coin") }));
  }

  #[test(account = @0x1)]
  fun test_scenario(account: &signer) {
    initialize(account);
    let account_address = signer::address_of(account);
    assert!(exists<CoinInfo<RedCoin>>(account_address), 0);
    assert!(exists<CoinInfo<BlueCoin>>(account_address), 0);
    assert!(exists<CoinInfo<GreenCoin>>(account_address), 0);
  }
}
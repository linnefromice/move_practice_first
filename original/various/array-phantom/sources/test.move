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

  struct RedCoin has store, copy, drop {
    red: string::String,
  }
  struct BlueCoin has store, copy, drop {
    blue: string::String,
  }
  struct GreenCoin has store, copy, drop {
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

  // public fun bk_find_coin_info<T: store>(account_address: address): (&T, u64) acquires CoinInfo {
  //   let coin_info = borrow_global<CoinInfo<T>>(account_address);
  //   let info = &coin_info.info;
  //   (info, coin_info.balance.value)
  // }

  public fun find_coin_info<T: store + copy>(account_address: address): (T, u64) acquires CoinInfo {
    let coin_info = borrow_global<CoinInfo<T>>(account_address);
    let info = coin_info.info;
    (info, coin_info.balance.value)
  }

  #[test(account = @0x1)]
  fun test_scenario(account: &signer) acquires CoinInfo {
    initialize(account);
    let account_address = signer::address_of(account);
    assert!(exists<CoinInfo<RedCoin>>(account_address), 0);
    assert!(exists<CoinInfo<BlueCoin>>(account_address), 0);
    assert!(exists<CoinInfo<GreenCoin>>(account_address), 0);

    let (info, value) = find_coin_info<RedCoin>(account_address);
    assert!(value == 0, 0);
    assert!(info.red == string::utf8(b"red coin"), 0);
    let (info, value) = find_coin_info<BlueCoin>(account_address);
    assert!(value == 0, 0);
    assert!(info.blue == string::utf8(b"blue coin"), 0);
    let (info, value) = find_coin_info<GreenCoin>(account_address);
    assert!(value == 0, 0);
    assert!(info.green == string::utf8(b"green coin"), 0);
  }
}
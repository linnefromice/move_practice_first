#[test_only]
module array_phantom::test_2 {
  use std::signer;
  use std::string;
  use std::table::{Self, Table};

  struct Balance<T> has key {
    coins: Table<u64, Coin<T>>
  }
  struct Coin<T> has store {
    info: T,
    value: u64,
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

  fun generate_coin<T>(info: T): Coin<T> {
    Coin<T> { info, value: 0 }
  }

  fun generate_balance<T: store>(): Balance<T> {
    Balance<T> { coins: table::new<u64, Coin<T>>() }
  }

  fun initialize_balance(account: &signer) {
    move_to(account, generate_balance<RedCoin>());
    move_to(account, generate_balance<BlueCoin>());
    move_to(account, generate_balance<GreenCoin>());
  }

  // public fun bk_find_coin_info<T: store>(account_address: address): (&T, u64) acquires CoinInfo {
  //   let coin_info = borrow_global<CoinInfo<T>>(account_address);
  //   let info = &coin_info.info;
  //   (info, coin_info.balance.value)
  // }

  // public fun find_coin_info<T: store + copy>(account_address: address): (T, u64) acquires CoinInfo {
  //   let coin_info = borrow_global<CoinInfo<T>>(account_address);
  //   let info = coin_info.info;
  //   (info, coin_info.balance.value)
  // }

  #[test(account = @0x1)]
  fun test_scenario(account: &signer) {
    initialize_balance(account);
    let account_address = signer::address_of(account);
    assert!(exists<Balance<RedCoin>>(account_address), 0);
    assert!(exists<Balance<BlueCoin>>(account_address), 0);
    assert!(exists<Balance<GreenCoin>>(account_address), 0);
  }
}
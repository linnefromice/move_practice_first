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

  fun generate_balance<T: store>(): Balance<T> {
    Balance<T> { coins: table::new<u64, Coin<T>>() }
  }

  fun initialize_balance(account: &signer) {
    move_to(account, generate_balance<RedCoin>());
    move_to(account, generate_balance<BlueCoin>());
    move_to(account, generate_balance<GreenCoin>());
  }

  fun add_coin<T: store>(uid: u64, account_address: address, coin: Coin<T>) acquires Balance {
    let balance = borrow_global_mut<Balance<T>>(account_address);
    table::add<u64, Coin<T>>(&mut balance.coins, uid, coin);
  }
  fun generate_coin<T>(info: T, value: u64): Coin<T> {
    Coin<T> { info, value }
  }
  fun add_red_coin(uid: u64, account_address: address, value: u64) acquires Balance {
    let coin = generate_coin<RedCoin>(RedCoin { red: string::utf8(b"red coin") }, value);
    add_coin<RedCoin>(uid, account_address, coin);
  }
  fun add_blue_coin(uid: u64, account_address: address, value: u64) acquires Balance {
    let coin = generate_coin<BlueCoin>(BlueCoin { blue: string::utf8(b"blue coin") }, value);
    add_coin<BlueCoin>(uid, account_address, coin);
  }
  fun add_green_coin(uid: u64, account_address: address, value: u64) acquires Balance {
    let coin = generate_coin<GreenCoin>(GreenCoin { green: string::utf8(b"green coin") }, value);
    add_coin<GreenCoin>(uid, account_address, coin);
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
  fun test_scenario(account: &signer) acquires Balance {
    initialize_balance(account);
    let account_address = signer::address_of(account);
    assert!(exists<Balance<RedCoin>>(account_address), 0);
    assert!(exists<Balance<BlueCoin>>(account_address), 0);
    assert!(exists<Balance<GreenCoin>>(account_address), 0);

    add_red_coin(1, account_address, 100);
    add_blue_coin(2, account_address, 200);
    add_green_coin(3, account_address, 300);
  }
}
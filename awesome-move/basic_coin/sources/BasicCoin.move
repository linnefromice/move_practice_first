module BasicCoin::BasicCoin {
  use std::errors;
  use std::signer;

  /// Error Codes
  const ENOT_MODULE_OWNER : u64 = 0;
  const ESUFFICIENT_BALANCE: u64 = 1;
  const EALREADY_HAS_BALANCE: u64 = 2;
  const EALREADY_INITIALIZED: u64 = 3;
  const EEQUAL_ADDR: u64 = 4;

  struct Coin<phantom CoinType> has store {
    value: u64
  }

  struct Balance<phantom CoinType> has key {
    coin: Coin<CoinType>
  }

  public fun publish_balance<CoinType>(account: &signer) {
    let empty_coin = Coin<CoinType> { value: 0 };
    assert!(!exists<Balance<CoinType>>(signer::address_of(account)), errors::already_published(EALREADY_HAS_BALANCE));
    move_to(account, Balance<CoinType> { coin: empty_coin });
  }

  spec public_balance {
    include Schema_publish<CoinType> { addr: signer::address_of(account), amount: 0 };
  }
  spec schema Schema_publish<CoinType> {
    addr: address;
    amount: u64;

    aborts_if exists<Balance<CoinType>>(addr);

    ensures exists<Balance<CoinType>>(addr);
    let post balance_post = global<Balance<CoinType>>(addr).coin.value;

    ensures balance_post == amount;
  }

  public fun mint<CoinType: drop>(mint_addr: address, amount: u64, _witness: CoinType) acquires Balance {
    deposit(mint_addr, Coin<CoinType> { value: amount });
  }

  spec mint {
    include DepositSchema<CoinType> { addr: mint_addr, amount };
  }

  public fun burn<CoinType: drop>(burn_addr: address, amount: u64, _witness: CoinType) acquires Balance {
    let Coin { value: _ } = withdraw<CoinType>(burn_addr, amount);
  }

  spec burn {
    // TBD
  }

  public fun balance_of<CoinType>(owner: address): u64 acquires Balance {
    borrow_global<Balance<CoinType>>(owner).coin.value
  }

  spec balance_of {
     pragma aborts_if_is_strict;
     aborts_if !exists<Balance<CoinType>>(owner);
  }

  fun withdraw<CoinType>(addr: address, amount: u64): Coin<CoinType> acquires Balance {
    let balance = balance_of<CoinType>(addr);
    assert!(balance >= amount, ESUFFICIENT_BALANCE);
    let balance_ref = &mut borrow_global_mut<Balance<CoinType>>(addr).coin.value;
    *balance_ref = balance - amount;
    Coin<CoinType> { value: amount }
  }

  spec withdraw {
    let balance = global<Balance<CoinType>>(addr).coin.value;

    aborts_if !exists<Balance<CoinType>>(addr);
    aborts_if balance < amount;

    let post balance_post = global<Balance<CoinType>>(addr).coin.value;
    ensures result == Coin<CoinType> { value: amount };
    ensures balance_post == balance - amount;
  }

  fun deposit<CoinType>(addr: address, check: Coin<CoinType>) acquires Balance {
    let balance = balance_of<CoinType>(addr);
    let balance_ref = &mut borrow_global_mut<Balance<CoinType>>(addr).coin.value;
    let Coin { value } = check;
    *balance_ref = balance + value;
  }

  spec deposit {
    let balance = global<Balance<CoinType>>(addr).coin.value;
    let check_value = check.value;

    aborts_if !exists<Balance<CoinType>>(addr);
    aborts_if balance + check_value > MAX_U64;

    let post balance_post = global<Balance<CoinType>>(addr).coin.value;
    ensures balance_post == balance + check_value;
  }
  spec schema DepositSchema<CoinType> {
    addr: address;
    amount: u64;
    let balance = global<Balance<CoinType>>(addr).coin.value;

    aborts_if !exists<Balance<CoinType>>(addr);
    aborts_if balance + amount > MAX_U64;

    let post balance_post = global<Balance<CoinType>>(addr).coin.value;
    ensures balance_post == balance + amount;
  }
}

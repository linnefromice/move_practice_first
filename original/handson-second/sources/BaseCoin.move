module HandsonSecond::BaseCoin {
  use Std::Signer;

  const EALREADY_HAS_COIN: u64 = 1;
  const ENOT_HAS_COIN: u64 = 2;
  const EINVALID_VALUE: u64 = 3;

  struct Coin<phantom CoinType> has key {
    value: u64
  }

  public fun publish<CoinType>(account: &signer) {
    let coin = Coin<CoinType> { value: 0 };
    let account_address = Signer::address_of(account);
    assert!(!exists<Coin<CoinType>>(account_address), EALREADY_HAS_COIN);
    move_to(account, coin);
  }

  public fun mint<CoinType>(to: address, amount: u64) acquires Coin {
    assert!(exists<Coin<CoinType>>(to), ENOT_HAS_COIN);
    let value_ref = &mut borrow_global_mut<Coin<CoinType>>(to).value;
    *value_ref = *value_ref + amount;
  }

  public fun deposit<CoinType>(to: address, coin: Coin<CoinType>) acquires Coin {
    assert!(exists<Coin<CoinType>>(to), ENOT_HAS_COIN);
    let value_ref = &mut borrow_global_mut<Coin<CoinType>>(to).value;
    *value_ref = *value_ref + coin.value;
    Coin { value: _ } = coin;
  }

  public fun withdraw<CoinType>(to: address, amount: u64): Coin<CoinType> acquires Coin {
    assert!(exists<Coin<CoinType>>(to), ENOT_HAS_COIN);
    let value_ref = &mut borrow_global_mut<Coin<CoinType>>(to).value;
    assert!(*value_ref >= amount, EINVALID_VALUE);
    *value_ref = *value_ref - amount;
    Coin { value: amount }
  }

  #[test_only]
  struct TestCoin {}
  #[test(account = @0x1)]
  fun test_publish(account: &signer) {
    publish<TestCoin>(account);
    let account_address = Signer::address_of(account);
    assert!(exists<Coin<TestCoin>>(account_address), 0);
  }
  #[test(account = @0x1)]
  fun test_mint(account: &signer) acquires Coin {
    publish<TestCoin>(account);
    let account_address = Signer::address_of(account);
    mint<TestCoin>(account_address, 100);
    let coin_ref = borrow_global<Coin<TestCoin>>(account_address);
    assert!(coin_ref.value == 100, 0);
  }
  #[test(account = @0x1)]
  fun test_deposit(account: &signer) acquires Coin {
    publish<TestCoin>(account);
    let account_address = Signer::address_of(account);
    let coin = Coin { value: 200 };
    deposit<TestCoin>(account_address, coin);
    let coin_ref = borrow_global<Coin<TestCoin>>(account_address);
    assert!(coin_ref.value == 200, 0);
  }
  #[test(account = @0x1)]
  fun test_withdraw(account: &signer) acquires Coin {
    publish<TestCoin>(account);
    let account_address = Signer::address_of(account);
    mint<TestCoin>(account_address, 300);
    let withdrawed = withdraw<TestCoin>(account_address, 80);
    assert!(withdrawed.value == 80, 0);
    let coin_ref = borrow_global<Coin<TestCoin>>(account_address);
    assert!(coin_ref.value == 220, 0);
    deposit<TestCoin>(account_address, withdrawed); // for not drop
  }
}
module HandsonSecond::LPCoinMod {
  struct LPCoin has key {
    value: u64
  }

  public(script) fun new_script(to: &signer) {
    new(to);
  }
  public fun new(to: &signer) {
    move_to(to, new_internal());
  }
  public fun new_internal(): LPCoin {
    LPCoin { value: 0 }
  }

  public fun mint(to: address, amount: u64) acquires LPCoin {
    let coin = borrow_global_mut<LPCoin>(to);
    mint_internal(coin, amount);
  }
  public fun mint_internal(coin: &mut LPCoin, amount: u64) {
    coin.value = coin.value + amount;
  }

  public fun burn(to: address, amount: u64) acquires LPCoin {
    let coin = borrow_global_mut<LPCoin>(to);
    burn_internal(coin, amount);
  }
  public fun burn_internal(coin: &mut LPCoin, amount: u64) {
    coin.value = coin.value - amount;
  }

  // Getters
  public fun value(account_address: address): u64 acquires LPCoin {
    let coin = borrow_global_mut<LPCoin>(account_address);
    value_internal(coin)
  }
  public fun value_internal(coin: &LPCoin): u64 {
    coin.value
  }
  public fun is_exist(account_address: address): bool {
    exists<LPCoin>(account_address)
  }

  #[test_only]
  use Std::Signer;
  #[test(to = @0x1)]
  fun test_new(to: &signer) {
    new(to);
    let to_address = Signer::address_of(to);
    assert!(exists<LPCoin>(to_address), 0);
  }
  #[test(to = @0x1)]
  fun test_mint(to: &signer) acquires LPCoin {
    new(to);
    let to_address = Signer::address_of(to);
    mint(to_address, 50);
    let coin_ref = borrow_global<LPCoin>(to_address);
    assert!(coin_ref.value == 50, 0);
  }
  #[test(to = @0x1)]
  fun test_burn(to: &signer) acquires LPCoin {
    new(to);
    let to_address = Signer::address_of(to);
    mint(to_address, 50);
    burn(to_address, 35);
    let coin_ref = borrow_global<LPCoin>(to_address);
    assert!(coin_ref.value == 15, 0);
  }
}
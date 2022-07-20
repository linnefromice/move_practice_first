module HandsonSecond::LPCoinMod {
  struct LPCoin has key {
    value: u64
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
}
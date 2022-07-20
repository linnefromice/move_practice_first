module HandsonSecond::LPTokenMod {
  

  struct LPToken has key {
    value: u64
  }

  public fun new(to: &signer) {
    move_to(to, new_internal());
  }
  public fun new_internal(): LPToken {
    LPToken { value: 0 }
  }

  public fun mint(to: address, amount: u64) acquires LPToken {
    let coin = borrow_global_mut<LPToken>(to);
    mint_internal(coin, amount);
  }
  public fun mint_internal(coin: &mut LPToken, amount: u64) {
    coin.value = coin.value + amount;
  }

  #[test_only]
  use Std::Signer;
  #[test(to = @0x1)]
  fun test_new(to: &signer) {
    new(to);
    let to_address = Signer::address_of(to);
    assert!(exists<LPToken>(to_address), 0);
  }
  #[test(to = @0x1)]
  fun test_mint(to: &signer) acquires LPToken {
    new(to);
    let to_address = Signer::address_of(to);
    mint(to_address, 50);
    let coin_ref = borrow_global<LPToken>(to_address);
    assert!(coin_ref.value == 50, 0);
  }
}
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

  #[test_only]
  use Std::Signer;
  #[test(to = @0x1)]
  fun test_new(to: &signer) {
    new(to);
    let to_address = Signer::address_of(to);
    assert!(exists<LPToken>(to_address), 0);
  }
}
#[test_only]
module test_addr::test_mod {
  use std::string;
  use aptos_framework::coin::{Self, BurnCapability, MintCapability};

  struct FakeCapabilities<phantom CoinType> has key {
    mint_cap: MintCapability<CoinType>,
    burn_cap: BurnCapability<CoinType>,
  }

  struct DummyCoin {}

  public fun initialize_coin_for_test(owner: &signer) {
    let (mint_cap, burn_cap) = coin::initialize<DummyCoin>(
      owner,
      string::utf8(b"DummyCoin"),
      string::utf8(b"DUMMY"),
      10,
      false
    );
    coin::register_for_test<DummyCoin>(owner);
    move_to(owner, FakeCapabilities<DummyCoin>{
      mint_cap,
      burn_cap
    });
  }

  #[test(owner = @test_addr)]
  fun test_initialize_coin(owner: &signer) {
    initialize_coin_for_test(owner);
    assert!(coin::is_coin_initialized<DummyCoin>(), 0);
  }
}
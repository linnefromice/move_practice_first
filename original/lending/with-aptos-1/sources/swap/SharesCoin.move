module lending::SharesCoin {
  use std::string;
  use aptos_framework::coin::{Self, BurnCapability, MintCapability};

  const NAME_PREFIX: vector<u8> = b"Shares ";
  const SYMBOL_PREFIX: vector<u8> = b"s";

  struct SharesCoin<phantom Coin> has key {}

  struct Capabilities<phantom CoinType> has key {
    mint_cap: MintCapability<CoinType>,
    burn_cap: BurnCapability<CoinType>,
  }

  public fun initialize<CoinType>(owner: &signer) {
    assert!(coin::is_coin_initialized<CoinType>(), 0);
    let raw_name = coin::name<CoinType>();
    let raw_symbol = coin::symbol<CoinType>();
    let name = string::utf8(NAME_PREFIX);
    string::append(&mut name, raw_name);
    let symbol = string::utf8(SYMBOL_PREFIX);
    string::append(&mut symbol, raw_symbol);
    let (mint_cap, burn_cap) = coin::initialize<SharesCoin<CoinType>>(
      owner,
      name,
      symbol,
      18, // TODO
      false
    );
    move_to(owner, Capabilities<SharesCoin<CoinType>> {
      mint_cap,
      burn_cap
    });
  }

  public fun register<CoinType>(account: &signer) {
    assert!(coin::is_coin_initialized<SharesCoin<CoinType>>(), 0);
    coin::register_for_test<SharesCoin<CoinType>>(account);
  }

  #[test_only]
  use std::signer;
  #[test_only]
  use test_addr::test_mod::{Self, DummyCoin};
  #[test(owner = @lending, test_owner = @test_addr)]
  fun test_initialize(owner: &signer, test_owner: &signer) {
    test_mod::initialize_coin_for_test(test_owner);
    initialize<DummyCoin>(owner);

    assert!(coin::is_coin_initialized<SharesCoin<DummyCoin>>(), 0);
    assert!(coin::name<SharesCoin<DummyCoin>>() == string::utf8(b"Shares DummyCoin"), 0);
    assert!(coin::symbol<SharesCoin<DummyCoin>>() == string::utf8(b"sDUMMY"), 0);
    assert!(coin::decimals<SharesCoin<DummyCoin>>() == 18, 0);
    assert!(exists<Capabilities<SharesCoin<DummyCoin>>>(signer::address_of(owner)), 0);
  }
}
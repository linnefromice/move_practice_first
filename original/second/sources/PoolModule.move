module SampleStaking::PoolModule {
  use Std::ASCII;
  use Std::Signer;
  use AptosFramework::Coin;

  struct PairPool<phantom X, phantom Y> has key {
    x: Coin::Coin<X>,
    y: Coin::Coin<Y>,
  }

  public fun add_pair_pool<X, Y>(owner: &signer, x_amount: u64, y_amount: u64) {
    let x = Coin::withdraw<X>(owner, x_amount);
    let y = Coin::withdraw<Y>(owner, y_amount);
    move_to(owner, PairPool<X, Y> { x, y });
  }

  #[test_only]
  use AptosFramework::Coin::{BurnCapability,MintCapability};
  #[test_only]
  struct CoinX {}
  #[test_only]
  struct CoinY {}
  #[test_only]
  struct FakeCapabilities<phantom CoinType> has key {
    mint_cap: MintCapability<CoinType>,
    burn_cap: BurnCapability<CoinType>,
  }
  #[test(owner = @SampleStaking)]
  public(script) fun test_add_pair_pool(owner: &signer) {
    let (x_mint_cap, x_burn_cap) = Coin::initialize<CoinX>(
      owner,
      ASCII::string(b"Coin X"),
      ASCII::string(b"X"),
      10,
      false
    );
    let (y_mint_cap, y_burn_cap) = Coin::initialize<CoinY>(
      owner,
      ASCII::string(b"Coin Y"),
      ASCII::string(b"Y"),
      10,
      false
    );

    Coin::register_internal<CoinX>(owner);
    Coin::register_internal<CoinY>(owner);
    let coin_x = Coin::mint<CoinX>(10000, &x_mint_cap);
    let coin_y = Coin::mint<CoinY>(10000, &y_mint_cap);
    let owner_address = Signer::address_of(owner);
    Coin::deposit<CoinX>(owner_address, coin_x);
    Coin::deposit<CoinY>(owner_address, coin_y);

    move_to(owner, FakeCapabilities<CoinX>{
      mint_cap: x_mint_cap,
      burn_cap: x_burn_cap,
    });
    move_to(owner, FakeCapabilities<CoinY>{
      mint_cap: y_mint_cap,
      burn_cap: y_burn_cap,
    });

    // Execute -> TODO
  }
}
module SampleStaking::PoolModule {
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
}
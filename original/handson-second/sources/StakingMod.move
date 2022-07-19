module HandsonSecond::StakingMod {
  use Std::Signer;
  use HandsonSecond::BaseCoin::{Self, Coin};

  struct Pool<phantom CoinType> has key {
    staking_coin: Coin<CoinType>
  }

  public fun publish_pool<CoinType>(owner: &signer, amount: u64) {
    let owner_address = Signer::address_of(owner);
    let withdrawed = BaseCoin::withdraw<CoinType>(owner_address, amount);
    move_to(owner, Pool<CoinType> {
      staking_coin: withdrawed
    });
  }
}

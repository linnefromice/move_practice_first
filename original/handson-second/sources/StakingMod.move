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

  #[test_only]
  use HandsonSecond::Coins;
  #[test(account = @0x1)]
  fun test_prerequisite(account: &signer) {
    let account_address = Signer::address_of(account);
    assert!(!BaseCoin::is_exist<Coins::RedCoin>(account_address), 0);
    assert!(!BaseCoin::is_exist<Coins::BlueCoin>(account_address), 0);
    BaseCoin::publish<Coins::RedCoin>(account);
    BaseCoin::publish<Coins::BlueCoin>(account);
    assert!(BaseCoin::value<Coins::RedCoin>(account_address) == 0, 0);
    assert!(BaseCoin::value<Coins::BlueCoin>(account_address) == 0, 0);
    assert!(BaseCoin::is_exist<Coins::RedCoin>(account_address), 0);
    assert!(BaseCoin::is_exist<Coins::BlueCoin>(account_address), 0);
  }
}

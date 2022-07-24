module SampleStaking::StakingCoin {
  use SampleStaking::BaseCoin;

  struct StakingCoin has key {}

  public entry fun publish_coin(account: &signer) {
    BaseCoin::publish_coin<StakingCoin>(account);
  }

  public entry fun mint(account: &signer, amount: u64) {
    BaseCoin::mint<StakingCoin>(account, amount);
  }

  public entry fun transfer(from: &signer, to: address, amount: u64) {
    BaseCoin::transfer<StakingCoin>(from, to, amount);
  }
}

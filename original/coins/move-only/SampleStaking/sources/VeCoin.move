module SampleStaking::VeCoin {
  use SampleStaking::BaseCoin;

  struct VeCoin has key {}

  public entry fun publish_coin(account: &signer) {
    BaseCoin::publish_coin<VeCoin>(account);
  }

  public entry fun mint(account: &signer, amount: u64) {
    BaseCoin::mint<VeCoin>(account, amount);
  }

  public entry fun transfer(from: &signer, to: address, amount: u64) {
    BaseCoin::transfer<VeCoin>(from, to, amount);
  }
}

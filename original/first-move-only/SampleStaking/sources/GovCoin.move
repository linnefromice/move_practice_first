module SampleStaking::GovCoin {
  use SampleStaking::BaseCoin;

  struct GovCoin has key {}

  public entry fun publish_coin(account: &signer) {
    BaseCoin::publish_coin<GovCoin>(account);
  }

  public entry fun mint(account: &signer, amount: u64) {
    BaseCoin::mint<GovCoin>(account, amount);
  }

  public entry fun transfer(from: &signer, to: address, amount: u64) {
    BaseCoin::transfer<GovCoin>(from, to, amount);
  }
}

module lending::SharesCoin {
  struct SharesCoin<phantom Coin> has key {}

  public fun initialize<CoinType>(owner: &signer) {
    move_to(owner, SharesCoin<CoinType> {});
  }

  #[test_only]
  use std::signer;
  #[test_only]
  struct DummyCoin {}
  #[test(owner = @lending)]
  fun test_initialize(owner: &signer) {
    initialize<DummyCoin>(owner);
    assert!(exists<SharesCoin<DummyCoin>>(signer::address_of(owner)), 0);
  }
}
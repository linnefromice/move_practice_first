module SampleStaking::Config {
  use Std::Signer;
  friend SampleStaking::LiquidityProviderTokenModule;
  friend SampleStaking::PoolModule;

  const OWNER: address = @SampleStaking;
  const E_NOT_OWNER_ADDRESS: u64 = 101;

  public(friend) fun admin_address(): address {
    OWNER
  }

  public(friend) fun assert_admin(signer: &signer) {
    assert!(Signer::address_of(signer) == OWNER, E_NOT_OWNER_ADDRESS);
  }
}
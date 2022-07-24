module HandsonSecond::Config {
  friend HandsonSecond::StakingMod;
  friend HandsonSecond::LPCoinMod;

  const E_NOT_OWNER_ADDRESS: u64 = 101;

  public fun owner_address(): address {
    @HandsonSecond
  }

  public(friend) fun assert_admin(account: address) {
    assert!(account == owner_address(), E_NOT_OWNER_ADDRESS);
  }
}
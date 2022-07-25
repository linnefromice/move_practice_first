module GovFirst::Config {
  const MODULE_OWNER: address = @GovFirst;

  const E_NOT_MODULE_OWNER: u64 = 1;

  public fun is_module_owner(account: address) {
    assert!(account == MODULE_OWNER, 0);
  }
}
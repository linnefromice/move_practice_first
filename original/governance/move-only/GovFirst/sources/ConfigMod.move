module GovFirst::ConfigMod {
  const MODULE_OWNER: address = @GovFirst;

  const E_NOT_MODULE_OWNER: u64 = 1;

  public fun module_owner(): address {
    MODULE_OWNER
  }

  public fun is_module_owner(account: address) {
    assert!(account == module_owner(), E_NOT_MODULE_OWNER);
  }
}
module gov_second::config_mod {
  const MODULE_OWNER: address = @gov_second;
  
  const E_NOT_MODULE_OWNER: u64 = 1;

  public fun module_owner(): address {
    MODULE_OWNER
  }

  public fun is_module_owner(account: address) {
    assert!(account == module_owner(), E_NOT_MODULE_OWNER);
  }
}

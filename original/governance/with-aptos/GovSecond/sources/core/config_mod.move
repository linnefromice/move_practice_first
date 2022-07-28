module gov_second::config_mod {
  const MODULE_OWNER: address = @gov_second;
  
  const E_NOT_MODULE_OWNER: u64 = 1;

  public fun module_owner(): address {
    MODULE_OWNER
  }

  public fun is_module_owner(account: address): bool {
    account == module_owner()
  }

  public fun assert_is_module_owner(account: address) {
    assert!(is_module_owner(account), E_NOT_MODULE_OWNER);
  }

  #[test]
  fun test_assert_is_module_owner() {
    assert_is_module_owner(@gov_second);
  }
  #[test]
  #[expected_failure(abort_code = 1)]
  fun test_assert_is_module_owner_with_not_owner() {
    assert_is_module_owner(@0x1);
  }
}

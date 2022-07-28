module gov_second::voting_power_mod {
  use std::signer;
  use gov_second::config_mod;

  struct VotingPowerManager has key {
    total_power: u64,
    total_used_power: u64,
    unique_holder_count: u64
  }

  struct VotingPower has key {
    value: u64
  }

  const E_NOT_INITIALIZED: u64 = 1;
  const E_ALREADY_HAVE: u64 = 2;
  const E_NOT_HAVE: u64 = 3;
  const E_INVALID_VALUE: u64 = 4;
  const E_INSUFFICIENT_VOTING_POWER: u64 = 5;

  public fun initialize(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::assert_is_module_owner(owner_address);
    assert!(!exists<VotingPowerManager>(owner_address), E_ALREADY_HAVE);
    move_to(owner, VotingPowerManager {
      total_power: 0,
      total_used_power: 0,
      unique_holder_count: 0
    });
  }

  public fun publish(account: &signer) acquires VotingPowerManager {
    let account_address = signer::address_of(account);
    assert!(!exists<VotingPower>(account_address), E_ALREADY_HAVE);

    let owner_address = config_mod::module_owner();
    assert!(exists<VotingPowerManager>(owner_address), E_NOT_INITIALIZED);
    let vp_manager = borrow_global_mut<VotingPowerManager>(owner_address);
    vp_manager.unique_holder_count = vp_manager.unique_holder_count + 1;

    move_to(account, VotingPower { value: 0 });
  }

  public fun use_voting_power(account: &signer, amount: u64): u64 acquires VotingPowerManager, VotingPower {
    assert!(amount > 0, E_INVALID_VALUE);
    let owner_address = config_mod::module_owner();
    let account_address = signer::address_of(account);
    assert!(exists<VotingPowerManager>(owner_address), E_NOT_INITIALIZED);
    assert!(exists<VotingPower>(account_address), E_NOT_HAVE);

    let vp_manager = borrow_global_mut<VotingPowerManager>(owner_address);
    let vp = borrow_global_mut<VotingPower>(account_address);
    assert!(vp.value >= amount, E_INSUFFICIENT_VOTING_POWER);
    vp.value = vp.value - amount;
    vp_manager.total_used_power = vp_manager.total_used_power + amount;
    amount
  }

  #[test(owner = @gov_second)]
  fun test_initialize(owner: &signer) {
    initialize(owner);
    let owner_address = signer::address_of(owner);
    assert!(exists<VotingPowerManager>(owner_address), 0);
  }
  #[test(owner = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_initialize_with_not_owner(owner: &signer) {
    initialize(owner);
  }
  #[test(owner = @gov_second)]
  #[expected_failure(abort_code = 2)]
  fun test_initialize_with_several_times(owner: &signer) {
    initialize(owner);
    initialize(owner);
  }

  #[test(owner = @gov_second, account1 = @0x1, account2 = @0x2, account3 = @0x3)]
  fun test_publish(owner: &signer, account1: &signer, account2: &signer, account3: &signer) acquires VotingPowerManager {
    initialize(owner);
    publish(account1);
    let account1_address = signer::address_of(account1);
    assert!(exists<VotingPower>(account1_address), 0);
    publish(account2);
    publish(account3);

    let vp_manager = borrow_global<VotingPowerManager>(config_mod::module_owner());
    assert!(vp_manager.unique_holder_count == 3, 0);
  }
  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_publish_before_initialize(account: &signer) acquires VotingPowerManager {
    publish(account);
  }
  #[test(owner = @gov_second, account = @0x1)]
  #[expected_failure(abort_code = 2)]
  fun test_publish_with_several_times(owner: &signer, account: &signer) acquires VotingPowerManager {
    initialize(owner);
    publish(account);
    publish(account);
  }

  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_use_voting_power_before_initialize(account: &signer) acquires VotingPowerManager, VotingPower {
    use_voting_power(account, 1);
  }
  #[test(owner = @gov_second, account = @0x1)]
  #[expected_failure(abort_code = 3)]
  fun test_use_voting_power_before_publish(owner: &signer, account: &signer) acquires VotingPowerManager, VotingPower {
    initialize(owner);
    use_voting_power(account, 1);
  }
  #[test(owner = @gov_second, account = @0x1)]
  #[expected_failure(abort_code = 4)]
  fun test_use_voting_power_with_zero(owner: &signer, account: &signer) acquires VotingPowerManager, VotingPower {
    initialize(owner);
    publish(account);
    use_voting_power(account, 0);
  }
  #[test(owner = @gov_second, account = @0x1)]
  #[expected_failure(abort_code = 5)]
  fun test_use_voting_power_with_no_power(owner: &signer, account: &signer) acquires VotingPowerManager, VotingPower {
    initialize(owner);
    publish(account);
    use_voting_power(account, 1);
  }
}
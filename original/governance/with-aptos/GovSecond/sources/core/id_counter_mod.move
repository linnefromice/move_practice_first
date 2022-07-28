module gov_second::id_counter_mod {
  use std::signer;
  use gov_second::config_mod;

  struct IdCounter<phantom For> has key {
    value: u64
  }

  const E_ALREADY_HAVE: u64 = 1;

  public fun publish_id_counter<For>(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::assert_is_module_owner(owner_address);
    assert!(!exists<IdCounter<For>>(owner_address), E_ALREADY_HAVE);
    move_to(owner, IdCounter<For>{ value: 0 });
  }

  #[test_only]
  struct Test1VotingMethod {}
  #[test_only]
  struct Test2VotingMethod {}
  #[test(account = @gov_second)]
  fun test_publish_id_counter(account: &signer) acquires IdCounter {
    let account_address = signer::address_of(account);
    assert!(!exists<IdCounter<Test1VotingMethod>>(account_address), 0);
    assert!(!exists<IdCounter<Test2VotingMethod>>(account_address), 0);

    publish_id_counter<Test1VotingMethod>(account);
    assert!(exists<IdCounter<Test1VotingMethod>>(account_address), 0);
    assert!(borrow_global<IdCounter<Test1VotingMethod>>(account_address).value == 0, 0);
    assert!(!exists<IdCounter<Test2VotingMethod>>(account_address), 0);

    publish_id_counter<Test2VotingMethod>(account);
    assert!(exists<IdCounter<Test2VotingMethod>>(account_address), 0);
    assert!(borrow_global<IdCounter<Test2VotingMethod>>(account_address).value == 0, 0);
  }
  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_publish_id_counter_by_not_owner(account: &signer) {
    publish_id_counter<Test1VotingMethod>(account);
  }
  #[test(account = @gov_second)]
  #[expected_failure(abort_code = 1)]
  fun test_publish_id_counter_with_several_times(account: &signer) {
    publish_id_counter<Test1VotingMethod>(account);
    publish_id_counter<Test1VotingMethod>(account);
  }
}
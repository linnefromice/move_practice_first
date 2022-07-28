module gov_second::pro_con_voting_method_mod {
  use std::signer;
  use aptos_framework::table::{Self, Table};
  use gov_second::config_mod;
  use gov_second::proposal_meta_mod;

  struct VotingForum has key {
    proposals: Table<u64, Proposal>
  }

  struct Proposal has store {
    meta: proposal_meta_mod::ProposalMeta,
    yes_votes: u64,
    no_votes: u64,
  }

  const E_ALREADY_HAVE: u64 = 1;

  public fun initialize(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::assert_is_module_owner(owner_address);
    assert!(!exists<VotingForum>(owner_address), E_ALREADY_HAVE);
    move_to(owner, VotingForum { proposals: table::new() })
  }

  #[test(owner = @gov_second)]
  fun test_initialize(owner: &signer) {
    initialize(owner);
    let owner_address = signer::address_of(owner);
    assert!(exists<VotingForum>(owner_address), 0);
  }
  #[test(owner = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_initialize_by_not_owner(owner: &signer) {
    initialize(owner);
  }
  #[test(owner = @gov_second)]
  #[expected_failure(abort_code = 1)]
  fun test_initialize_with_several_times(owner: &signer) {
    initialize(owner);
    initialize(owner);
  }
}
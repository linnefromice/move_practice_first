module gov_first::voting_mod {
  use std::string;
  use aptos_framework::table::{Self, Table};
  use gov_first::ballot_box_mod::BallotBox;
  use gov_first::config_mod;

  struct VotingForum has key {
    ballot_boxes: Table<u64, BallotBox>,
  }

  public fun initialize(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::is_module_owner(owner_address);
    move_to(owner, VotingForum { ballot_boxes: table::new() })
  }

  #[test(owner = @gov_first)]
  fun test_initialize(owner: &signer) {
    initialize(owner);
    let owner_address = signer::address_of(owner);
    assert!(exists<VotingForum>(owner_address), 0);
  }
  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_initialize_with_not_module_owner(account: &signer) {
    initialize(account);
  }
}
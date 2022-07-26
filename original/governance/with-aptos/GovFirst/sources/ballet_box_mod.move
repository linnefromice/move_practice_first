module gov_first::ballot_box_mod {
  use std::signer;
  use gov_first::config_mod;
  use gov_first::proposal_mod::Proposal;

  struct IdCounter has key {
    value: u64
  }

  struct BallotBox has key {
    uid: u64,
    proposal: Proposal,
  }

  public fun initialize(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::is_module_owner(owner_address);
    move_to(owner, IdCounter { value: 0 });
  }

  public fun create_ballot_box(proposal: Proposal): BallotBox acquires IdCounter {
    let id_counter = borrow_global_mut<IdCounter>(config_mod::module_owner());
    id_counter.value = id_counter.value + 1;
    BallotBox {
      uid: id_counter.value,
      proposal
    }
  }

  #[test(owner = @gov_first)]
  fun test_initialize(owner: &signer) acquires IdCounter {
    initialize(owner);
    let id_counter = borrow_global<IdCounter>(config_mod::module_owner());
    assert!(id_counter.value == 0, 0);
  }

  #[test(owner = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_initialize_with_not_module_owner(owner: &signer) {
    initialize(owner);
  }
}
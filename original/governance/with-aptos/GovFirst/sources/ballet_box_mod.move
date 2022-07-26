module gov_first::ballot_box_mod {
  use std::signer;
  use std::string;
  use gov_first::config_mod;
  use gov_first::proposal_mod::{Self, Proposal};

  struct IdCounter has key {
    value: u64
  }

  struct BallotBox has key {
    uid: u64,
    proposal: Proposal,
  }

  const E_NOT_INITIALIZED: u64 = 1;

  public fun initialize(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::is_module_owner(owner_address);
    move_to(owner, IdCounter { value: 0 });
  }

  public fun create_ballot_box(proposal: Proposal): BallotBox acquires IdCounter {
    let module_owner = config_mod::module_owner();
    assert!(exists<IdCounter>(module_owner), E_NOT_INITIALIZED);
    let id_counter = borrow_global_mut<IdCounter>(module_owner);
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

  #[test(owner = @gov_first, account = @0x1)]
  fun test_create_ballot_box(owner: &signer, account: &signer) acquires IdCounter {
    initialize(owner);
    let proposal = proposal_mod::create_proposal(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
    );
    let ballot_box = create_ballot_box(proposal);
    assert!(ballot_box.uid == 1, 0);

    move_to(account, ballot_box);
  }

  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_create_ballot_box_before_initialize(account: &signer) acquires IdCounter {
    let proposal = proposal_mod::create_proposal(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
    );
    let ballot_box = create_ballot_box(proposal); // fail here
    move_to(account, ballot_box);
  }
}

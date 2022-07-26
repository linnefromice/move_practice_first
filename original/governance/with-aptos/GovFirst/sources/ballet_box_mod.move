module gov_first::ballot_box_mod {
  use std::signer;
  use aptos_framework::timestamp;
  use gov_first::config_mod;
  use gov_first::proposal_mod::Proposal;

  struct IdCounter has key {
    value: u64
  }

  struct BallotBox has key, store {
    uid: u64,
    proposal: Proposal,
    expiration_secs: u64,
    created_at: u64,
  }

  const E_NOT_INITIALIZED: u64 = 1;

  public fun initialize(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::is_module_owner(owner_address);
    move_to(owner, IdCounter { value: 0 });
  }

  public fun create_ballot_box(proposal: Proposal, expiration_secs: u64): BallotBox acquires IdCounter {
    let module_owner = config_mod::module_owner();
    assert!(exists<IdCounter>(module_owner), E_NOT_INITIALIZED);
    // uid
    let id_counter = borrow_global_mut<IdCounter>(module_owner);
    id_counter.value = id_counter.value + 1;
    // created_at
    let current_seconds = timestamp::now_microseconds();
    BallotBox {
      uid: id_counter.value,
      proposal,
      expiration_secs,
      created_at: current_seconds,
    }
  }

  // Getter
  public fun uid(obj: &BallotBox): u64 {
    obj.uid
  }

  #[test_only]
  use std::string;
  #[test_only]
  use gov_first::proposal_mod;
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

  #[test(framework = @AptosFramework, owner = @gov_first, account = @0x1)]
  fun test_create_ballot_box(framework: &signer, owner: &signer, account: &signer) acquires IdCounter {
    timestamp::set_time_has_started_for_testing(framework);
    let per_microseconds = 1000 * 1000;
    let day = 24 * 60 * 60;
    timestamp::update_global_time_for_test(7 * day * per_microseconds);

    initialize(owner);
    let proposal = proposal_mod::create_proposal(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
    );
    let ballot_box = create_ballot_box(proposal, day);
    assert!(ballot_box.uid == 1, 0);
    assert!(ballot_box.expiration_secs == 1 * day, 0);
    assert!(ballot_box.created_at == 7 * day * per_microseconds, 0);

    move_to(account, ballot_box);
  }

  #[test(framework = @AptosFramework, account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_create_ballot_box_before_initialize(framework: &signer, account: &signer) acquires IdCounter {
    timestamp::set_time_has_started_for_testing(framework);
    let proposal = proposal_mod::create_proposal(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
    );
    let ballot_box = create_ballot_box(proposal, 100); // fail here
    move_to(account, ballot_box);
  }
}

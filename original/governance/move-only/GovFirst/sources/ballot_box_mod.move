module gov_first::ballot_box_mod {
  use std::signer;
  use gov_first::proposal_mod::Proposal;
  use gov_first::config_mod;

  struct ProposalIdCounter has key {
    value: u64
  }

  struct BallotBox has key, store {
    uid: u64,
    proposal: Proposal,
    expiration_timestamp: u64, // temp
    created_at: u64, // temp
  }

  public fun initialize(owner: &signer) {
    let owner_address = signer::address_of(owner);
    config_mod::is_module_owner(owner_address);
    move_to(owner, ProposalIdCounter { value: 0 });
  }

  public fun create_ballot_box(proposal: Proposal): BallotBox acquires ProposalIdCounter {
    let id_counter = borrow_global_mut<ProposalIdCounter>(config_mod::module_owner());
    id_counter.value = id_counter.value + 1;
    BallotBox {
      uid: id_counter.value,
      proposal,
      expiration_timestamp: 0,
      created_at: 0,
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
  #[test(account = @gov_first)]
  fun test_initialize(account: &signer) acquires ProposalIdCounter {
    initialize(account);
    let account_address = signer::address_of(account);
    assert!(exists<ProposalIdCounter>(account_address), 0);
    let id_counter = borrow_global<ProposalIdCounter>(account_address);
    assert!(id_counter.value == 0, 0);
  }
  #[test(account = @0x1)]
  #[expected_failure(abort_code = 1)]
  fun test_initialize_when_not_owner_module(account: &signer) {
    initialize(account);
  }
  #[test(account = @gov_first)]
  fun test_create_ballot_box(account: &signer) acquires ProposalIdCounter {
    initialize(account);
    let account_address = signer::address_of(account);
    assert!(borrow_global<ProposalIdCounter>(account_address).value == 0, 0);
    let proposal = proposal_mod::create_proposal(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
    );
    let ballot_box = create_ballot_box(proposal);
    assert!(ballot_box.uid == 1, 0);
    assert!(ballot_box.expiration_timestamp == 0, 0);
    assert!(ballot_box.created_at == 0, 0);
    assert!(borrow_global<ProposalIdCounter>(account_address).value == 1, 0);

    move_to(account, ballot_box);
  }
}
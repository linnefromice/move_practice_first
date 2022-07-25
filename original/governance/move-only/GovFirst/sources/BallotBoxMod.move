module GovFirst::BallotBoxMod {
  use std::signer;
  use GovFirst::ProposalMod::Proposal;
  use GovFirst::ConfigMod;

  struct ProposalIdCounter has key {
    value: u64
  }

  struct BallotBox has key {
    uid: u64,
    proposal: Proposal,
    expiration_timestamp: u64, // temp
    created_at: u64, // temp
  }

  public fun initialize(owner: &signer) {
    let owner_address = signer::address_of(owner);
    ConfigMod::is_module_owner(owner_address);
    move_to(owner, ProposalIdCounter { value: 0 });
  }

  fun create_ballot_box(proposal: Proposal): BallotBox acquires ProposalIdCounter {
    let id_counter = borrow_global_mut<ProposalIdCounter>(ConfigMod::module_owner());
    id_counter.value = id_counter.value + 1;
    BallotBox {
      uid: id_counter.value,
      proposal,
      expiration_timestamp: 0,
      created_at: 0,
    }
  }

  #[test_only]
  use std::string;
  #[test_only]
  use GovFirst::ProposalMod;
  #[test(account = @GovFirst)]
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
  #[test(account = @GovFirst)]
  fun test_create_ballot_box(account: &signer) acquires ProposalIdCounter {
    initialize(account);
    let account_address = signer::address_of(account);
    assert!(borrow_global<ProposalIdCounter>(account_address).value == 0, 0);
    let proposal = ProposalMod::create_proposal(
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
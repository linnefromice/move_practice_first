module GovFirst::BallotBoxMod {
  use GovFirst::ProposalMod::Proposal;

  struct BallotBox has key {
    proposal: Proposal,
    expiration_timestamp: u64, // temp
    created_at: u64, // temp
  }

  fun create_ballot_box(proposal: Proposal): BallotBox {
    BallotBox { 
      proposal,
      expiration_timestamp: 0,
      created_at: 0,
    }
  }

  #[test_only]
  use std::string;
  #[test_only]
  use GovFirst::ProposalMod;
  #[test(account = @0x1)]
  fun test_create_ballot_box(account: &signer) {
    let proposal = ProposalMod::create_proposal(
      account,
      string::utf8(b"proposal_title"),
      string::utf8(b"proposal_content"),
    );
    let ballot_box = create_ballot_box(proposal);
    assert!(ballot_box.expiration_timestamp == 0, 0);
    assert!(ballot_box.created_at == 0, 0);
    move_to(account, ballot_box);
  }
}
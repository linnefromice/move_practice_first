module GovFirst::BallotBoxMod {
  use GovFirst::ProposalMod::Proposal;

  struct BallotBox has key {
    proposal: Proposal,
  }

  fun create_ballot_box(proposal: Proposal): BallotBox {
    BallotBox { proposal }
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
    move_to(account, ballot_box);
  }
}
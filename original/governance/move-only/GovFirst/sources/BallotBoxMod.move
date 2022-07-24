module GovFirst::BallotBoxMod {
  use GovFirst::ProposalMod::Proposal;

  struct BallotBox has key {
    proposal: Proposal,
  }

  fun create_ballot_box(proposal: Proposal): BallotBox {
    BallotBox { proposal }
  }
}
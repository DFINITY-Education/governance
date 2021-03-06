import Array "mo:base/Array";
import Float "mo:base/Float";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Types "./Types";

actor class Governor(starterApp: Principal, voteThreshold: Float, neuronLedger: Principal) {

  type NeuronId = Types.NeuronId;
  type Proposal = Types.Proposal;
  type ProposalStatus = Types.ProposalStatus;
  type Vote = Types.Vote;

  type Result = Result.Result<(), Types.GovError>;
  type PropResult = Result.Result<ProposalStatus, Types.GovError>;

  var currentApp = starterApp;
  // This should use BigMap
  var proposals: [var Proposal] = [var];

  public query func getCurrentApp() : async (Principal) {
    currentApp
  };

  /// Swaps in the new App canister to replace the previous version. This is the result of
  ///   a migration proposal succeeding.
  /// Args:
  ///   |propNum|  The number representing the passed proposal.
  /// Returns:
  ///   A Result indicating if the migration was successfully executed (see "GovError" in Types.mo for possible errors).
  public func migrate(propNum: Nat) : async (Result) {
    switch (_checkProposal(propNum)) {
      case (#ok(status)) {
        switch (status) {
          case (#succeeded) {
            currentApp := proposals[propNum].newApp;
            #ok()
          };
          case (_) #err(#proposalNotActive);
        }
      };
      case (#err(e)) #err(e);
    }
  };

  /// Creates a new proposal for App migration.
  /// Args:
  ///   |neuron|  The id of the neuron creating this proposal. 
  ///   |newApp|  The Princpal id of the new proposed App.
  /// Returns:
  ///   The id associated with this proposal.
  public shared(msg) func propose(neuron: NeuronId, newApp: Principal) : async (Nat) {
    assert(msg.caller == neuronLedger);

    proposals := Array.thaw<Proposal>(
      Array.append<Proposal>(Array.freeze<Proposal>(proposals), [makeProposal(newApp, neuron)]));
    proposals.size();
  };

  /// Cancels a proposal (can ony be called by the owner of the proposal).
  /// Args:
  ///   |neuron|   The id of the neuron creating this proposal. 
  ///   |propNum|  The id of the proposal.
  /// Returns:
  ///   A Result indicating if the cancellation was successfully executed (see "GovError" in Types.mo for possible errors).
  public shared(msg) func cancelProposal(neuron: NeuronId, propNum: Nat) : async (Result) {
    assert(msg.caller == neuronLedger);

    if (proposals.size() < propNum) return #err(#proposalNotFound);
    let prop = proposals[propNum];
    if (neuron != prop.proposer) return #err(#incorrectPermissions);
    switch (prop.status) {
      case (#active) {
        prop.status := #canceled;
        proposals[propNum] := prop;
        #ok()
      };
      case (_) #err(#proposalNotActive);
    }
  };

  /// Records a new proposal vote.
  /// Args:
  ///   |neuron|        The id of the neuron creating this proposal. 
  ///   |propNum|       The id of the proposal.
  ///   |vote|          The vote being case (variant type Vote - see Types.mo)
  ///   |votingPower|   The number of votes cast for this proposal (the voting power of the neuron). 
  /// Returns:
  ///   A Result indicating if the vote was successfully recorded (see "GovError" in Types.mo for possible errors).
  public shared(msg) func voteOnProposal(neuron: NeuronId, propNum: Nat, vote: Vote, votingPower: Nat) : async (Result) {
    assert(msg.caller == neuronLedger);

    switch (_checkProposal(propNum)) {
      case (#ok(status)) {
        switch (status) {
          case (#active) {
            let prop = proposals[propNum];
            switch (vote) {
              case (#inFavor) prop.votesFor += 1;
              case (#against) prop.votesAgainst += 1;
            };
            proposals[propNum] := prop;
            #ok()
          };
          case (_) #err(#proposalNotActive);
        }
      };
      case (#err(e)) #err(e);
    }
  };

  /// External-facing method for inter-canister calls
  public func checkProposal(propNum: Nat) : async (PropResult) {
    _checkProposal(propNum)
  };

  /// Checks if the given proposal has exceeded its time to live.
  ///   If so, checks if the vote has passed the given threshold.
  /// Args:
  ///   |propNum|  The id of the proposal.
  /// Returns:
  ///   The new status of this proposal (in the form of the PropResult variant - see Types.mo)
  func _checkProposal(propNum: Nat) : (PropResult) {
    if (proposals.size() < propNum) return #err(#proposalNotFound);
    let prop = proposals[propNum];
    let status = switch (prop.status) {
      case (#active) {
        if (Time.now() > prop.ttl) {
          let outcome = Float.div(
              Float.fromInt(prop.votesFor),
              (Float.fromInt(prop.votesFor) + Float.fromInt(prop.votesAgainst))
            );
          if (outcome > voteThreshold) {
            prop.status := #succeeded;
            proposals[propNum] := prop;
            #succeeded
          } else {
            prop.status := #defeated;
            proposals[propNum] := prop;
            #defeated
          }
        } else {
          #active
        }
      };
      case (anythingElse) anythingElse;
    };

    #ok(status)
  };

  /// Helper called in Propose - used to create a new proposal
  /// Args:
  ///   |_newApp|   The Principal of the newly proposed App.
  ///   |_proposer| The canister making the proposal.
  /// Returns:
  ///   The new Proposal object (see Types.mo)
  func makeProposal(_newApp: Principal, _proposer: NeuronId) : (Proposal) {
    {
      newApp = _newApp;
      proposer = _proposer;
      var votesFor = 0;
      var votesAgainst = 0;
      var status: ProposalStatus = #active;
      var alreadyVoted = [];
      ttl = Time.now() + (3600 * 1000_000_000);
    }
  };

};

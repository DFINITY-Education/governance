import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Result "mo:base/Result";

module {

  public type NeuronId = Nat;

  public type Neuron = {
    votingPower: Nat;
    dissolveDelay: Nat;
    lockedTokens: Nat;
  };

  public type ProposalStatus = {
    #active;
    #canceled;
    #defeated;
    #succeeded;
  };

  public type Proposal = {
    newApp: Principal;
    proposer: NeuronId;
    var votesFor: Nat;
    var votesAgainst: Nat;
    var alreadyVoted: [NeuronId];
    var status: ProposalStatus;
    ttl: Int;
  };

  public type Error = {
    #belowMinimumBid;
    #insufficientBalance;
    #auctionNotFound;
    #userNotFound;
  };

  public type Vote = {
    #inFavor;
    #against;
  };

  public type GovError = {
    #noGovernor;
    #incorrectPermissions;
    #proposalNotFound;
    #proposalNotActive;
  };

};

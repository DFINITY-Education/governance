import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";

import Token "mo:motoko-token/Token";

import Types "./types";

actor class NeuronLedger(tokenLedger: Principal) {

    type Neuron = Types.Neuron;
    type NeuronId = Types.NeuronId;

    let neurons = HashMap.HashMap<Principal, Neuron>(1, Principal.equal, Principal.hash);
    let followers = HashMap.HashMap<NeuronId, [NeuronId]>(1, Nat.equal, Hash.hash);

    public func createNeuron(tokensToLock: Nat, tokenActor: Principal) {
        // Caller must have enough tokens
        assert(true);

    };

    public func dissolveNeuron() {};

    public func claimNeuronRewards() {};

    public func followNeuron() {};

    public func voteAccept() {};

    public func voteReject() {};

    func cascade() {};

};

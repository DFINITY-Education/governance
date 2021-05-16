import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Token "mo:motoko-token/Token";

import Governor "./governor";
import Types "./types";

actor class NeuronLedger(tokenLedgerPid: Principal) = NL {

    type Time = Time.Time;

    type Governor = Governor.Governor;
    type Neuron = Types.Neuron;
    type NeuronId = Types.NeuronId;
    type Vote = Types.Vote;

    let tokenLedger = actor (Principal.toText(tokenLedgerPid)) : Token.Token;

    let ownersToNeuronIds = HashMap.HashMap<Principal, NeuronId>(1, Principal.equal, Principal.hash);
    let neuronIdsToNeurons = HashMap.HashMap<NeuronId, Neuron>(1, Nat.equal, Hash.hash);

    var neuronCount = 0;
    var totalLocked = 0;

    func me() : Principal { Principal.fromActor(NL) };
    func totalSupply() : async Nat { await tokenLedger.totalSupply() };
    func intoGovernorActor(governorPid: Principal) : Governor { actor (Principal.toText(governorPid)) };

    public shared(msg) func createNeuron(lockedTokens: Nat, dissolveDelay: Nat) {
        // Caller must not already have a neuron
        switch (ownersToNeuronIds.get(msg.caller)) {
            case (?neuron) assert(false);
            case (null) {
                // Caller must have enough tokens
                switch (await tokenLedger.balanceOf(Principal.toText(msg.caller))) {
                    case (?balance) assert(balance >= lockedTokens);
                    case (null) assert(false);
                };

                // Transfer must succeed
                if (not 
                    (await 
                        tokenLedger.transferFrom(
                            Principal.toText(msg.caller),
                            Principal.toText(me()),
                            lockedTokens
                        )
                    )
                ) {
                    assert(false);
                };

                ownersToNeuronIds.put(msg.caller, neuronCount);
                neuronIdsToNeurons.put(
                    neuronCount,
                    newNeuron(Time.now(), lockedTokens, dissolveDelay, null)
                );

                neuronCount += 1;
                totalLocked += lockedTokens;
            };
        };
    };

    public shared(msg) func dissolveNeuron() {
        // Caller must already have a neuron
        switch (ownersToNeuronIds.get(msg.caller)) {
            case (?id) {
                switch (neuronIdsToNeurons.get(id)) {
                    case (?neuron) {
                        // Dissolve delay must be zero
                        if (Time.now() - neuron.dissolveDelay < neuron.startingTime) {
                            assert(false);
                        };

                        // Transfer must succeed
                        if (not 
                            (await 
                                tokenLedger.transfer(
                                    Principal.toText(msg.caller),
                                    neuron.lockedTokens + calculateReward(neuron)
                                )
                            )
                        ) {
                            assert(false);
                        };

                        ownersToNeuronIds.delete(msg.caller);
                        neuronIdsToNeurons.delete(id);

                        totalLocked -= neuron.lockedTokens;
                    };
                    case (null) assert(false);
                };
                
            };
            case (null) assert(false);
        };
    };

    public shared(msg) func followNeuron(neuronIdToFollow: NeuronId) {
        // Neuron to follow must exist
        if (Option.isNull(neuronIdsToNeurons.get(neuronIdToFollow))) {
            assert(false);
        };
        // Caller must already have a neuron
        switch (ownersToNeuronIds.get(msg.caller)) {
            case (null) assert(false);
            case (?neuronId) {
                // Ensure there are no cycles
                assert(checkForCycles(neuronId, neuronIdToFollow));

                switch (neuronIdsToNeurons.get(neuronId)) {
                    case (null) assert(false);
                    case (?neuron) {        
                        // Add neuronId to set of followers
                        neuronIdsToNeurons.put(
                            neuronId,
                            newNeuron(
                                neuron.startingTime,
                                neuron.lockedTokens,
                                neuron.dissolveDelay,
                                ?neuronIdToFollow
                            )
                        );
                    };
                };
            };
        };
    };

    public shared(msg) func voteOnProposal(governor: Principal, propNum: Nat, vote: Vote) {
        // Caller must already have a neuron
        switch (ownersToNeuronIds.get(msg.caller)) {
            case (?id) {
                switch (neuronIdsToNeurons.get(id)) {
                    case (?neuron) {
                        // Neuron must not be following anyone to vote manually
                        if (Option.isSome(neuron.following)) {
                            assert(false);
                        };

                        let governorActor = intoGovernorActor(governor);
                        let result = await governorActor.voteOnProposal(
                                            id,
                                            propNum,
                                            vote,
                                            neuron.votingPower + cascadeVotingPower(id)
                                        );
                        if (Result.isErr(result)) {
                            assert(false);
                        };
                    };
                    case (null) assert(false);
                };
            };
            case (null) assert(false);
        };
    };

    func cascadeVotingPower(id: NeuronId) : Nat {
        var n = 0;
        var neuronsToCascade = List.nil<NeuronId>();
        for ((k, v) in neuronIdsToNeurons.entries()) {
            switch (v.following) {
                case (?following) {
                    if (following == id) {
                        n += v.votingPower;
                        neuronsToCascade := List.push<NeuronId>(k, neuronsToCascade);
                    };
                };
                case (null) {};
            };
        };
        List.iterate<NeuronId>(
            neuronsToCascade,
            func (id: NeuronId) {
                n += cascadeVotingPower(id);
            }
        );

        n
    };

    func checkForCycles(follower: NeuronId, followee: NeuronId) : Bool {
        true
    };

    func calculateReward(neuron: Neuron) : Nat {
        0
    };

    func newNeuron(
        startingTime: Time,
        dissolveDelay: Nat,
        lockedTokens: Nat,
        following: ?NeuronId
    ) : Neuron {
        {
            votingPower = dissolveDelay * lockedTokens;
            startingTime;
            dissolveDelay;
            lockedTokens;
            var following;
        }
    };

};

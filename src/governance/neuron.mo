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

    // Used to assign a unique ID to each neuron (incremented by 1 for each neuron created)
    var neuronCount = 0;
    // Keeps track of total number of tokens locked across all neurons
    var totalLocked = 0;

    let ownersToNeuronIds = HashMap.HashMap<Principal, NeuronId>(1, Principal.equal, Principal.hash);
    let neuronIdsToNeurons = HashMap.HashMap<NeuronId, Neuron>(1, Nat.equal, Hash.hash);

    func me() : Principal { Principal.fromActor(NL) };
    func totalSupply() : async Nat { await tokenLedger.totalSupply() };
    func intoGovernorActor(governorPid: Principal) : Governor { actor (Principal.toText(governorPid)) };

    /// Allows caller to create a new neuron, which is stored in the |ownersToNeuronIds| and |neuronIdsToNeurons| hashmaps.
    /// Args:
    ///   |lockedTockens|  The number of tokens locked in this neuron.
    ///   |dissolveDelay|  The initial dissolve delay of this neuron.
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

    /// Dissolves the caller's neuron if the dissolveDelay has elapsed
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

    /// Instructs the caller's neuron to follow |neuronIdToFollow| 
    /// Args:
    ///   |neuronIdToFollow|  The ID of the neuron being followed (stored in |ownersToNeuronIds|)
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

    /// Instructs caller's neuron to create a new proposal.
    /// Args:
    ///   |governor|  The governor that maintains proposals.
    ///   |newApp|    The application being proposed.
    public shared(msg) func propose(governor: Principal, newApp: Principal) {
        // Caller must already have a neuron
        switch (ownersToNeuronIds.get(msg.caller)) {
            case (?id) {
                switch (neuronIdsToNeurons.get(id)) {
                    case (?neuron) {
                        let governorActor = intoGovernorActor(governor);
                        let result = await governorActor.propose(
                                            id,
                                            newApp
                                        );
                    };
                    case (null) assert(false);
                };
            };
            case (null) assert(false);
        };
    };

    /// Instructs caller's neuron to cancel one of their proposals.
    /// Args:
    ///   |governor|  The governor that maintains proposals.
    ///   |propNum|   The unique ID of the proposal.
    public shared(msg) func cancelProposal(governor: Principal, propNum: Nat) {
        // Caller must already have a neuron
        switch (ownersToNeuronIds.get(msg.caller)) {
            case (?id) {
                switch (neuronIdsToNeurons.get(id)) {
                    case (?neuron) {
                        let governorActor = intoGovernorActor(governor);
                        let result = await governorActor.cancelProposal(
                                            id,
                                            propNum
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

    /// Instructs caller's neuron to vote on a given proposal.
    /// Args:
    ///   |governor|  The governor that maintains proposals.
    ///   |propNum|   The unique ID of the proposal.
    ///   |vote|      The vote being cast (defined in types.mo).
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

    /// Helper method to calculate the voting power of the neurons following neuron |id|. The greater the number
    ///     of followees a neuron has, the greater its cascading voting power
    /// Args:
    ///   |id|  The NeuronId of the neuron we want to calculate the cascading voting power of. 
    /// Returns:
    ///   A nat representing the voting power of |id|'s followees.
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

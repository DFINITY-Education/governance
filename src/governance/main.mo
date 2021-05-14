import Principal "mo:base/Principal";

import Token "mo:motoko-token/Token";

import Governor "./governor";
import NeuronLedger "./neuron";
import InitialApp "./initialApp";

actor {

    public func deployApp(name : Text) : async (Principal, Principal) {
        let token = await Token.Token();
        let neuron = await NeuronLedger.NeuronLedger(Principal.fromActor(token));
        let initialApp = await InitialApp.HelloWorld();
        let governor = await Governor.Governor(Principal.fromActor(initialApp), 10, Principal.fromActor(neuron));

        (Principal.fromActor(neuron), Principal.fromActor(governor))
    };

};

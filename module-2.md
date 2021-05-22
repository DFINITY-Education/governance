# Module 2: Neuron Creation

In this module, students will begin the process of creating their own open governance system by implementing a basic version of NNS. In Module 2 we outline the process for locking tokens to create neurons, and Modules 3 + 4 will continue this process to add additional features to our governance model.

## Background

As we previously mentioned, users can lock their ICP for a predetermined length of time to create a neuron, which allows them to vote on proposals in the NNS and receive rewards in the form of ICP for this participation. Before we jump into the code for this module, let's dive a bit deeper into the Network Nervous System (NNS) behind the IC, which we touched briefly upon in [Module 1](module-1.md). 

### Creating Neurons

When a user attempts to create a new neuron, they must specify an amount of ICP to "lock" in the neuron as well as the **dissolve delay**. The dissolve delay of a neuron is a value between 0 and 8 years, indicating the amount of time a user will need to wait to unlock the ICP in the neuron once they have initiated the "dissolve mode". There are three main states for a neuron:

1. **Locked:** The neuron is locked with a specified *dissolve delay*. If a user wants to access their ICP, they must first switch this neuron to the *dissolving* state, which initiates a countdown from their stated *dissolve delay*. In this state, the *dissolve delay* doesn't change over time. 
2. **Dissolving:** The neuron's dissolve delay decreases with the passage of time until it reaches 0, at which point the neuron is *dissolved* and the user can access their ICP. The user can invoke the `stop_dissolving` method to switch the neuron to the *locked* state.
3. **Dissolved:** The neuron's *dissolve delay* is 0 and the user can access their ICP by "disbursing" the neuron. Neurons in the *dissolved* state cannot vote because they have a *dissolve delay* less than six months.

The dissolve delay for a neuron can be increased after the neuron is created, but it can only be decreased through the passage of time while the neuron is in the *dissolving* state. Neurons can only vote if they have a *dissolve delay* greater than six months. Additionally, neurons maintain an `Age`, which represents the time that has elapsed since the neuron was created or last stopped dissolving. As a result, the `Age` of a neuron resets to 0 the moment the neuron begins dissolving and will grow from 0 if the neuron is locked again.

#### Example

Suppose Alice locks 100 ICP in a neuron, sets the `DissolveDelay` to 1 year, and puts the neuron in the `Locked` state. She waits 2 years and then decides to begin dissolving her neuron. At this point, her neuron has an `Age` of 2 years that resets to 0, and she must wait an additional year (the length of the unchanged `DissolveDelay`) before her neuron will be `Dissolved` and she can access the ICP inside.

## Your Task

We have provided you with starter code for a simplified version of the NNS that could be used for open governance of an internet service. In this module, you will complete several methods that enable users to lock ICP and create neurons.

### Simplifying Assumptions

Our basic version of the NNS makes several important simplifications from the original NNS to make the coding process a bit easier. The main simplifications we've made are as follows:

* Users can only create one neuron and follow one other neuron.
* Users cannot change the Dissolve Delay of their neuron. We don't keep track of the three aforementioned states of the neuron (locked, dissolving, and dissolved) and assume that all neurons are in the "dissolving" state.

One could quite easily modify the starter code to add in these features - consider it a bonus exercise!

### Code Understanding

#### `types.mo`

Let's begin by reviewing the notable types in `Types.mo`. In particular, notice that a `NeuronId` is simply a Nat that serves as a unique identifier for a neuron. Additionally, a `Neuron` type stores all of the relevant information for a neuron, including attributes like its `startingTime` (time at which it was created), `dissolveDelay`, and number of `lockedTokens`.

#### `neuron.mo`

Next, let's turn to the main actor: the `NeuronLedger` class. This class keeps track of all neurons and their relevant methods. To instantiate a `NeuronLedger`, one must provide a `tokenLedgerPid` as a parameter, which represents the Principal id of the ledger storing all user token balances. The `NeuronLedger` needs access to this canister in order to add and subtract tokens from users' balances when they lock/dissolve neurons. 

```
import Token "mo:motoko-token/Token";
```

For our token ledger, we use the ERC-20 style token used in the [Blockchain and Cryptocurrency](https://github.com/DFINITY-Education/blockchain-and-cryptocurrency) course (imported using the above code). For a refresher on this token, please read over [Module 2](https://github.com/DFINITY-Education/blockchain-and-cryptocurrency/blob/main/module-2.md) of that course and view the [source code](https://github.com/DFINITY-Education/blockchain-and-cryptocurrency/tree/main/vendor/motoko-token) for this token. You will need to familiarize yourself with several of the methods in this token, including `balanceOf()`, `transfer()`, and `transferFrom()`.

We store the Token canister in the `tokenLedger` variable, which we can use to access properties about user balances and the token itself. For instance, we create the `totalSupply()` method by simply making a call to `tokenLedger.totalSupply()`. To store neurons and their corresponding owners, we use two hash maps: `ownersToNeuronIds` and `neuronIdsToNeurons`. While we really only need one hash map because users can only have a single neuron, we implemented it in this way to easily enable users to have multiple neurons downs the line, if desired.

Finally, we have provided you with the helper function `newNeuron`, which takes in the relevant attributes needed to create a neuron and returns a `Neuron` type object.

### Specification

**Task:** Complete the implementation of the `createNeuron()` and `dissolveNeuron()` methods in `neuron.mo`.

**`createNeuron(lockedTokens: Nat, dissolveDelay: Nat)`** allows the method caller to create a new neuron, which we store in the `ownersToNeuronIds` and `neuronIdsToNeurons` hash maps.

* You must first ensure that the caller doesn't already have a neuron and that they have sufficient balance to lock the specified number of `lockedTokens` up. If the method caller doesn't satisfy either of these, `assert(false)` and do not create the neuron.
  * You will need to use the `balanceOf` method on the `tokenLedger` to access the caller's balance. Note that `balanceOf` accepts the principal id in `Text` form, so you must first convert the caller's principal id to text with the `Principal.toText()` method.
* When a neuron is created, you must transfer `lockedTokens` from the caller to the `NeuronLedger`. You will need to use the `transferFrom` method to conduct this transfer and the `me()` helper method to access the Principal id of the `NeuronLedger`.
* Create the new neuron by calling the `newNeuron` helper, using `null` for the `following` field. Make sure you place the correct elements into `ownersToNeuronIds` and `neuronIdsToNeurons` to store the result of this neuron creation, using `neuronCount` as the `NeuronId`. 
* Finally, ensure that you increment the `neuronCount` variable by 1 and the `totalLocked` by the number of tokens you just locked.

**`dissolveNeuron()`** allows the method caller to dissolve their neuron if the `dissolveDelay` has elapsed

* You must first check that the `msg.caller` has a neuron. Additionally, the neuron's `dissolveDelay` must have elapsed for the neuron to be dissolved. You can check this condition by comparing the `dissolveDelay` and `startingTime` attributes to the current `Time.now()` at which this method way called.
  * If either of these conditions don't hold, `assert(false)` to indicate an error.
* Once a neuron is dissolved, you must transfer the locked tokens plus the locking reward back to the user. 
  * Remember that you are transferring tokens from the current canister (`NeuronLedger`) to the caller's canister, which can be accomplished with the token's `.transfer()` function.
    * Note that the `transfer()` function returns a boolean indicating if the transfer was a success. If the transfer fails, you should return `assert(false)` to indicate an error.
  * The `calculateReward(neuron)` function is used to calculate the reward for holding a neuron, based on the elapsed `dissolveDelay`. For now, this reward is set to 0, but you can modify this function to create rewards as you see fit.
*  Dissolved neurons should be deleted from both `ownersToNeuronIds` and `neuronIdsToNeurons`, and `totalLocked` should be decreased by the number of `lockedTokens` in the neuron.

### Deploying

Take a look at the [Developer Quick Start Guide](https://sdk.dfinity.org/docs/quickstart/quickstart.html) if you'd like a quick refresher on how to run programs on a locally-deployed IC network. 

Follow these steps to deploy your canisters and launch the front end. If you run into any issues, reference the **Quick Start Guide**, linked above,  for a more in-depth walkthrough.

1.  Ensure that your dfx version matches the version shown in the `dfx.json` file by running the following command:

   ```
   dfx --version
   ```

   You should see something along the lines of:

   ```
   dfx 0.6.14
   ```

   If your dfx version doesn't match that of the `dfx.json` file, see the [this guide](https://sdk.dfinity.org/docs/developers-guide/install-upgrade-remove.html#install-version) for help in changing it. 

2. Open a second terminal window (so you can start and view network operations without conflicting with the management of your project) and navigate to the same `\governance` directory.

   In this new window, run:

   ```
   dfx start
   ```

3. Navigate back to your main terminal window (also in the `\governance` directory) and ensure that you have `node` modules available by running:

   ```
   npm install
   ```

4. Finally, execute:

   ```
   dfx deploy
   ```




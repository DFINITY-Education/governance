# Module 4: Voting and Following

In this module, students will build upon their work in Modules 2 and 3, adding the ability for neurons to vote on proposals and follow other neurons' voting patterns.

## Background

Once a proposal has been submitted on the IC, users can use their staked neurons to vote for/against it. Importantly, a user's **voting power** is influenced by neuron-specific factors such as the neuron's locked ICP, maturity, and dissolve delay. By voting on proposals, users receive **voting rewards** proportional to their voting power, incentivizing users to remain active participants in the system. See [this](https://medium.com/dfinity/understanding-the-internet-computers-network-nervous-system-neurons-and-icp-utility-tokens-730dab65cae8) Medium post for a detailed account of how voting rewards are calculated. 

However, many users don't have the time or expertise to review every single proposal on the NNS before voting. The solution: users can **follow** other neurons, like the [Internet Computer Association](https://internetcomputer.org/), and mirror their votes on the NNS. This enables users to designate trusted neurons to vote in their place, earning the same voting rewards as a normally-cast vote. 

## Your Task

### Specification

**Task:** Complete the implementation of `voteOnProposal()` and `followNeuron()` in `neuron.mo`.

**`voteOnProposal(governor: Principal, propNum: Nat, vote: Vote)`** instructs the caller's neuron to vote on the given proposal.

* First, ensure that the method caller has a neuron; if not, return `assert(false)` to indicate an error.
* A neuron cannot currently be following another neuron to call this method and vote manually. Check that the neuron isn't following another neuron; if it is, `assert(false)`.
* To invoke the governor actor and its related methods, you must first call `intoGovernorActor(governor)` and store the result in a variable. This variable is how you will invoke the Governor's methods.
* In particular, you'll need to call `.voteOnProposal()` to register this neuron's vote.
  * The `votingPower` you specify for this vote should be the sum of the neuron's `votingPower` field as well as the sum of the voting powers of its followers. We've implemented the helper `cascadeVotingPower()` to calculate this sum, which you'll need to invoke here.
  * Check that the `Result` of your call to `.voteOnProposal()` doesn't return an error; if it does, `assert(false)`

**`followNeuron(neuronIdToFollow: NeuronId)`** instructs the caller's neuron to follow `neuronIdToFollow`.

* First, ensure that the `neuronIdToFollow` exists; if not, `assert(false)`
* Next, check that the method caller has a neuron.
* Before following the new neuron, ensure that this doesn't create a **cycle** by invoking the helper `checkForCycles()`.
* Finally, create a new neuron (identical to the previous one, but now with the specified neuron to follow) by invoking the `newNeuron()` method and update the `neuronIdsToNeurons` hash map with this neuron.

### Deploying

Take a look at the [Developer Quick Start Guide](https://sdk.dfinity.org/docs/quickstart/quickstart.html) if you'd like a quick refresher on how to run programs on a locally-deployed IC network. 

Follow these steps to deploy your canisters and launch the front end. If you run into any issues, reference the **Quick Start Guide**, linked above,  for a more in-depth walkthrough.

1. Ensure that your dfx version matches the version shown in the `dfx.json` file by running the following command:

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



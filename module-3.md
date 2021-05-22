# Module 3: Proposal Creation

In this module, students will build upon their prior work from Module 2, adding the ability for users to create new proposals for application upgrades.

## Background

On the IC, modifications and network upgrades can only be implemented if they are approved by the NNS. How does this work? Well, users create **proposals** that specify exact code or state changes to the system, and then these proposals are voted on by users' neurons. Once a proposal passes a specified threshold of affirmative votes, it is passed and implemented by the NNS.

Proposals are organized into **proposal topics** that specify the type of upgrade being proposed. Topics include `#NeuronManagement`, `#NetworkEconomics`, `SubnetManagement`, etc.; to see a more in-depth list, visit the explanatory [Medium](https://medium.com/dfinity/understanding-the-internet-computers-network-nervous-system-neurons-and-icp-utility-tokens-730dab65cae8) post. These topics influence how the proposal is processed by the NNS. Additionally, users provide a brief text summary of their proposal as well as a URL linking to a more in-depth explanation.

In our implementation, we simplify this structure by forgoing topics and proposal summaries.

## Your Task

We have provided you with a complete `governor` actor, which acts as a proposal-management and upgrade system. Your task is to integrate this into our basic NNS, enabling users to create new proposals.

### Code Understanding

#### `governor.mo`

Let's begin by understanding the `governor.mo` canister that we've provided for you. This canister is based on one we implemented in Module 4 of the [Web Development](https://github.com/DFINITY-Education/web-development) course, with some slight modifications specific to neurons and voting power. Take a moment now to review the documentation of this canister [here](https://github.com/DFINITY-Education/web-development/blob/main/module-4.md).

Now, let's review the changes that we made to this canister. First, the `Governor` class now accepts a third parameter `neuronLedger`, which is the principal ID of the ledger we introduced in Module 2 to keep track of neurons (in `neuron.mo`). It's expected that the `neuronLedger` canister will be making all of the calls to public methods in `Governor`, so we've added `assert` statements to each method ensuring this is the case.

We've added a `neuron ` parameter to the `propose()`, `cancelProposal()`, and `voteOnProposal` methods, which specifies the id of the neuron making/canceling the proposal. Additionally, `voteOnProposal` also accepts a `votingPower` argument, which indicates the number of votes that the neuron has for their particular vote for/against the proposal. 

### Specification

**Task:** Complete the implementation of the `propose()` and `cancelProposal()` methods in `neuron.mo`.

**`propose(governor: Principal, newApp: Principal)`** instructs the method caller's neuron to create a new proposal.

* First, ensure that the caller has a neuron; if not, `assert(false)` to indicate an error.
* To invoke the governor actor and its related methods, you must first call `intoGovernorActor(governor)` and store the result in a variable. This variable is how you will invoke the Governor's methods.
* The `Governor`'s `propose()` method takes care of the logic for creating a new proposal; review the `propose()` method's code and then invoke it to register the new proposal.

**`cancelProposal(governor: Principal, propNum: Nat)`** instructs the method caller's neuron to cancel one of its active proposals.

* This method mirrors the `propose()` method's logic, but now you call the `Governor`'s `cancelProposal()` method instead of the `propose()` method.
  * As usual, `assert(false)` if an error occurs.

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






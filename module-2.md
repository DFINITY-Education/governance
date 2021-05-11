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

### 






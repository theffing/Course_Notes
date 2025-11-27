---
tags:
  - DeepLearning
---

#### Objectives
- Know the vanilla version of RNN
- Understand the different components and the working mechanisms of LSTM
- Know the learning problem on RNN and the strategies to solve the RNN learning problem

## Slot Filling
With Feed forward Network

Represent each worse as a vector, **1-of-N Encoding**
lexicon = {apple, bag, cat, dog, elephant}

The vector is lexicon size, each dimension corresponds to a word in the lexicon
The dimension for the word is 1, and others are 0
Ex. apple = [1 0 0 0 0]

The output of hidden layer is stored in memory.
Memory can be considered as another input.

## Elman Network
The output of the hidden unit will be saved in memory and will be used in the same layer for other neurons.
## Jordan Network
The output of the hidden unit will be saved in memory and will be used backwards?
## Bidirectional RNN

---
## Long Short-term Memory (LSTM)

![[Pasted image 20251127142024.png]]
![[Pasted image 20251127142045.png]]
#### Activation function f is usually a sigmoid function
---
Between 0 and 1
Mimics open and close gate


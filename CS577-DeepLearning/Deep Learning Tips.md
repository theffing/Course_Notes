---
tags:
  - DeepLearning
---

No good results on training data
- New Activation Functions
- Adaptive Learning Rate
## Vanishing Gradient Problem
- Small gradient with first few layers with last layers
- Smaller gradients learn very slow and almost random
- Larger gradients learn very fast and already converge
Because of backpropagation
The overall problem has to do with Sigmoid activation function

## ReLU - Function
Short for rectified linear unit
If input z larger than zero, the input is output, if the input is smaller than zero, the output is zero
1. Fast to compute
2. Biological reason
3. The infinite sigmoid with different biases
4. Solves Vanishing Gradient Problem
The gradient do not change in every layer

#### Training ReLU
remove neurons from network that produce 0 output according to ReLU function
Trim to a thinner linear network
Do not have smaller gradients
#### Leaky ReLU
ReLU - Variant
if z is smaller than 0, output will be 0.01z

#### Parametric ReLU
if z is smaller than 0, output will be output times z

## Maxout Network
ReLU is a special case of Maxout
Learnable activation function
![[Pasted image 20251119125501.png]]
![[Pasted image 20251119130154.png]]
Maxout Training ^

# Adaptive Learning Rate
## RMSProp
Root Mean Square of the gradients with previous gradients being decayed

Hard to find optimal network parameters
## Momentum
Movement of last step minus gradient at present

Momentum in gradient descent algorithms helps to achieve convergence in training

# Early Stopping and Regularization
## Early Stopping

![[Pasted image 20251119133507.png]]

## Regularization
New loss function to be minimized

Ex.
Find a set of weight not only minimizing original cost but also close to zero
![[Pasted image 20251119133612.png]]

git 



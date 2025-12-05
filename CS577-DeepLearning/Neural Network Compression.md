---
tags:
  - DeepLearning
---
## Model Compression
#### Model pruning
- Set individual parameters to zero and make the network sparse.
- Remove entire nodes from the network
#### Knowledge Distillation
- Transfer the knowledge from a large model or set of models to a single smaller model.
#### Quantization
- Reduce the precision of the weights, biases, and activations such that they consume less memory.
- Going from 32-bit to 8-bit, for example, would reduce the model size by a factor of 4, so one obvious benefit of quantization is a significant reduction in memory.
## Network Pruning
Importance of a weight
- absolute values, life long
Importance of a neuron
- the number of times it wasn't zero on a given data set
After pruning, the accuracy will drop
Fine-tuning on training data for recover
Don't prune too much at once, or the network won't recover
![[Pasted image 20251202163120.png]]
#### Knowledge Distillation
Providing the information that "1" is similar to "7", in the hand drawn digit example.
Cross-entropy minimization to reduce the loss between the Teacher Model and the Student Model
Ensemble, average of many models
#### Parameter Quantization
1. Using less bits to represent a value
2. Weight Clustering; average of all numbers in matrix sub-cluster
3. Represent frequent clusters by less bits, represent rare clusters by more bits; like Huffman Encoding
## Depthwise Separable Convolution
- Depthwise Convolution
	- Filter number = Input channel number
	- Each filter only considers one channel
	- The filters are $k * k$ matrices
	- There is no interaction between channels
- Pointwise Convolution
	- 4 1x1 filters in a 4x4 matrix, each filter goes through feature map
	- Creates new feature map for each filter
I: Number of input channels
O: number of output channels
$k*k$: kernel size
## Dynamic Computation
The networks adjusts the computation it need.
Prepare a set of models, containing one for each scenario.
#### Dynamic Depth
Extra Layer between layers when certain restrictions require dynamic usage of models.
#### Dynamic Depth

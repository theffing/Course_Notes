---
tags:
  - DeepLearning
---
#### Attention
Attention is a mechanism which intuitively mimics cognitive attentions. 

It calculates "soft" weights for each word, more precisely for its embedding, in the context window. These weights can be computed either in parallel (such as in transformers) or sequentially (such as recurrent neural networks).
#### Transformers
The transformer model is based on an encoder-decoder architecture. 

Both the encoder and decoder consist of two and three sub-layers, respectively: 
- multi-head self-attention
- a fully-connected feed forward network a
- in the case of the decoder -- encoder-decoder self-attention.
## Self-Attention
##### Sophisticated Input
Input is a vector
Output is a Scalar or Class

but Input can also be
A Set of Vectors -> into a Model
Output is then Scalars or Classes

##### Output
1. Each Vector has a label
2. The whole sequence has a label
3. Model decides the number of labels itself
#### Sequence Learning
FC can consider the neighbor, but how to consider the whole inputs?
A window cover the whole sequence?
![[Pasted image 20251201093058.png]]
![[Pasted image 20251201113951.png]]
![[Pasted image 20251201114029.png]]
---

#### Multi-head Self-attention

#### Self-attention for Speech
Speech is a very long vector sequence
If input sequence is length L
the **Attention Matrix** is L x L
#### Self-attention for Image
An image can also be viewed as a set of vectors.
##### Detection Transformer (DETR) A PAPER
Set of image features -> Encoder -> Decoder -> Prediction heads
#### Self-attention vs CNN
## Transformer
#### Sequence-to-Sequence
can be used for a chatbot to give responses
**Applications of Seq2Seq**
Most NLP applications
As long as transforming the task to QA

QA can be done by seq2seq,
- Syntactic Parsing
- Multi-label Classification
- Object Detection
An object can belong to multiple classes


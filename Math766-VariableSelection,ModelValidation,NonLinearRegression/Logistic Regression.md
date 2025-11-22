#### Regression Models with Binary Response Variable

i.e. Y = 0 or Y = 1: On or Off, Yes or No, TRUE OR FALSE

Response Output is dictated by X_i parameters

#### Constraints on Response Function
One predictor X
Instead of predicting Y=0 and Y=1, 
Model the probabilities that the response takes one of these two values.

#### Nonconstant Error Variance
Notice that Y is a Bernoulli random variable with the variance Y given by $\pi(1 - \pi)$ . But since
	$\pi = B_0 + B_1{x}$,
The variance of Y in this case is a function of x, hence the assumption of constant variance (**homoscedasticity**) does not hold.

Difficulties are created by unbounded linear functions:
i.e. $B_0 + B_1$

#### Dealing with Constraints on Response Function
##### The Logit Model
![[Pasted image 20251122143446.png]]
The logistic model we've seen above can be generalized easily to model with several predictive variables.

#### Odds
The ratio of number of "successful" events over the number of "failure" events
This is called the odds of the "successful" event (the event corresponding to Y=1).

The odds of drawing a white ball out a box of, 5 white balls, 2 yellow balls, and 6 red balls is:

> $\frac{Pr(Drawing a White Ball)}{1-Pr(Drawing a White Ball)} = \frac{5/13}{1- 5/13} = \frac{5}{8} = 0.625$

The odds are said to be 5:8. That is, on average the successful event will occur 5 times for every 8 times it does not.

## Logistic Regression in R

Simulated data set LR1.csv

	{Logistic Regression<-read.csv("LR1.CSV", header=TRUE, sep=",")
	x<-LogisticRegression$x
	y<-LogisticRegression$y
	plot(x,y)}

Run Logistic Regression in R

	model1<-glm(y-x, data=LR, family="binomial")
	summary(model1)






---
tags:
  - VariableSelection
---

#### Objectives
- Describe how we modified the ordinary least squares method to make the regression model more robust to the effect of outliers
- Use R to compute the robust regression parameters using different M-estimators
- Use R to perform model validations involving logistic regression

## Robustness
If the value of $x_n$ is large enough, then the average, $x$ can be made as large as possible regardless of the other $n-1$ values of $x_i$

Because of this, we say that the mean (average) is not a robust measure of central tendency.

## Least Squares Method
Outliers are heavily weighted. Bad data points can throw off the regression

## M-Estimation
M-estimation is a generalization of the ordinary least squares. M for Maximum

Instead of squaring the residuals, we will define a general function of the residuals. $H(\epsilon_i)$, and then minimize $S=\Sigma{H(\epsilon_i)}$

In order to perform the M-estimation
We will:
- guess the weight, $w_i$
- calculate the residuals, $\epsilon_i$
- use the previous residuals to calculate new weight
- repeat these processes until convergence

We want H to be non-negative, symmetric, monotonic, and have a continuous derivative, as well as $H(0) = 0$.
#### Huber M-Estimator
With a certain value of $k$, the function $H$ behave like the ordinary least square estimator, however, when we went beyond the value of $k$, then we will switch to using the absolute value of the residue (avoiding amplification effect of outliers).

Huber choose the value of $k=1.345\sigma$ that produce a 95% efficiency when the errors are normal, and still offer protection against outliers

#### Bisquare M-Estimator
The bisquare M-estimator in a sense is more robust than the Huber M-estimator. This is because when $|\epsilon| > k = 4.685\sigma$, the weighting becomes constant.
## Robust Regression
in R

	RobustRegression<-read.csv("RRobust1.csv", header=TRUE, sep=",")
	x<-RobustRegression$x
	y<-RobustRegression$y
	plot(x,y)

## Model Validations
Using R, perform Model Validations involving logistic regression


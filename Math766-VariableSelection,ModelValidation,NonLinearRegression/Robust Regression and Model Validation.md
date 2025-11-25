
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

We want H to be non-negative, symmetric, monotonic, and have a continuous derivative, as well as $H(0) = 0$.

## Robust Regression
---
tags:
  - VariableSelection
---

#### Objectives
- Poisson Regression vs Ordinary Linear Regression
- Obtaining Regression Parameters using the Maximum Likelihood method
- Use R to compute the Estimators of a Poisson Regression Model when presented with a dataset
- Interpret and Draw Conclusions from the R output of the Poisson Model
--

## Poisson Regression in R

	PoissonR<-read.csv("Poisson1.CSV", header=TRUE, sep=",")
	x<-PoissonR$x
	y<-PoissonR$y

	Model1<-glm(y-x, family-poisson)
	summary(Model1)

	Call:
	glm(formula = y - x, family = poisson)
#### Making a Prediction
use the 'predict' function

	newdata1 <- data.frame(x=c(0.01, 1.013, 1.21, 0.145))
	predict(Model1, newdata=newdata1, type="response")

## Generalized Linear Models
in R

	glm(formula, family, ...)

	binomial(link = "logit")

	gaussian(link = "indentity")

	gamma(link = "inverse")

	poisson(link = "log")

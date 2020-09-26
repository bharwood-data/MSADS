############# Libraries #############
library(changepoint)
library(BayesFactor)
library(BEST)
library(BaylorEdPsych)
library(mdscore)
library(tidyr)
library(MCMCpack)
library(car)
library(corrplot)
library(e1071)

############## General Prep and exploration ###############
corrplot(cor(districts[-c(1,7)]))
summary(districts)
districts1 <- districts

# Remove outliers in TotalSchools and Enrolled
hist(districts1$TotalSchools) 
districts1 <- districts1[districts1$TotalSchools < max(districts1$TotalSchools),]
hist(districts1$TotalSchools)

# Function to check skew levels of each numeric variable
skews <- function()
{
  skew <- c()
  for (i in colnames(districts1[c(2:6,8:13)]))
  {
    skew[i] <- skewness(districts1[[i]])
  }
  skew
}

skews()

# Transform variables as needed
for (i in c(2:5,8,11))
{
  districts1[[i]] <- sqrt(districts1[[i]])
}
skews()
districts1$PctUpToDate <- sqrt(100 - districts1$PctUpToDate)
skews()

hist(log(districts1$TotalSchools+9, base = 10))
districts1[,c(12,13)] <- log(districts1[,c(12,13)])
skews()

# Boolean variable not helpful for logistic regression, so make a factor type version, as well as numeric version
districts1$Complete <- factor(districts1$DistrictComplete, levels = c("FALSE","TRUE"))
districts1$NComplete <- as.numeric(districts1$Complete) - 1

############# Time series ###########
plot(usVaccines, main = "US Vaccination Rates")
plot(diff(usVaccines))

# This function will plot the cpt mean and cpt variation for the designated variable, as well as the acf
cptPlot <- function(df, var) 
{
  par(mfrow = c(3,1))
  plot(cpt.mean(df[[var]]), ylab = "Rate", main = "Change in Means")
  plot(cpt.var(diff(df[[var]])), ylab = "Rate", main = "Change in Variation")
  acf(diff(df[[var]]), main = "Autocorrelation")
  par(mfrow = c(1,1))
}
usDF <- data.frame(usVaccines)

# Loop through the different vaccines and produce the plots, as well as calculate standard deviation to measure volatility
for (i in c("DTP1", "HepB_BD", "Pol3", "Hib3", "MCV1"))
{
  cptPlot(usDF, i)
  print(paste(i,":",sd(usDF[[i]])))
}

# This function will produce the changepoint mean and variation for the designated data and variable
cpoints <- function(df, var)
{
  print(cpt.mean(df[[var]]))
  print(cpt.var(diff(df[[var]])))
}

# Pull the final row to measure highest and lowest vaccination rates at conclusion
usDF[nrow(usDF),]


################# Public/Private #############

# Make a table to count public and private schools that reported and determine ratios
reportTable <- table(allSchoolsReportStatus$pubpriv, allSchoolsReportStatus$reported)
pubReport <- reportTable[4]/sum(reportTable[2], reportTable[4])
privReport <- reportTable[3]/sum(reportTable[1], reportTable[3])
pubReport
privReport

# Traditional chi-square to check for difference
chisq.test(reportTable)

# Bayesian
BFtable <- contingencyTableBF(reportTable, sampleType = "poisson", posterior = FALSE)
BFtable
MCMCtable <-contingencyTableBF(reportTable, sampleType = "poission", posterior = TRUE, iterations = 10000)
summary(MCMCtable)
noProp <- MCMCtable[,"pi[1,1]"]/MCMCtable[,"pi[2,1]"]
hist(noProp, main = "", xlab = "Ratio")
yesProp <- MCMCtable[,"pi[1,2]"]/MCMCtable[,"pi[2,2]"]
hist(yesProp, main = "", xlab = "Ratio")
diffProp <- noProp - yesProp
hist(diffProp, main = "", xlab = "Ratio")
abline(v = quantile(diffProp, c(0.025)), col = "black")
abline(v = quantile(diffProp, c(0.975)), col = "black")
abline(v = mean(diffProp), col = "red")

################# US Rates ################
usVaccines[nrow(usVaccines),]

# Quickly calulate the average vaccination rate for each vaccine (note: can't average averages)
for (i in seq(2,5)) {
  ca2013[i] <- sum((100-districts1[i])*districts1$Enrolled/100)/sum(districts1$Enrolled)
}
# Add national rates in 2013
rates <- rbind(usDF[nrow(usDF),c(1,3,5,2)]/100, ca2013)
row.names(rates) <- c("US", "CA")
# Compare district to national
compRates <- rates[2,]/rates[1,]
row.names(compRates) <- "CA/US"
compRates
rates
################ Vaccination rates between districts ####################

# Need to conduct t-tests between each district. Loop through them and perform each test and report the results.
for (i in c(2,3,4))
{
  for (j in seq(i+1,5))
  {
    p <- t.test(districts1[i], districts1[j])$p.value
    t <- t.test(districts1[i], districts1[j])$statistic
    df <- t.test(districts1[i], districts1[j])$parameter
    if (p < 0.05)
    {
      print(paste("T-test for", names(districts1[i]),"and", names(districts1[j]),"is significant, with t=",t,"df=",df,"and p=", p))
    }
    else
    {
      print(paste("T-test for", names(districts1[i]),"and", names(districts1[j]),"is NOT significant, with t=",t,"df=",df,"and p=", p))
    }
  }
}

# See if HepB can be predicted by the demographic variables
M <- lm(WithoutHepB ~ PctChildPoverty +PctFreeMeal + PctFamilyPoverty + Enrolled + TotalSchools, data = districts1)
summary(M)
M1 <- lm(WithoutHepB ~ PctFreeMeal + PctFamilyPoverty + Enrolled, data = districts1)
summary(M1)
vif(M1)

############### Predicting complete reporting ####################

# Logistic regression to check if the combination of demographic variables can predict complete reporting
out <- glm(Complete ~ PctChildPoverty +PctFreeMeal + PctFamilyPoverty + Enrolled + TotalSchools, data = districts1, family = "binomial")
summary(out)
anova(out, test = "Chisq")

# Check predictive capability of each demographic variable. This produces boxplots and HDIs, and creates a data frame to view all relevant results at the same time.

par(mfrow = c(1,2))
p <- c()
chi <- c()
a <- c()
cbot <- c()
ctop <- c()
pr2 <- c()
acc <- c()
bbot <- c()
btop <- c()
bmean <- c()
for (i in seq(9,13))
{
  var <- colnames(districts1[i])
  boxplot(districts1[[i]] ~ districts1$Complete, xlab = "Complete", ylab = var, main = paste("Distribution of Completion by",var))
  out <- glm(districts1$Complete ~ districts1[[i]], family = "binomial")
  print(summary(out))
  p[i-8] <- wald.test(out, 2)$pvalue # <- significance of Wald z
  atest <- anova(out, test = "Chisq") 
  chi[i-8] <- atest$Deviance[2] # <- chi-square value from anova
  a[i-8] <- atest$`Pr(>Chi)`[2] # <- chi-square significance
  cf <- exp(confint(out)) 
  cbot[i-8] <- cf[2] # <- lower bound of confidence interval
  ctop[i-8] <- cf[4] # <- upper bound of confidence interval
  pr <- PseudoR2(out)
  pr2[i-8] <- pr[1] # <- MacFadden R^2
  t <- table(round(predict(out, type= "response")), districts1$Complete)
  acc[i-8] <- t[2]/sum(t) # <- accuracy
  bayesout <- MCMClogit(formula = NComplete ~ districts1[[i]], data = districts1)
  s <- summary(bayesout)
  bbot[i-8] <- exp(s$quantiles[2]) # <- lower bound for HDI
  btop[i-8] <- exp(s$quantiles[10]) # M- upper bound for HDI
  bmean[i-8] <- exp(s$statistics[2]) 
  logOdds <- as.matrix(bayesout[,2])
  odds <- apply(logOdds, 1, exp)
  hist(odds)
  abline(v = quantile(odds, c(0.025)), col = "black")
  abline(v = quantile(odds, c(0.975)), col = "black")
  abline(v = bmean[i-8], col = "red")
}
acc <- replace_na(acc, 1)
par(mfrow = c(1,1))

glms <- data.frame(c("PctChildPoverty", "PctFreeMeal", "PctFamilyPoverty", "Enrolled", "TotalSchools"),
                   p, chi, a, cbot, ctop, pr2, acc, bbot, btop, bmean)
colnames(glms) <- c("Predictor", "Significance", "Chi", "Anova", "ConfIntL", "ConfIntU", "MacFadden", "Accuracy", "HDILower", "HDIUpper", "MeanOdds")

View(glms)
#################### Predicting up-to-date vaccines ######################

m <- lm(PctUpToDate ~ PctChildPoverty +PctFreeMeal + PctFamilyPoverty + Enrolled + TotalSchools, data = districts1) 
vif(m)
summary(m)
m1 <- lm(PctUpToDate ~ PctFreeMeal + +PctFamilyPoverty + TotalSchools + Enrolled, data = districts1)
summary(m1)

bayesLM <- lmBF(PctUpToDate ~ PctFreeMeal + PctFamilyPoverty + TotalSchools + Enrolled, data = districts1, posterior = TRUE, iterations = 10000)
summary(round(bayesLM,2))
colors <- c("royalblue", "orange", "purple", "dark green")
vars <- c("PctFreeMeal", "PctFamilyPoverty", "TotalSchools", "Enrolled")
par(mfrow = c(2,2))
for (i in c(2:5))
{
  hist(bayesLM[,i], 
       main = "Bayesian Variance Estimate Histogram", 
       xlab = vars[i-1], 
       #xlim = c(-0.03,0.005),
       breaks = 50,
       col = colors[i-1])
  abline(v = quantile(bayesLM[,i],c(0.025)), col = "black", lwd = 2)
  abline(v = quantile(bayesLM[,i],c(0.9785)), col = "black", lwd = 2)  
}
par(mfrow = c(1,1))
lmBF <- lmBF(PctUpToDate ~ PctFreeMeal + PctFamilyPoverty + Enrolled + TotalSchools, data = districts1)
lmBF

#################### Predicting Relgious Belief Exception #########################
boxplot(districts$PctBeliefExempt)
m <- lm(PctBeliefExempt ~ PctChildPoverty +PctFreeMeal + PctFamilyPoverty + Enrolled + TotalSchools, data = districts1) 
summary(m)
m1 <- lm(PctBeliefExempt ~ PctFreeMeal + PctFamilyPoverty + Enrolled + TotalSchools, data = districts1) 
vif(m1)
summary(m1)
m2 <- lm(PctBeliefExempt ~ PctFreeMeal + Enrolled + TotalSchools, data = districts1) 
vif(m2)
summary(m2)
m3 <- lm(PctBeliefExempt ~ PctFreeMeal + Enrolled, data = districts1) 
vif(m3)
summary(m3)
bayesLM2 <- lmBF(PctBeliefExempt ~ PctFreeMeal + Enrolled, data = districts1, posterior = TRUE, iterations = 10000)
summary(round(bayesLM2,2))
colors <- c("blue", "red")
vars <- c("PctFreeMeal", "Enrolled")
par(mfrow = c(1,2))
for (i in c(2,3))
{
  hist(bayesLM[,i], 
       main = "Bayesian Variance Estimate Histogram", 
       xlab = vars[i-1], 
       #xlim = c(-0.03,0.005),n
       breaks = 50,
       col = colors[i-1])
  abline(v = quantile(bayesLM[,i],c(0.025)), col = "black", lwd = 2)
  abline(v = quantile(bayesLM[,i],c(0.9785)), col = "black", lwd = 2)  
}
par(mfrow = c(1,1))
lmBF2 <- lmBF(PctBeliefExempt ~ PctFreeMeal + Enrolled, data = districts1)
lmBF2



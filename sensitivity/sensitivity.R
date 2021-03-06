###--------------------------------------------------------------------------###
### Author: Arman Oganisian
### Conduct Sensitivity Analysis for non-ignorabile treatment effect under 
##$  linear model.
###--------------------------------------------------------------------------###

## Load Packages
library(rstan)
library(LaplacesDemon)
library(latex2exp)
set.seed(1)

####------------------------ Simulate Data ---------------------------------####
N = 100 # sample size
warmup = 500
iter = 1000
n_draws = iter - warmup


L = rnorm(N) 
U = rnorm(N)
A = rbern(N, prob = invlogit( 0 + 1*L + 1*U ) )
Y = rnorm(N, mean = 0 + 1*A - 1*L -2*U  , sd = 1 )

# P=2 dimensions of model matrix
X = model.matrix( ~ 1 + A + L )

stan_data = list(Y=Y, L=L, A = A, N=N)

####------------------------ Sample Posterior    ---------------------------####
sa_model = stan_model(file = "sensitivity.stan")

stan_res = sampling(sa_model, data = stan_data, 
                    warmup = warmup, iter = iter, chains=1, seed=1)

post_draws = extract(stan_res, pars=c('theta','psi3','psi2','psi1'))
post_draws = do.call('cbind', post_draws)

####-------------------         Plot Results            --------------------####

png("sensitivity.png")

spars = c('$\\Delta \\sim \\delta_0 $', 
          '$\\Delta \\sim N(0, 3^{-1/2} )$', 
          '$\\Delta \\sim Gam(1,3)$',
          '$\\Delta^* \\sim Gam(1,3)$' )

plot(colMeans(post_draws),
     col='blue', pch=20, ylab=TeX("$\\Psi_s$"),axes=F, 
     ylim=c(-2,2), xlab='Sensitivity Parameter Prior')

axis(side = 1, 1:4, labels = TeX(spars),tick = T, padj = .5)
axis(side = 2, seq(-2,2,1), labels = seq(-2,2,1), tick = T)

### Plot posterior credible Band
colfunc <- colorRampPalette(c("white", "skyblue"))
ci_perc = seq(.99,.01,-.01)
colvec = colfunc(length(ci_perc))
names(colvec) = ci_perc

for(i in ci_perc){
  pci = apply(post_draws, 2, quantile, probs=c( (1-i)/2, (1+i)/2  ) )
  segments(1:4, pci[1,], 1:4, pci[2,], col=colvec[as.character(i)], lwd=10 )
}
###

points(1:4, colMeans(post_draws), col='steelblue', pch=20, lwd=10)
abline(h=1, col='red', lty=2)

dev.off()
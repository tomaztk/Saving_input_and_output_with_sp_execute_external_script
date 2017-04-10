load(file="C:\\DataTK\\logRSQLsession3.rda")
c


setwd("C:\\DataTK")
Rprof(filename = "000_dataTK_Rprof.out", append = TRUE, interval = 0.02)

re<- 2
r <- 1
r2 <- re + r
r2

library(MASS)
lm_seq <- seq(0,10,0.01)
lm_seq
Rprof(NULL)



setwd("C:\\DataTK")
savehistory(file = "000_dataTK.Rhistory")

re<- 2
r <- 1
r2 <- re + r
r2
lm_seq <- seq(0,10,0.01)
lm_seq


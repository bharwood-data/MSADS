#############################
#                           #
# Author: Ben Harwood       #
# IST 719 Final Poster code #
#                           #
#############################


########## Packages ##########

library(httr)
library(lattice)
library(dplyr)
library(ggplot2)
library(ggpubr)
library(packcircles)

########## Various vectors that will be needed for colors and identifers ##########

class_colors <- c("#C41F3B", "#A330C9", "#FF7D0A", "#A9D271", "#40C7EB", "#00FF96", "#F58CBA", "#FFFFFF", "#FFF569", "#0070DE", "#8787ED", "#C79C6E")
classes <- c("death-knight", "demon-hunter", "druid", "hunter", "mage", "monk", "paladin", "priest", "rogue", "shaman", "warlock", "warrior")
Class <- c("DK", "DH", "Druid", "Hunter", "Mage", "Monk", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "warrior")
class <- data.frame(classes, Class, class_colors)
tank.colors <- c("#C41F3B", "#A330C9", "#FF7D0A", "#00FF96", "#F58CBA", "#C79C6E")
heal.colors <- c("#FF7D0A", "#00FF96", "#F58CBA", "#FFFFFF", "#0070DE")
tanks <- c("death-knight", "demon-hunter", "druid", "monk", "paladin", "warrior")
healers <- c("druid", "monk", "paladin", "priest", "shaman")

########## Data extraction from Raider.io API ##########

## This function pulls the data from raier.io ##

season_data <- function(region, patch, instance)
{
  df <- c()
  for (j in 0:4)
  {
    url <- paste("https://raider.io/api/v1/mythic-plus/runs?season=season-",patch,"&region=",region,"&dungeon=",instance,"&page=",j, sep="")
    resp <- GET(url)
    data <- content(resp)
    season <- c()
    runID <- c()
    score <- c()
    rank <- c()
    dungeon<-c()
    level<-c()
    clear_time <- c()
    remaining_time <- c()
    date <- c()
    affix1 <- c()
    affix2 <- c()
    affix3 <- c()
    affix4 <- c()
    class <- c()
    role <- c()
    cap <- length(data$rankings)*5
    for (i in 1:cap)
    {
      if (length(data$rankings[[ceiling(i/5)]]$run$roster) == 5){
        rank[i] <- data$rankings[[ceiling(i/5)]]$rank
        season[i] <- data$rankings[[ceiling(i/5)]]$run$season
        runID[i] <- data$rankings[[ceiling(i/5)]]$run$keystone_run_id
        score[i] <- data$rankings[[ceiling(i/5)]]$score
        dungeon[i] <- data$rankings[[ceiling(i/5)]]$run$dungeon$slug
        level[i] <- data$rankings[[ceiling(i/5)]]$run$mythic_level
        clear_time[i] <- data$rankings[[ceiling(i/5)]]$run$clear_time_ms
        remaining_time[i] <- data$rankings[[ceiling(i/5)]]$run$time_remaining_ms
        date[i] <- substr(data$rankings[[ceiling(i/5)]]$run$completed_at, 1, 10)
        affix1[i] <- data$rankings[[ceiling(i/5)]]$run$weekly_modifiers[[1]]$name
        affix2[i] <- data$rankings[[ceiling(i/5)]]$run$weekly_modifiers[[2]]$name
        affix3[i] <- data$rankings[[ceiling(i/5)]]$run$weekly_modifiers[[3]]$name
        affix4[i] <- ifelse (data$rankings[[ceiling(i/5)]]$run$num_modifiers_active == 4, data$rankings[[ceiling(i/5)]]$run$weekly_modifiers[[4]]$name, "none")
        class[i] <- data$rankings[[ceiling(i/5)]]$run$roster[[i%%5+1]]$character$class$slug
        role[i] <- data$rankings[[ceiling(i/5)]]$run$roster[[i%%5+1]]$role
      }
    }
    
    temp_df <- data.frame(rank, score, season, runID, dungeon, level, clear_time, remaining_time, date, affix1, affix2, affix3, affix4, class, role)
    df <- rbind(df, temp_df) 
  }
  df <- df[rowSums(is.na(df)) != ncol(df),]
  return(df)
}

## This function uses the previous function to pull data for a specific dungeon
## this is needed because Mechagon Junkyard and Workshop were not in the game
## until season 4 so must be captured seperately

dungeon_data <- function(region, xpac, instance)
{
  dungeon <- c()
  if (xpac == "BFA")
  {
    for (s in 1:4)
    {
      season <- paste0("bfa-",s)
      dung <- season_data(region, season, instance)
      dungeon <- rbind(dungeon, dung)
    }
    return(dungeon)
  }
}

## This function calls the previous function to pull the top 100 runs per dungeon, per season
## from raider.io

bfa.data <- function()
    {
      df <- c()
      for (d in c("ataldazar","freehold","the-underrot","kings-rest", "shrine-of-the-storm","siege-of-boralus","temple-of-sethraliss","the-motherlode","tol-dagor","waycrest-manor"))
      {
        temp <- dungeon_data("us","BFA", d)
        df <- rbind(df, temp)
      }
      for (d in c("operation-mechagon-junkyard","operation-mechagon-workshop"))
      {
        temp <- season_data("us", "bfa-4", d)
        df <- rbind(df, temp)
      }
      return(df)
    }

## Pulling the actual data
## There should be 21,000 rows in this data frame. Sometimes it doesn't pull everything due to 
## API pull request limitations. If it does not, just re-run it.

bfa <- bfa.data() 
bfa$class <- as.character(bfa$class)

########## Classes by Dungeon ##########

bfa.settings <- list(superpose.polygon = list(col = class_colors))
bfaT <- table(Class = bfa$class, Dungeon = bfa$dungeon)
barchart(sqrt(bfaT)
         , stack = FALSE
         , groups = FALSE
         , horizontal = FALSE
         , auto.key = list(space = "top", columns = 3, title = "Class", cex.title = 1, text = c("Death Knight","Demon Hunter", "Druid", "Hunter", "Mage", "Monk", "Paladin","Priest", "Rogue", "Shaman", "Warlock", "Warrior"))
         , layout = c(4,3)
         , index.con = list(c(9,11,10,12,5,6,7,8,1,2,3,4))
         , strip = strip.custom(factor.levels = c("Atal'Dazar", "Freehold","King's Rest", "Mechagon Junkyard", "Mechagon Workshop", "The Motherlode", "Shrine of the Storm", "Siege of Boralus", "Temple of Sethraliss", "The Underrot", "Tol Dagor", "Waycrest Manor"))  
         , par.settings = bfa.settings
         , col = class_colors
         , main = "BFA Overall Class Distribution by Dungeon"
         , scales = list(x = list(draw = FALSE))
         , ylab = "Frequency"
         , xlab = ""
         , between = list(x=1, y=1)
         , labels = TRUE)

########## Total class distribution ##########

barplot(table(bfa$class)
        , col = class_colors
        , xlab = "Frequency"
        , main = "Class Distribution"
        , horiz = TRUE)
legend("bottomright", legend = classes, box.col = "transparent", fill = bfa.colors)

########## Cleartime Histograms - ultimately unused ##########

histogram(~clear_time/1000 | dungeon
          , groups = FALSE
          , horizontal = FALSE
          , data = bfa
          , layout = c(4,3)
          , index.con = list(c(9,11,10,12,5,6,7,8,1,2,3,4))
          , strip = strip.custom(factor.levels = c("Atal'Dazar", "Freehold","King's Rest", "Mechagon Junkyard", "Mechagon Workshop", "The Motherlode", "Shrine of the Storm", "Siege of Boralus", "Temple of Sethraliss", "The Underrot", "Tol Dagor", "Waycrest Manor"))  
          , main = "Clear Time Distribution by Dungeon (in seconds)"
          #, scales = list(x = list(draw = FALSE))#, y = list(draw = FALSE))
          , ylab = "Frequency"
          , xlab = ""
          , between = list(x=1, y=1)
          , labels = TRUE)

########## Class combinations and role frequency ##########
          
## This function aggregates the previous data frame into individual runs, instead of players
## It creates 5 columns for each role in the run, allowing us to compare class combinations more
## effectively.

bfaruns <- function()
{
  df <- c()
  names <- c("dps1", "dps2", "dps3", "healer", "tank")
  dungeons <- c("ataldazar","freehold","the-underrot","kings-rest", "operation-mechagon-junkyard", 
                  "operation-mechagon-workshop", "shrine-of-the-storm","siege-of-boralus",
                  "temple-of-sethraliss","the-motherlode","tol-dagor","waycrest-manor")
  s13dungeons <- c("ataldazar","freehold","the-underrot","kings-rest", "shrine-of-the-storm","siege-of-boralus",
                   "temple-of-sethraliss","the-motherlode","tol-dagor","waycrest-manor")
  for (s in 1:4)
  {
    if (s != 4)
    {
      for (d in s13dungeons)   
      {
        for(i in 1:100)
          {
            df1 <- bfa[which(bfa$season == paste0("season-bfa-",s) & bfa$rank == i & bfa$dungeon == d),]
            df1rank <- df1[1,1:12]
            df1class <- df1$class[order(df1$role)]
            df1class <- as.character(df1class)
            df1class <- t(df1class)
            colnames(df1class) <- names
            df1rank <- cbind(df1rank, df1class)
            df <- rbind(df, df1rank)
          }
      }
    }
    else
    {
      for (d in dungeons)
      {
        for(i in 1:100)
        {
          df1 <- bfa[which(bfa$season == paste0("season-bfa-",s) & bfa$rank == i & bfa$dungeon == d),]
          df1rank <- df1[1,1:12]
          df1class <- df1$class[order(df1$role)]
          df1class <- as.character(df1class)
          df1class <- t(df1class)
          colnames(df1class) <- names
          df1rank <- cbind(df1rank, df1class)
          df <- rbind(df, df1rank)
        }
      }  
    }
  }  
  return(df)
}

BFA <- bfaruns()
BFA <- BFA[which(BFA$tank %in% tanks),]
BFA <- BFA[which(BFA$healer %in% healers),]
BFA[,13:17] <- as.character(BFA[,13:17])

## The following data frames allow us to look specifically at the class representation
## for tanks, healers, and dps by season

BFAT <- data.frame(table(Class = BFA$tank, Season = BFA$season))
for (s in c("season-bfa-1", "season-bfa-2", "season-bfa-3", "season-bfa-4"))
{
  runs <- length(BFA[BFA$season == s,1])
  BFAT$Freq[BFAT$Season == s] <- BFAT$Freq[BFAT$Season == s]/runs
}

ggplot(as.data.frame(BFAT), aes(Season, Freq, color = Class)) +
  geom_point(size = 5, color = c(rep(tank.colors, 4))) +
  geom_line(aes(group = Class)) +
  scale_color_manual(values = tank.colors)
theme_bw()

BFAH <- data.frame(table(Class = BFA$healer, Season = BFA$season))
for (s in c("season-bfa-1", "season-bfa-2", "season-bfa-3", "season-bfa-4"))
{
  runs <- length(BFA[BFA$season == s,1])
  BFAH$Freq[BFAH$Season == s] <- BFAH$Freq[BFAH$Season == s]/runs
}

ggplot(as.data.frame(BFAH), aes(Season, Freq, color = Class)) +
  geom_point(size = 5, color = c(rep(heal.colors, 4))) +
  geom_line(aes(group = Class)) +
  scale_color_manual(values = heal.colors) +
  theme_bw()

dps <- bfa[which(bfa$role == "dps"),]
dpsT <- data.frame(table(Class = dps$class, Season = dps$season))
for (s in c("season-bfa-1", "season-bfa-2", "season-bfa-3", "season-bfa-4"))
{
  runs <- length(dps$rank[dps$season == s])
  dpsT$Freq[dpsT$Season == s] <- dpsT$Freq[dpsT$Season == s]/runs
}

ggplot(dpsT, aes(Season, Freq, color = Class)) +
  geom_point(size = 5, color = c(rep(bfa.colors, 4))) +
  geom_line(aes(group = Class)) +
  facet_wrap(~Class, scales = "free", ncol = 4) +
  scale_color_manual(values = bfa.colors) +
  ylim(0,0.6) +
  theme_bw()

## Finally, plots showing tank/healer combination frequency and dps combination frequency.

barplot(sqrt(table(BFA$healer, BFA$tank))
        , beside = TRUE
        , col = heal.colors
        , names.arg = c("Death Knight", "Demon Hunter", "Druid", "Monk", "Paladin", "Warrior")
        , xlab = "Tank"
        , main = "Healer/Tank Combination Utilization"
)
legend("topright", legend = healers, box.col = "transparent", fill = heal.colors)

dps1 <- BFA[,13:15]
perms <- combn(classes,3)
perms <- as.data.frame(t(perms))
counts <- c(rep(0, nrow(perms)))
for (i in 1:220)
  {
  for (j in 1:4198)
    {
      t <- dps1[j,1] %in% perms[i,] & dps1[j,2] %in% perms[i,] & dps1[j,3] %in% perms[i,]
      if (t == TRUE)
      {
        counts[i] <-  counts[i] +1
      }
    }  
  }
perms$freq <- counts
perms$code <- paste0(perms$V1, "/", perms$V2, "/", perms$V3)
perms <- perms[order(-perms$freq),]
perms <- head(perms,20)
perms$V1 <- as.character(perms$V1)
perms$V2 <- as.character(perms$V2)
perms$V3 <- as.character(perms$V3)

packing <- circleProgressiveLayout(perms$freq, sizetype = "area")
perms <- cbind(perms, packing)
dat.gg <- circleLayoutVertices(packing, npoints= 50)

ggplot() +
  geom_polygon(data = dat.gg, aes(x, y, group = id, fill=as.factor(id)), color = "black", alpha = 0.6) +
  geom_text(data = perms, aes(x, y, label = freq))+
  scale_size_continuous(range = c(1,4)) +
  theme_void() +
  theme(legend.position = "none") +
  coord_equal() +
  ggtitle("20 Most Frequent DPS Class Combinations")
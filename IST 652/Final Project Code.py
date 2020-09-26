##########################
#                        #
# IST 652 Final Project  #
# Ben Harwood            #
# Version: Final         #
# 08/27/2020             #
#                        #
##########################           

import pandas as pd
import numpy as np
import nltk
import csv
import random
import re
import statistics
import matplotlib.pyplot as plt
import statsmodels.api as sm
from wordcloud import WordCloud, ImageColorGenerator
from PIL import Image
from nltk.corpus import PlaintextCorpusReader
from nltk.tokenize import sent_tokenize
from nltk.collocations import BigramCollocationFinder
from nltk.collocations import TrigramCollocationFinder
from nltk import FreqDist
from nltk import tokenize
from nltk.sentiment.vader import SentimentIntensityAnalyzer
from scipy.stats import chi2_contingency
#nltk.download('vader_lexicon')
#nltk.download('punkt')

###### Preliminary setup of some things to be used throughout ###########
nltkstopwords = nltk.corpus.stopwords.words('english')
morestopwords = ['could', 'would', 'might', 'must', 'need', 'sha', 'wo', 'y', "'s", "'d", "'ll","'t","'m","'re","'ve","n't", "us", "every", "let", "know", "also", "see", "say", "get", "vermont", "arizona", "connecticut", "illinois", "kentucky", "louisiana", "maine", "massachusetts", "michigan", "hampshire"]
bigram_measures = nltk.collocations.BigramAssocMeasures()
trigram_measures = nltk.collocations.TrigramAssocMeasures()
stopwords = nltkstopwords + morestopwords
pattern = re.compile('^[^a-z]+$')
nonAlphaMatch = pattern.match('**')
if nonAlphaMatch: print('matched non-alphabetical')
def alpha_filter(w):
    pattern = re.compile('^[^a-z]+$')
    if (pattern.match(w)):
        return True
    else:
        return False 

############# Loading, processing, and bigrams for speeches ###########

root = "E:/Documents/IST 652/Final Project/Speeches"
corpus = PlaintextCorpusReader(root, ["AL.txt", "CA.txt", "CT.txt", "DE.txt","FL.txt","GA.txt",\
    "HI.txt","IA.txt","ID.txt","IL.txt","IN.txt","KS.txt","LA.txt","MA.txt","MD.txt","ME.txt",\
        "MI.txt","MN.txt","MO.txt","MS.txt","NE.txt","NJ.txt","NM.txt","NY.txt","OH.txt","OK.txt",\
            "PA.txt","RI.txt","SC.txt","SD.txt","TN.txt","VA.txt","VT.txt","WA.txt","WV.txt","AZ.txt"])

states = ["AL","CA","CT","DE","FL","GA","HI","IA","ID","IL","IN","KS","LA","MA","MD","ME","MI","MN",\
    	"MO","MS","NE","NJ","NM","NY","OH","OK","PA","RI","SC","SD","TN","VA","VT","WA","WV","AZ"]

# Creation of a list of the sentences, tokenized into words
Sents = []
for i in range(10):
    temp = corpus.fileids()[i]
    temptext = corpus.raw(temp)
    tempTokens = nltk.word_tokenize(temptext)
    Sents = Sents + tempTokens

# Making all tokens lowercase and removing non alphabetic tokens
words = [w.lower() for w in Sents]
AlphaWords = [w for w in words if not alpha_filter(w)]
StoppedWords = [w for w in AlphaWords if not w in stopwords]

print("The governors used", len(AlphaWords), "total (and", len(np.unique(np.array(AlphaWords))),"unique) words in their speeches,", round((1-len(StoppedWords)/len(AlphaWords))*100,2), "percent of which were stop words.")

def wordcloud_draw(data, color = "black", width=1000, height=750, max_font_size=50, max_words = 100):
    words = " ".join([w for w in data])
    wordcloud = WordCloud(stopwords = stopwords, background_color=color, width=width,height=height,max_font_size=max_font_size, max_words=max_words).generate(words)
    plt.figure(1,figsize=(10.5,7))
    plt.imshow(wordcloud, interpolation="bilinear")
    plt.axis("off")
    plt.show()

wordcloud_draw(AlphaWords, color="white", max_words = 300)

# Bigrams and Trigrams
finder = BigramCollocationFinder.from_words(words)
finderT = TrigramCollocationFinder.from_words(words)
Scored = finder.score_ngrams(bigram_measures.raw_freq)
ScoredT = finderT.score_ngrams(trigram_measures.raw_freq)
for score in Scored[:50]:
    print(score)
finder.apply_word_filter(alpha_filter)
finderT.apply_word_filter(alpha_filter)
Scored = finder.score_ngrams(bigram_measures.raw_freq)
ScoredT = finderT.score_ngrams(trigram_measures.raw_freq)
for score in Scored[:50]:
    print(score)
finder.apply_word_filter(lambda w: w in stopwords)
finderT.apply_word_filter(lambda w: w in stopwords)
Scored = finder.score_ngrams(bigram_measures.raw_freq)
ScoredT = finderT.score_ngrams(trigram_measures.raw_freq)
for score in Scored[:50]:
    print(score)
for score in ScoredT[:50]:
    print(score)    

dist = FreqDist(StoppedWords)
items = dist.most_common(50)
print(items)

# This code created syntax to use in Latex for creation of a table
# for i in range(50):
#   print(items[i][0],"\t & \t",items[i][1], "\t & \t", Scored[i][0], "\t &\t", round(Scored[i][1],4), "\\\\")

# List of states and their associated speeches
speeches = []
for i in range(len(states)):
    temp = corpus.fileids()[i]
    temptext = corpus.raw(temp)
    tempsent = sent_tokenize(temptext)
    speeches.append([states[i], temptext]) 

# Make the list a dataframe
speech_df = pd.DataFrame(speeches)
speech_df.columns = ["State", "Text"]
analyzer = SentimentIntensityAnalyzer()

# Sentiment scoring function
def score_text(text):
    sentence_list = tokenize.sent_tokenize(text)
    cscore = 0.0
    for sent in sentence_list:
        ss = analyzer.polarity_scores(sent)['compound']
        cscore += ss
    return cscore / len(sentence_list)

# Determine sentiment of each speech and add to dataframe
speech_df["Sentiment"] = speech_df.Text.map(lambda t : score_text(t))

# Histogram of sentiments
hist = speech_df["Sentiment"].hist(bins = 12)


# Examination of the sentiment scores
# speech_df["Sentiment"]
speech_list = speech_df.values.tolist()
min_sent = min(speech_df["Sentiment"])
max_sent = max(speech_df["Sentiment"])
avg_sent = statistics.mean(speech_df["Sentiment"]) # average sentiment
for i in range(len(states)):
    if speech_list[i][2] == max_sent:
        top_state = speech_list[i][0]
    elif speech_list[i][2] == min_sent:
        bot_state = speech_list[i][0]
neg_states = []
for i in range(len(states)):
    if speech_list[i][2] < 0:
        neg_states.append(speech_list[i][0])

print("The state with the most positive speech was",top_state,"at {:.2%}".format(max_sent), "and the state with the least positive speech was", bot_state, "at {:.2%}".format(min_sent))
print("The average speech sentiment was {:.2%}".format(avg_sent))
print("The following states had negative speechs scores:",neg_states)
######################## Election data #########################

# Read the csv and convert to pandas dataframe
elections = pd.read_csv("e:/documents/ist 652/final project/usa-2016-presidential-election-by-county.csv", delimiter=";")
elections_df = pd.DataFrame(elections)

# Quick exploration
# elections.head()
# elections.info()
# elections_df.State.unique()

# This function allows the user to enter a state abbreviation and returns the number of counties, and the same information as above in one nice, neat statement
def DemRep_state():
    check = "Y"
    while check == "Y":
        state = input("Enter the abbreviation for the state you wish to examine for democrats (in caps, please):")
        if state in elections_df["ST"].values:
            is_key = elections_df["ST"] == state
            df = elections_df[is_key]
            DemRep12 = df[df["Democrats 12 (Votes)"] > df["Republicans 12 (Votes)"]]
            DemRep16 = df[df["Votes16 Clintonh"] > df["Votes16 Trumpd"]]
            DemDem = pd.merge(DemRep12, DemRep16, how = "inner", on=["Fips"]) # this determines how many of the democrat counties in 2012 were aslo democrat countie2 in 2016
            print("There are",len(df),"counties in", state, "with", len(DemRep12), "of them voting democrat in 2012, and", len(DemRep16), \
            "of them voting democrat in 2016. Additionally,", len(DemDem), "of the", len(DemRep12), "counties that voted democrat in 2012 also voted democrat in 2016.")
        else:
            print("State not recognized, please try again.") # making sure the user inputs a proper state abbreviation
        check = input("Would you like to look at another state? (Y/N)")

# Same as previous function, but for republicans instead of democrats
def RepDem_state():
    check = "Y"
    while check == "Y":    
        state = input("Enter the abbreviation for the state you wish to examine for republicans (in caps, please):")
        if state in elections_df["ST"].values:
            is_key = elections_df["ST"] == state
            df = elections_df[is_key]
            RepDem12 = df[df["Democrats 12 (Votes)"] < df["Republicans 12 (Votes)"]]
            RepDem16 = df[df["Votes16 Clintonh"] < df["Votes16 Trumpd"]]
            RepRep = pd.merge(RepDem12, RepDem16, how = "inner", on=["Fips"])
            print("There are",len(df),"counties in", state, "with", len(RepDem12), "of them voting republican in 2012, and", len(RepDem16), \
            "of them voting republican in 2016. Additionally,", len(RepRep), "of the", len(RepDem12), "counties that voted republican in 2012 also voted republican in 2016.")
        else:
            print("State not recognized, please try again.") 
        check = input("Would you like to look at another state? (Y/N")

# Ask user which party to look at and allow them to move back and forth
check ="Y"
Check = input("Would you like to look at democrat or republican votes, or skip (D/R/S)?")
while check == "Y":
    if Check == "D":
        DemRep_state()
        check = input("Would you like to look at republican votes (Y/N)?")
        if check == "Y":
            Check = "R"
    elif Check == "R":
        RepDem_state()
        check = input("Would you like to look at democrat votes (Y/N)?")
        if check == "Y":
            Check = "D"
    else: 
        check == "N"
    
# Create a list to look at entire country as above, but by each state
elections_df = elections_df.sort_values("ST")
states1 = elections_df["ST"].unique()
states1 = np.delete(states1,[0,51]) # dropping Alaska as it has no data for 2012 or 2016, as well as the last row as it is NaN
newdf = []
for state in states1:
    is_key = elections_df["ST"] == state
    df = elections_df[is_key]
    counties = len(df)
    DemRep12 = df[df["Democrats 12 (Votes)"] > df["Republicans 12 (Votes)"]] 
    DemRep16 = df[df["Votes16 Clintonh"] > df["Votes16 Trumpd"]]
    DemDem = pd.merge(DemRep12, DemRep16, how = "inner", on=["Fips"])
    RepDem12 = df[df["Democrats 12 (Votes)"] < df["Republicans 12 (Votes)"]]
    RepDem16 = df[df["Votes16 Clintonh"] < df["Votes16 Trumpd"]]
    RepRep = pd.merge(RepDem12, RepDem16, how = "inner", on=["Fips"])
    AvgMedInc = sum(df["Median Earnings 2010"])/len(df) # determine the average median income of the counties for the current state
    if len(RepDem16) < len(DemRep16):
        Vote16 = "D"
    else:
        Vote16 = "R"
    Tuple = tuple([state, counties, len(DemRep12), len(DemRep16), len(DemDem), len(RepDem12), len(RepDem16), len(RepRep), AvgMedInc, Vote16])
    newdf.append(Tuple)

# Create a new list of "jumpers", ie counties that switched parties from 2012 to 2016 election
jumpers = []
for state in states1:
    is_key = elections_df["ST"] == state
    df = elections_df[is_key]
    DemRep12 = df[df["Democrats 12 (Votes)"] > df["Republicans 12 (Votes)"]] 
    DemRep16 = df[df["Votes16 Clintonh"] > df["Votes16 Trumpd"]]
    RepDem12 = df[df["Democrats 12 (Votes)"] < df["Republicans 12 (Votes)"]]
    RepDem16 = df[df["Votes16 Clintonh"] < df["Votes16 Trumpd"]]
    DemRep = pd.merge(DemRep12, RepDem16, how = "inner", on=["Fips"])
    RepDem = pd.merge(RepDem12, DemRep16, how = "inner", on=["Fips"])
    Tuple = tuple([state, len(DemRep), len(RepDem)])
    jumpers.append(Tuple)

# Add the jumpers to the data frame
for i in range(len(states1)-1):
    l1 = list(newdf[i])
    l2 = list(jumpers[i][1:3])
    l1.append(l2[0])
    l1.append(l2[1])
    newdf[i] = tuple(l1)

# Add sentiment to states we have the measure for
data = pd.DataFrame(newdf, columns = ["State", "Counties", "D12", "D16", "DD", "R12", "R16", "RR", "AvgMedInc", "Vote16", "DemJumpers", "RepJumpers"])
data1 = pd.merge(data, speech_df, how = "outer", on = ["State"])
data1 = data1[data1.Sentiment.notnull()]
data1 = data1.drop(columns = ["Text"])
data1["DJumpRatio"] = data1["DemJumpers"]/data1["D12"]
data1["RJumpRatio"] = data1["RepJumpers"]/data1["R12"]
data1["G-Party"] = ["R", "R", "D", "D", "D", "R", "R", "D", "R", "R", "R", "R", "R", "D", "R", "R", "R", "R", "D", "R", "R", "R", "R", "R", "D", "R", "R", "D", "D", "R", "R", "R", "D", "R", "D", "D"]
data1 = data1.fillna(0)
dem_states = data1[data1["G-Party"] == "D"]
rep_states = data1[data1["G-Party"] == "R"]
print("The average speech sentiment for states led by democratic governors was {:.2%}".format(statistics.mean(dem_states["Sentiment"])))
print("The average speech sentiment for states led by republican governors was {:.2%}".format(statistics.mean(rep_states["Sentiment"])))
len(rep_states.Sentiment[rep_states["D16"] > rep_states["R16"]])

# how did states vote relative to their governor
vote_pct = len(data1[data1["G-Party"] == data1["Vote16"]])/len(data1)
dem_pct = len(dem_states[dem_states["G-Party"] == dem_states["Vote16"]])/len(dem_states)
rep_pct = len(rep_states[rep_states["G-Party"] == rep_states["Vote16"]])/len(rep_states)
print("Overall, {:.2%}".format(vote_pct),"of states voted for the party of their governor. Additionally, {:.2%}".format(dem_pct),"of states with democrat governors voted for Hillary Clinton, while {:.2%}".format(rep_pct),"of states with republican governors voted for Donald Trump.")

# Linear regression to see if sentiment impacted party jump 
m1 = sm.OLS(data1["RepJumpers"],data1[["Sentiment"]]).fit()
print(m1.summary())
data1.plot(x="Sentiment", y="RepJumpers", style = 'o')
plt.title("Sentiment vs RpJumpers")
plt.xlabel("Sentiment")
plt.ylabel("RepJumpers")
plt.show()

m2 = sm.OLS(data1["DemJumpers"],data1[["Sentiment"]]).fit()
print(m2.summary())
data1.plot(x="Sentiment", y="DemJumpers", style = 'o')
plt.title("Sentiment vs DemJumpers")
plt.xlabel("Sentiment")
plt.ylabel("DemJumpers")
plt.show()

# Linear regression to see if median income impacted party jump
m3 = sm.OLS(data1["DemJumpers"],data1[["AvgMedInc"]]).fit()
print(m3.summary())
data1.plot(x="AvgMedInc", y="DemJumpers", style = 'o')
plt.title("AvgMedInc vs DemJumpers")
plt.xlabel("AvgMedInc")
plt.ylabel("DemJumpers")
plt.show()

m4 = sm.OLS(data1["RepJumpers"],data1[["AvgMedInc"]]).fit()
print(m4.summary())
data1.plot(x="AvgMedInc", y="RepJumpers", style = 'o')
plt.title("AvgMedInc vs RepJumpers")
plt.xlabel("AvgMedInc")
plt.ylabel("RepJumpers")
plt.show()

# Multiple regression to see how well sentiment and median income can predict demjumper
m5 = sm.OLS(data1["DemJumpers"],data1[["Sentiment", "AvgMedInc"]]).fit()
print(m5.summary())

# chi-sq test to see if governor party and how the state voted were independent
dd = len(dem_states[dem_states["G-Party"] == dem_states["Vote16"]])
dr = len(dem_states[dem_states["G-Party"] != dem_states["Vote16"]])
rr = len(rep_states[rep_states["G-Party"] == rep_states["Vote16"]])
rd = len(rep_states[rep_states["G-Party"] != rep_states["Vote16"]])
ct = np.array([[dd, dr], [rd, rr]])
print(ct)
chi2, p, dof, ex = chi2_contingency(ct, correction = False)
sig = float(input("Enter desired level of significance:"))
if p < sig:
    print("The chi-sq test is significant, with p =",p,"so we can reject the null hypothesis that governor party and voting party are independent.")
else:
    print("The chi-sq test is not significant, with p =",p,"so we fail to reject the null hypothesis that governor party and voting party are independent.")


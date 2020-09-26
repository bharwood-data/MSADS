#################################
#
# Authors: Ben Harwood, Kevin Vogel
# IST 664 Final Project Code
# Classifying Gubernatorial Inauguration Speeches as Democrat or Republican
# Version: Lost count
# Date: 06/05/2020
#
#################################

import nltk
from nltk.corpus import PlaintextCorpusReader
from nltk.tokenize import sent_tokenize
import numpy as np
import csv
from nltk.collocations import BigramCollocationFinder
from nltk.collocations import TrigramCollocationFinder
from nltk import FreqDist
import re
import random

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

############# Loading, processing, and bigrams for Democrat speeches ###########

dem_root = "E:/Documents/IST 664/Final Project/Democrats" # change this line as appropriate
dems = PlaintextCorpusReader(dem_root, ["Arizona.txt", "Connecticut.txt", "Illinois.txt", "Kentucky.txt", "Louisiana.txt", "Maine.txt", "Massachusetts.txt", "Michigan.txt", "New Hampshire.txt", "Vermont.txt"])
dem_sentences = []
for i in range(10):
    temp = dems.fileids()[i]
    temptext = dems.raw(temp)
    tempsent = sent_tokenize(temptext)
    dem_sentences = dem_sentences + tempsent

Dems = []
for i in range(10):
    temp = dems.fileids()[i]
    temptext = dems.raw(temp)
    tempTokens = nltk.word_tokenize(temptext)
    Dems = Dems + tempTokens

Demwords = [w.lower() for w in Dems]
DemAlphaWords = [w for w in Demwords if not alpha_filter(w)]
DemStoppedWords = [w for w in DemAlphaWords if not w in stopwords]
print("Democrats used", len(Demwords) - len(DemAlphaWords), "words in their speeches,", round((1-len(DemStoppedWords)/len(DemAlphaWords))*100,2), "percent of which were stop words.")

Demfinder = BigramCollocationFinder.from_words(Demwords)
DemfinderT = TrigramCollocationFinder.from_words(Demwords)
DemScored = Demfinder.score_ngrams(bigram_measures.raw_freq)
DemScoredT = DemfinderT.score_ngrams(trigram_measures.raw_freq)
for score in DemScored[:50]:
    print(score)
Demfinder.apply_word_filter(alpha_filter)
DemfinderT.apply_word_filter(alpha_filter)
DemScored = Demfinder.score_ngrams(bigram_measures.raw_freq)
DemScoredT = DemfinderT.score_ngrams(trigram_measures.raw_freq)
for score in DemScored[:50]:
    print(score)
Demfinder.apply_word_filter(lambda w: w in stopwords)
DemfinderT.apply_word_filter(lambda w: w in stopwords)
DemScored = Demfinder.score_ngrams(bigram_measures.raw_freq)
DemScoredT = DemfinderT.score_ngrams(trigram_measures.raw_freq)
for score in DemScored[:50]:
    print(score)
for score in DemScoredT[:50]:
    print(score)    

Demdist = FreqDist(DemStoppedWords)
Demitems = Demdist.most_common(50)

# This code created syntax to use in Latex for creation of a table
# for i in range(50):
#    print(Demitems[i][0],"\t & \t",Demitems[i][1], "\t & \t", DemScored[i][0], "\t &\t", round(DemScored[i][1],4), "\\\\")

# This chunk wrote the democrat sentences into a csv file that needed work done within Excel. This file has been provided
# with open("demsentences.csv", "w") as result_file:
#    wr = csv.writer(result_file, dialect = "excel")
#    wr.writerows(np.transpose([dem_sentences,]))

############# Loading, processing, and bigrams for Republican speeches ###########

rep_root = "E:/Documents/IST 664/Final Project/Republicans" # change this line as appropriate
reps = PlaintextCorpusReader(rep_root, ["Arizona.txt", "Connecticut.txt", "Illinois.txt", "Kentucky.txt", "Louisiana.txt", "Maine.txt", "Massachusetts.txt", "Michigan.txt", "New Hampshire.txt", "Vermont.txt"])
rep_sentences = []
for i in range(10):
    temp = reps.fileids()[i]
    temptext = reps.raw(temp)
    tempsent = sent_tokenize(temptext)
    rep_sentences = rep_sentences + tempsent

Reps = []
for i in range(10):
    temp = reps.fileids()[i]
    temptext = reps.raw(temp)
    tempTokens = nltk.word_tokenize(temptext)
    Reps = Reps + tempTokens

Repwords = [w.lower() for w in Reps]
RepAlphaWords = [w for w in Repwords if not alpha_filter(w)]
RepStoppedWords = [w for w in RepAlphaWords if not w in stopwords]
print("Republicans used", len(Repwords) - len(RepAlphaWords), "words in their speeches,", round((1-len(RepStoppedWords)/len(RepAlphaWords))*100,2), "percent of which were stop words.")
Repfinder = BigramCollocationFinder.from_words(Repwords)
RepfinderT = TrigramCollocationFinder.from_words(Repwords)
RepScored = Repfinder.score_ngrams(bigram_measures.raw_freq)
RepScoredT = RepfinderT.score_ngrams(trigram_measures.raw_freq)
for score in RepScored[:50]:
    print(score)
Repfinder.apply_word_filter(alpha_filter)
RepScored = Repfinder.score_ngrams(bigram_measures.raw_freq)
RepfinderT.apply_word_filter(alpha_filter)
RepScoredT = RepfinderT.score_ngrams(bigram_measures.raw_freq)
for score in RepScored[:50]:
    print(score)
Repfinder.apply_word_filter(lambda w: w in stopwords)
RepScored = Repfinder.score_ngrams(bigram_measures.raw_freq)
RepfinderT.apply_word_filter(lambda w: w in stopwords)
RepScoredT = RepfinderT.score_ngrams(bigram_measures.raw_freq)
for score in RepScored[:50]:
    print(score) 
for score in RepScoredT[:50]:
    print(score)
Repdist = FreqDist(RepStoppedWords)
Repitems = Repdist.most_common(50)

# Similar to the democrat section, this code created syntax to create a table in Latex
# for i in range(50):
#    print(Repitems[i][0],"\t & \t",Repitems[i][1], "\t & \t", RepScored[i][0], "\t &\t", round(RepScored[i][1],4), "\\\\")

# This chunk wrote the republican sentences into a csv file that needed work done within Excel. This file has been provided
# with open("repsentences.csv", "w") as result_file:
#    wr = csv.writer(result_file, dialect = "excel")
#    wr.writerows(np.transpose([rep_sentences,]))

##### Merging Democrat and Republican data for further exploration ####################

with open("demsentences.csv") as f:
    reader = csv.reader(f)
    next(reader)
    DemSentFile = [r for r in reader]
with open("repsentences.csv") as f:
    reader = csv.reader(f)
    next(reader)
    RepSentFile = [r for r in reader]

Sents = DemSentFile + RepSentFile
SentFile = []
for i in range(len(Sents)):
    party = Sents[i][0]
    words = nltk.word_tokenize(Sents[i][1])
    words = [w.lower() for w in words]
    alphawords = [w for w in words if not alpha_filter(w)]
    Tuple = tuple([alphawords, party])
    SentFile.append(Tuple)
random.shuffle(SentFile)

########### Base feature set generation and testing ##################
all_words_list = [word for (sent, p) in SentFile for word in sent]
all_words = nltk.FreqDist(all_words_list)
word_items = all_words.most_common(2000)
word_features = [word for (word, count) in word_items]
word_features[:50]

def document_features(document, word_features):
    document_words = set(document)
    features = {}
    for word in word_features:
        features["V_{}".format(word)] = (word in document_words)
    return features

featuresets = [(document_features(s, word_features), p) for (s, p) in SentFile]
baseScores = []
for i in range(5):
    train_set, test_set = featuresets[round((0.1+0.05*i)*len(featuresets)):], featuresets[:round((0.1+0.05*i)*len(featuresets))]
    classifier = nltk.NaiveBayesClassifier.train(train_set)
    score = nltk.classify.accuracy(classifier, test_set)
    baseScores.append(tuple([round(1-(0.1+0.05*i),2), round(score,4)]))
baseScores

def cross_validation(num_folds, featuresets):
    subset_size = int(len(featuresets)/num_folds)
    print(num_folds, "folds, each of size:", subset_size)
    gold = []
    predicted = []
    accuracy_list = []
    precision_list = []
    recall_list = []
    f1_list = []
    Recall = []
    Precision = []
    F1 = []
    true_pos = true_neg = false_pos = false_neg = 0
    for i in range(num_folds):
        test_this_round = featuresets[(i*subset_size):][:subset_size]
        train_this_round = featuresets[:(i*subset_size)] + featuresets[((i+1)*subset_size):]
        classifier = nltk.NaiveBayesClassifier.train(train_this_round)
        goldlist = []
        predictedlist = []
        for (features, label) in test_this_round:
            goldlist.append(label)
            gold.append(label)
            predictedlist.append(classifier.classify(features))
            predicted.append(classifier.classify(features))
        accuracy_this_round = nltk.classify.accuracy(classifier, test_this_round)
        print(i, accuracy_this_round)
        accuracy_list.append(accuracy_this_round)
        labels = list(set(goldlist))
        for lab in labels:
            TP=FP=FN=TN=0
            for i, val in enumerate(goldlist):
                if val == lab and predictedlist[i] == lab: TP += 1
                if val == lab and predictedlist[i] != lab: FN += 1
                if val != lab and predictedlist[i] == lab: FP += 1
                if val != lab and predictedlist[i] != lab: TN += 1
            recall = TP / (TP + FP)
            precision = TP / (TP + FN)
            recall_list.append(recall)
            precision_list.append(precision)
            f1_list.append(2 * (recall * precision) / (recall + precision))
            if lab == "R":
                true_pos = true_pos + TP
                true_neg = true_neg + TN
                false_pos = false_pos + FP
                false_neg = false_neg + FN
    Recall.append(true_pos / (true_pos + false_pos))
    Recall.append(true_neg / (true_neg + false_neg))
    Precision.append(true_pos / (true_pos + false_neg))
    Precision.append(true_neg / (true_neg + false_pos))
    F1.append((2 * Recall[0] * Precision[0]) / (Recall[0] + Precision[0]))
    F1.append((2 * Recall[1] * Precision[1]) / (Recall[1] + Precision[1]))
    cm = nltk.ConfusionMatrix(gold, predicted)
    print("Average accuracy:", sum(accuracy_list)/num_folds)
    print(cm.pretty_format(sort_by_count = True, truncate=9))
    print("Party\tPrecision\t Recall\t\t     F1")
    for i, lab in enumerate(labels):
        print(lab, "\t","{:7.3f}".format(Precision[i]), "\t", \
            "{:7.3f}".format(Recall[i]), "\t", "{:7.3f}".format(F1[i]))

cross_validation(10, featuresets)

########### Subjectivity feature set generation and testing ########
SLpath = "E:/Documents/IST 664/Data/subjclueslen1-HLTEMNLP05.tff"
def readSubjectivity(path):
    flexicon = open(path, 'r')
    sldict = { }
    for line in flexicon:
        fields = line.split()   
        strength = fields[0].split("=")[1]
        word = fields[2].split("=")[1]
        posTag = fields[3].split("=")[1]
        stemmed = fields[4].split("=")[1]
        polarity = fields[5].split("=")[1]
        if (stemmed == 'y'):
            isStemmed = True
        else:
            isStemmed = False
        sldict[word] = [strength, posTag, isStemmed, polarity]
    return sldict
SL = readSubjectivity(SLpath)

def SL_features(document, word_features, SL):
    document_words = set(document)
    features = {}
    for word in word_features:
        features["V_{}".format(word)] = (word in document_words)
    weakPos = 0
    strongPos = 0
    weakNeg = 0
    strongNeg = 0
    for word in document_words:
        if word in SL:
            strength, posTag, isStemmed, polarity = SL[word]
            if strength == "weaksubj" and polarity == "positive":
                weakPos += 1
            if strength == "strongsubj" and polarity == "positive":
                strongPos += 1
            if strength == "weaksubj" and polarity == "negative":
                weakNeg += 1
            if strength == "strongsubj" and polarity == "negative":
                strongNeg += 1
            features["positivecount"] = weakPos + (2 * strongPos)
            features["negativecount"] = weakNeg + (2 * strongNeg)
    return features

SL_featuresets = [(SL_features(s, word_features, SL), p) for (s, p) in SentFile]

SLscores = []
for i in range(5):
    SL_train_set, SL_test_set = SL_featuresets[round((0.1+0.05*i)*len(SL_featuresets)):], SL_featuresets[:round((0.1+0.05*i)*len(SL_featuresets))]
    SL_classifier = nltk.NaiveBayesClassifier.train(SL_train_set)
    score = nltk.classify.accuracy(SL_classifier, SL_test_set)
    SLscores.append(tuple([round(1-(0.1+0.05*i),2), round(score,4)]))
SLscores

cross_validation(10, SL_featuresets)
########### Negation feature set generation and exploration ##################
negationwords = ["no", "not", "never", "none", "nowhere", "nothing", "noone", "rather", "hardly", "scarcely", "rarely", "seldom", "neither", "nor"]

def NOT_features(document, word_features, negationwords):
    features = {}
    for word in word_features:
        features["V_{}".format(word)] = False
        features["N_NOT{}".format(word)] = False
    for i in range(0, len(document)):
        word = document[i]
        if ((i + 1) < len(document)) and ((word in negationwords) or (word.endswith("n't"))):
            i += 1
            features["V_NOT{}".format(document[i])] = (document[i] in word_features)
        else:
            features["V_{}".format(word)] = (word in word_features)
    return features

NOT_featuresets = [(NOT_features(s, word_features, negationwords), p) for (s, p) in SentFile]

NOTscores = []
for i in range(5):
    NOT_train_set, NOT_test_set = NOT_featuresets[round((0.1+0.05*i)*len(NOT_featuresets)):], NOT_featuresets[:round((0.1+0.05*i)*len(NOT_featuresets))]
    NOT_classifier = nltk.NaiveBayesClassifier.train(NOT_train_set)
    score = nltk.classify.accuracy(NOT_classifier, NOT_test_set)
    NOTscores.append(tuple([round(1-(0.1+0.05*i), 2), round(score, 4)]))
NOTscores

cross_validation(10, NOT_featuresets)
############## POS tags ##################

def POS_features(document, word_features):
    document_words = set(document)
    tagged_words = nltk.pos_tag(document)
    features = {}
    for word in word_features:
        features['V_{}'.format(word)] = (word in document_words)
    numNoun = 0
    numVerb = 0
    numAdj = 0
    numAdverb = 0
    for (word, tag) in tagged_words:
        if tag.startswith('N'): numNoun += 1
        if tag.startswith('V'): numVerb += 1
        if tag.startswith('J'): numAdj += 1
        if tag.startswith('R'): numAdverb += 1
    features['nouns'] = numNoun
    features['verbs'] = numVerb
    features['adjectives'] = numAdj
    features['adverbs'] = numAdverb
    return features

POS_featuresets = [(POS_features(s, word_features), p) for (s, p) in SentFile]
POS_scores = []
for i in range(5):
    POS_train_set, POS_test_set = POS_featuresets[round((0.1+0.05*i)*len(POS_featuresets)):], POS_featuresets[:round((0.1+0.05*i)*len(POS_featuresets))]
    POS_classifier = nltk.NaiveBayesClassifier.train(POS_train_set)
    score = nltk.classify.accuracy(POS_classifier, POS_test_set)
    POS_scores.append(tuple([round(1-(0.1+0.05*i),2), round(score,4)]))
POS_scores

cross_validation(10, POS_featuresets)

############### Bigrams ##################
finder = BigramCollocationFinder.from_words(all_words_list)
bigram_features = finder.nbest(bigram_measures.pmi, 2000)
def bigram_document_features(document, word_features, bigram_features):
    document_words = set(document)
    document_bigrams = nltk.bigrams(document)
    features = {}
    for word in word_features:
        features['V_{}'.format(word)] = (word in document_words)
    for bigram in bigram_features:
        features['B_{}_{}'.format(bigram[0], bigram[1])] = (bigram in document_bigrams)
    return features
Bigram_featuresets = [(bigram_document_features(s, word_features, bigram_features), p) for (s, p) in SentFile]

Bigram_scores = []
for i in range(5):
    Bigram_train_set, Bigram_test_set = Bigram_featuresets[round((0.1+0.05*i)*len(Bigram_featuresets)):], Bigram_featuresets[:round((0.1+0.05*i)*len(Bigram_featuresets))]
    Bigram_classifier = nltk.NaiveBayesClassifier.train(Bigram_train_set)
    score = nltk.classify.accuracy(Bigram_classifier, Bigram_test_set)
    Bigram_scores.append(tuple([round(1-(0.1+0.05*i),2), round(score,4)]))
Bigram_scores

cross_validation(10, Bigram_featuresets)

################### Removing stopwords ##################
newstopwords = [word for word in stopwords if word not in negationwords]

new_all_words_list = [word for word in all_words_list if word not in newstopwords]
new_all_words = nltk.FreqDist(new_all_words_list)
new_word_items = new_all_words.most_common(2000)
new_word_features = [word for (word, count) in new_word_items]

################### Repeating base featuresets with stop words removed ######################
featuresets1 = [(document_features(s, new_word_features), p) for (s, p) in SentFile]
baseScores1 = []
for i in range(5):
    train_set1, test_set1 = featuresets1[round((0.1+0.05*i)*len(featuresets1)):], featuresets1[:round((0.1+0.05*i)*len(featuresets1))]
    classifier1 = nltk.NaiveBayesClassifier.train(train_set1)
    score = nltk.classify.accuracy(classifier1, test_set1)
    baseScores1.append(tuple([round(1-(0.1+0.05*i),2), round(score,4)]))
baseScores1

cross_validation(10, featuresets1)

#################### Subjectivity with stop words removed ####################
SL_featuresets1 = [(SL_features(s, new_word_features, SL), p) for (s, p) in SentFile]

SLscores1 = []
for i in range(5):
    SL_train_set, SL_test_set = SL_featuresets1[round((0.1+0.05*i)*len(SL_featuresets1)):], SL_featuresets1[:round((0.1+0.05*i)*len(SL_featuresets1))]
    SL_classifier = nltk.NaiveBayesClassifier.train(SL_train_set)
    score = nltk.classify.accuracy(SL_classifier, SL_test_set)
    SLscores1.append(tuple([round(1-(0.1+0.05*i),2), round(score,4)]))
SLscores1

cross_validation(10, SL_featuresets1)

############## Negation with stop words removed ##################
NOT_featuresets1 = [(NOT_features(s, new_word_features, negationwords), p) for (s, p) in SentFile]

NOTscores1 = []
for i in range(5):
    NOT_train_set1, NOT_test_set1 = NOT_featuresets1[round((0.1+0.05*i)*len(NOT_featuresets1)):], NOT_featuresets1[:round((0.1+0.05*i)*len(NOT_featuresets1))]
    NOT_classifier1 = nltk.NaiveBayesClassifier.train(NOT_train_set1)
    score = nltk.classify.accuracy(NOT_classifier1, NOT_test_set1)
    NOTscores1.append(tuple([round(1-(0.1+0.05*i), 2), round(score, 4)]))
NOTscores1

cross_validation(10, NOT_featuresets1)

############## POS tags with stop words removed ##################
POS_featuresets1 = [(POS_features(s, new_word_features), p) for (s, p) in SentFile]
POS_scores1 = []
for i in range(5):
    POS_train_set1, POS_test_set1 = POS_featuresets1[round((0.1+0.05*i)*len(POS_featuresets1)):], POS_featuresets1[:round((0.1+0.05*i)*len(POS_featuresets1))]
    POS_classifier1 = nltk.NaiveBayesClassifier.train(POS_train_set1)
    score1 = nltk.classify.accuracy(POS_classifier1, POS_test_set1)
    POS_scores1.append(tuple([round(1-(0.1+0.05*i),2), round(score1,4)]))
POS_scores1

cross_validation(10, POS_featuresets1)

########## Bigrams ##################
finder1 = BigramCollocationFinder.from_words(new_all_words_list)
bigram_features1 = finder1.nbest(bigram_measures.pmi, 2000)
Bigram_featuresets1 = [(bigram_document_features(s, new_word_features, bigram_features1), p) for (s, p) in SentFile]

Bigram_scores1 = []
for i in range(5):
    Bigram_train_set1, Bigram_test_set1 = Bigram_featuresets1[round((0.1+0.05*i)*len(Bigram_featuresets1)):], Bigram_featuresets1[:round((0.1+0.05*i)*len(Bigram_featuresets1))]
    Bigram_classifier1 = nltk.NaiveBayesClassifier.train(Bigram_train_set1)
    score = nltk.classify.accuracy(Bigram_classifier1, Bigram_test_set1)
    Bigram_scores1.append(tuple([round(1-(0.1+0.05*i),2), round(score,4)]))
Bigram_scores1

cross_validation(10, Bigram_featuresets1)

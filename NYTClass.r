
###############################################################################################
# DESCRIPTION: Saving a trained model and using it to classifying and predicting new data #
# This is a three step process
# 1) Model Calibration/development: develop a model using a first subset of data
# 2) Model Validation: use the develped model to simulate a second subset of data
# 3) Model Predction: use the calibrated and validated model to predict third subset or future data 
###############################################################################################
###############################################################################################
setwd("~/Documents/text")
library("RTextTools")
library("plyr")
library("Matrix")
library("tm")
library("e1071")
########################################################
#sourced a script wihich holds the modified create_matrix function. 
source("create_mat.R")
########################################################
# READ THE CSV DATA
data(NYTimes)
str(NYTimes)
summary(NYTimes)
#finding missing values and droping columns with more then 400 NA value
lapply(NYTimes, function(x) count(is.na(x)))

# [OPTIONAL] SUBSET YOUR DATA TO GET A RANDOM SAMPLE
set.seed(202)
NYTimes<- NYTimes[sample(nrow(NYTimes)),]
############################################################################################
# subsetting data into three dataset for tranning, testing, and prediction purposes #
############################################################################################
#     data_matrix AND CONTAINER CREATION     #
#############################################################################################
data_matrix <- create_matrixv(cbind(NYTimes["Title"],NYTimes["Subject"]), language="english", removeNumbers=TRUE, stemWords=TRUE,weighting=tm::weightTfIdf)


data_matrix
data_container <- create_container(data_matrix,NYTimes$Topic.Code,trainSize=1:1500,testSize=1501:3000, virgin=FALSE)

names(attributes(data_container)) #class matrix_container
# Quick look at data_container
(training_matrix <- data_container@training_matrix)
(column_names<- data_container@column_names)
(training_matrix1 <- as.matrix(training_matrix))
(colnames(training_matrix1) <- column_names)
training_matrix1[1:10,1:10]

################################################
#    	  Step1: TRAIN MODELS				 #
################################################
model <- train_model(data_container, algorithm="SVM")
print(model)
summary(model)
################################################
#      Step2:	CLASSIFY MODELS		     #
################################################
classify_data <- classify_model(data_container, model)

################################################
# VIEW THE RESULTS BY CREATING ANALYTICS #
################################################
analytics <- create_analytics(data_container, classify_data)
analytics@algorithm_summary #SUMMARY OF PRECISION, RECALL, F-SCORES, AND ACCURACY SORTED BY TOPIC CODE FOR EACH ALGORITHM
analytics@label_summary #SUMMARY OF LABEL (e.g. TOPIC) ACCURACY
analytics@ensemble_summary #SUMMARY OF ENSEMBLE PRECISION/COVERAGE. USES THE n VARIABLE PASSED INTO create_analytics()

class_prob<-cbind(c(1:8, 10,12:21,24,26,27, 28,29,30,31,99),analytics@label_summary$PCT_CORRECTLY_CODED_PROBABILITY)

colnames(class_prob)<-c("Predicted.Topic.Code","Probability")
View(class_prob)
write.csv(class_prob,"class_prob.csv", row.names=FALSE)

# CHECK OVERALL ACCURACY OF ALGORITHMS
###########################################
recall_accuracy (analytics@document_summary$MANUAL_CODE, analytics@document_summary$PROBABILITY_CODE)
levels(classify_data$SVM_LABEL)
###############################################
#Create new data which you want to classify: 
###############################################
newdata<- NYTimes[3001:3104, ]

newmatrix <- create_matrixv(cbind(newdata["Title"],newdata["Subject"]), language="english", removeNumbers=TRUE, stemWords=TRUE,originalMatrix=data_matrix,weighting=tm::weightTfIdf)

###############################################
#        Step3: MODEL PREDICTION  #
###############################################
pred<-predict(model, newmatrix, decision.values = FALSE,probability = FALSE, na.action = na.omit)
output<-cbind(newdata,pred)
colnames(output)[6]<-'Predicted.Topic.Code'
View(poutput)
names(output)
pred_output<-merge(x=output,y=class_prob, by= 'Predicted.Topic.Code')
pred_output<-pred_output[c(2,3,4,5,6,1,7)]
write.csv(pred_output,"pred_output.csv", row.names=FALSE)
View(pred_output)





# Export some RMarkdown environment settings to the console.
console = new.env()
console$read.csv = function(fname, stringsAsFactors=TRUE) {
  wd = getwd()
  setwd(console$working_dir)
  csv = read.csv(fname, stringsAsFactors=stringsAsFactors)
  setwd(wd)
  csv
}

console$write.csv = function(obj, fname, row.names=FALSE) {
  wd = getwd()
  setwd(console$working_dir)
  write.csv(obj, fname, row.names=row.names)
  set(wd)
}

console$read.RDS = function(fname) {
  wd = getwd()
  setwd(console$working_dir)
  model = readRDS(fname)
  set(wd)
  model
}

console$working_dir = getwd()
console$files_list = list.files()
console$getwd = function() { console$working_dir }
console$setwd = function(wd) { setwd(wd) }
console$list.files = function() { files_list }

analysis = new.env()
# Objective functions
analysis$sq_error = function(y_pred, y) {
  (y_pred - y)^2
}

analysis$rmse = function(y_pred, y) {
  sqrt(mean(analysis$sq_error(y_pred, y)))
}

# Error analysis: confusion matrix, accuracy, precision,
#                 recall, f1 score
analysis$rating_confusionMatrix = function(y_pred, y, rating) {
  y_pred = round(as.numeric(y_pred))
  tab = table(y_pred != rating, y != rating)
  conf = list()
  conf$TP = tab[1, 1]
  conf$FP = tab[1, 2]
  conf$FN = tab[2, 1]
  conf$TN = tab[2, 2]
  conf
}

analysis$confusion = function(y_pred, y) {
  conf = data.frame()
  for (i in 1:5) {
    cm = analysis$rating_confusionMatrix(y_pred, y, i)
    conf[i, "TP"] = cm$TP
    conf[i, "FP"] = cm$FP
    conf[i, "FN"] = cm$FN
    conf[i, "TN"] = cm$TN
  }
  conf
}

analysis$rating_accuracy = function(conf) {
  (conf$TP + conf$TN) / rowSums(conf)
}

analysis$rating_precision = function(conf) {
  conf$TP / (conf$TP + conf$FP)
}

analysis$rating_recall = function(conf) {
  conf$TP / (conf$TP + conf$FN)
}

analysis$rating_fscore = function(conf) {
  pre = analysis$rating_precision(conf)
  rec = analysis$rating_recall(conf)
  (2 * pre * rec) / (pre + rec)
}

analysis$rating_score = function(y_pred, y) {
  conf = analysis$confusion(y_pred, y)
  accuracy = analysis$rating_accuracy(conf)
  precision = analysis$rating_precision(conf)
  recall = analysis$rating_recall(conf)
  fscore = analysis$rating_fscore(conf)
  data.frame(accuracy, precision, recall, fscore)
}

analysis$score_dist = function(score1, score2) {
  score1-score2
}
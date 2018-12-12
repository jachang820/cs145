library(dplyr)
library(ggplot2)
library(gridExtra)

# Since these AWS packages take forever to load...
if (Sys.info()["sysname"] != "Windows") {
  if (!"package:aws.ec2metadata" %in% search()) {
    library(aws.ec2metadata)
  }
  if (!"package:aws.s3" %in% search()) {
    library(aws.s3)
  }
}

BUCKET_NAME = "jc-rstudio"

trainfuncs = new.env()

# Import CSV. Works with both local and S3. Returns NA if
# file does not exist.
trainfuncs$read.csv = function(filename, ...) {
  args = as.list(match.call())[-c(1,2)]
  args = eval(args)  
  
  if (trainfuncs$file.exists(filename)) {
    if (aws.ec2metadata::is_ec2()) {
      fname = paste("s3:/", BUCKET_NAME, filename, sep="/")
      do.call(aws.s3::s3read_using, c(read.csv, object=fname, args))
    } else {
      do.call(read.csv, c(filename, args))
    } 
  } else {
    NULL
  }
}

trainfuncs$write.table = function(data, filename, ...) {
  args = as.list(match.call())[-c(1,2,3)]

  if (aws.ec2metadata::is_ec2()) {
    do.call(write.csv, c(list(data), filename, args))
    do.call(aws.s3::s3write_using, c(list(data), write.table, 
                                     args,
                                     object=filename, 
                                     bucket=BUCKET_NAME))
  } else {
    do.call(write.table, c(list(data), filename, args))
  }
}

trainfuncs$file.exists = function(filename) {
  if (aws.ec2metadata::is_ec2()) {
    trainfuncs$bucket = aws.s3::get_bucket_df(BUCKET_NAME)
    filename %in% trainfuncs$bucket$Key
  } else {
    file.exists(filename)
  }
}

# Get indexes by names. 
# axis=1 for row name
# axis=2 for column name
trainfuncs$which.index = function(data, name, axis=2) {
  axis.names = ifelse(axis==2, names, rownames)
  if (sum(names(data) %in% c(name)) > 0) {
    which(axis.names(data) %in% c(name))
  } else {
    NULL
  }
}
which.index = trainfuncs$which.index

# Remove row or column on condition.
# axis=1 for row name
# axis=2 for column name
trainfuncs$rm_if = function(condition, data, name, axis=2) {
  index = trainfuncs$which.index(data, name)
  if (!is.null(index)) {
    if (inherits(data, "list")) {
      ifelse(condition, data[-index], data)
    } else {
      ifelse(condition, 
             ifelse(axis==2, data[,-index], data[-index,]), 
             data)
    }
  } else {
    data
  }
}

# Define algorithm name
trainfuncs$set_alg_name = function(name) {
  trainfuncs$alg_name = name
  trainfuncs$grid_file = paste(name, "grid.csv", sep='_')
}

# Use default parameters if alternatives are not supplied.
if (!exists("default_params")) {
  default_params = list()
}

# Define which functions to use (default: linear regression).
if (!exists("train_fct")) {
  train_fct = lm
}
if (!exists("predict_fct")) {
  predict_fct = predict
}

# Add default params to list of supplied parameters.
trainfuncs$update_params = function(params_lst) {
  params = default_params
  if (length(params_lst) > 0) {
    param_names = names(params_lst)
    for (i in 1:length(params_lst)) {
      params[param_names[i]] = params_lst[param_names[i]]
    }
  }
  params
}

# Remove parameters that match defaults from supplied list.
trainfuncs$remove_defaults = function(params_lst) {
  if (length(params_lst) > 0 && length(default_params) > 0) {
    param_names = names(default_params)
    for (i in 1:length(default_params)) {
      name = param_names[i]
      p = default_params[[i]]
      if (!is.numeric(p) && !is.character(p) && !is.logical(p) &&
          is.factor(p)) {
        ind = trainfuncs$which.index(params_lst, name)
        if (!is.null(ind)) {
          params_lst = params_lst[-ind]
        }
      } else if (!is.null(params_lst[[name]]) &&
                 params_lst[[name]] == p) {
        ind = trainfuncs$which.index(params_lst, name)
        if (!is.null(ind)) {
          params_lst = params_lst[-ind]
        }
      }
    }
  }
  params_lst
}

# Use default parameters, plus supplied parameters, to 
# create commonly used values.
trainfuncs$get_params = function(..., final=FALSE, updates=NULL) {
  arg = as.list(match.call())[-1]
  arg = eval(arg)
  arg$final = NULL
  arg$updates = NULL
  arg = c(updates, arg)
  arg = arg[!duplicated(names(arg))]
  
  # Prepare list of all parameters.
  params = trainfuncs$update_params(arg)
  params = params[sort(names(params))]

  # Format file names.
  param_str = trainfuncs$remove_defaults(params)
  if (length(param_str) > 0) {
    name = names(param_str)
    for (i in 1:length(param_str)) {
      if (is.logical(param_str[[i]])) {
        param_str[[i]] = substr(name[i], 1, 6)
      } else if (is.factor(param_str[[i]]) || 
        is.character(param_str[[i]])) {
        param_str[[i]] = substr(as.character(param_str[[i]]), 1, 6)
      } else if (is.numeric(param_str[[i]])) {
        param_str[[i]] = paste(substr(name[i], 1, 2), 
                               param_str[[i]], sep='')
      }
    }
    param_str = paste(param_str, collapse="_")
  } else {
    param_str = "default"
  }
  alg_name = trainfuncs$alg_name
  if (final) {
    alg_name = paste(alg_name, "final", sep='_')
  }
  csv = paste("submit", alg_name, param_str, sep='_')
  rds = paste(alg_name, param_str, sep='_')

  # Return value.
  list(args = params,
       csv = paste("submit/", csv, ".csv", sep=''),
       rds = paste("models/", rds, ".rds", sep=''),
       log = paste("logs/", rds, ".log", sep=''),
       final = final)
}

trainfuncs$valid_args = function(fct, arg) {
  valid_names = names(arg) %in% names(formals(fct))
  name = names(arg)[valid_names]
  arg = arg[valid_names]
  names(arg) = name
  arg
}

trainfuncs$train = function(train_args, params) {
  arg = c(train_args, params$args) 
  model = do.call(train_fct, arg)
  params$rds = trainfuncs$enum_filename(params$rds)
  saveRDS(model, params$rds)
  model
}

trainfuncs$predict = function(model, newdata, 
															labels=NULL, pred_obj=NULL, params=NULL) {
  pred = do.call(predict_fct, list(model, newdata))
  if (!is.null(pred_obj)) {
    pred = pred[[pred_obj]]
  }
  if (!is.null(labels)) {
    rmse_ = sqrt(mean((pred - labels)^2))
    paste("RMSE:", rmse_, sep=' ') %>% cat()
    if (!is.null(params)) {
      arg = c(params$rds, params$args, rmse_)
      cols = c("modelname", names(params$args), "rmse")
      names(arg) = cols
      record = data.frame()
      col.names = !file.exists(trainfuncs$grid_file)
      for (n in 1:length(arg)) {
        record[1, cols[n]] = arg[n]
      }
      if (col.names) {
        trainfuncs$write.table(record, trainfuncs$grid_file, 
                               sep=',', col.names=TRUE, 
                               append=FALSE, row.names=FALSE)  
      } else {
        trainfuncs$write.table(record, trainfuncs$grid_file, 
                               sep=',', col.names=FALSE, 
                               append=TRUE, row.names=FALSE)
      }
    }
  }
  if (!is.null(params) && is.null(labels)) {
    submit = data.frame(seq.int(0, nrow(newdata) - 1), pred)
    names(submit) = c("index", "stars")
    params$csv = trainfuncs$enum_filename(params$csv)
    write.csv(submit, params$csv, row.names=FALSE, quote=FALSE)
  }
  pred
}

trainfuncs$enum_filename = function(filename) {
  if (file.exists(filename)) {

    # Remove file extension (.csv, .rds)
    n = nchar(filename)
    file_no_ext = strtrim(filename, n - 4)
    file_ext = substr(filename, n - 3, n)
    num = 2
    while (file.exists(paste(file_no_ext, "(", num, ")", 
                             file_ext, sep=''))) {
      num = num + 1
    }
    filename = paste(file_no_ext, "(", num, ")", 
                     file_ext, sep='')
  }
  filename
}

trainfuncs$train.predict = function(train_args, params, newdata, 
                         labels=NULL, pred_obj=NULL, combos=NULL) {
  if (is.null(combos)) {
    combos = data.frame(NULL)
    n = 1
  } else {
    combos = do.call(expand.grid, combos)
    n = nrow(combos)
  }
  pred = matrix(nrow=nrow(newdata), ncol=n)

  for (i in 1:n) {
    paste("\nTrial",i,"of",n,":\n", sep=' ') %>% cat()
    arg = c(combos[i, ], params$args)

    # Fix problem of name not carrying over when combo has only
    # one column.
    if (ncol(combos) > 0) {
      name = names(arg)
      name[1] = names(combos)[1]
      names(arg) = name     
    }

    arg = trainfuncs$valid_args(train_fct, arg) 
    params = do.call(trainfuncs$get_params, 
                     c(arg, final=params$final))

    params$args = params$args[!duplicated(names(params$args))]
    model = trainfuncs$train(train_args, params)
    pred[, i] = trainfuncs$predict(model, newdata, 
                                   labels, pred_obj, params)
  }
  pred
}

trainfuncs$join_sets = function(data, split=FALSE) {
  data = inner_join(data, users, by='uid')
  data = inner_join(data, business, by='bid')
  data$uid = NULL
  data$bid = NULL
  if (split && !is.null(data$stars)) {
    data_y = data$stars
    data_X = data[, -trainfuncs$which.index(data, "stars")]
    data = list(X=data_X, y=data_y)
  }
  data
}

trainfuncs$best_params = function(lower=1, upper=NULL, verbose=FALSE) {
  p_grid = read.csv(trainfuncs$grid_file, stringsAsFactors=FALSE)
  if (is.null(upper)) {
    upper = nrow(p_grid)
  }
  p_grid = p_grid[lower:upper, ]
  min_index = which.min(p_grid$rmse)
  n = names(p_grid)[-1]
  best = p_grid[min_index, ]
  best = best[-1]
  if (verbose) {
    features = paste(n, ":  ", best, sep='', collapse="\n  ")
    paste("BEST PARAMS", features, sep="\n  ") %>% cat()
  }  
  best
}

# Range (min, mean, max) summary of one parameter in grid file
trainfuncs$param_summary = function(grid, param, y="rmse") {
  y_name = as.name(y)
  as.data.frame(grid %>% 
    group_by_(param) %>% 
    summarize(max=max(!!y_name),
              mean=mean(!!y_name),
              min=min(!!y_name)))
}

# Plot range of one parameter in grid file
trainfuncs$plot_param = function(grid, param, y="rmse", title=TRUE) {
  bands = trainfuncs$param_summary(grid, param, y)
  gg = ggplot(bands) + 
    geom_ribbon(aes(x=get(param), ymin=min, ymax=max), 
                fill='lightsalmon', alpha=0.3) +
    geom_line(aes(get(param), mean), color='indianred2', size=1) + 
    xlab(param) + ylab(y) + theme_bw()
  if (title) {
    gg + ggtitle(paste("Mean", y, "\nby", param, sep=' ')) + 
      scale_x_continuous(expand = c(0,0))
  } else {
    gg
  }
}

# Table of best min, mean, max of one parameter in grid file
trainfuncs$param_range = function(grid, param) {
  bands = trainfuncs$param_summary(grid, param)
  rbind(lowest_max=bands[which.min(bands$max),],
        lowest_mean=bands[which.min(bands$mean),],
        lowest_min=bands[which.min(bands$min),])
}

# Grid of plots of correlation between each parameter
trainfuncs$plot_param_grid = function(pgrid, features=NULL) {
  if (is.null(features)) {
    features = names(pgrid)
  }
  features = as.list(features)
  n = length(features)
  if ("rmse" %in% features) {
    features[which(features == "rmse")] = NULL
    features = c("rmse", features)
  }
  
  plots = list()
  for (i in 1:n) {
    for (j in 1:n) {
      index = (i - 1) * n + j
      plots[[index]] = 
        trainfuncs$plot_param(pgrid, features[[j]], features[[i]], 
                              title=FALSE)
      if (i == 1) {
        plots[[index]] = plots[[index]] + xlab(features[[j]]) +
          scale_x_discrete(position = "top", expand = c(0,0)) 
      } else {
        plots[[index]] = plots[[index]] + xlab(NULL) +
          scale_x_continuous(expand = c(0,0))
      }
      if (j == 1) {
        plots[[index]] = plots[[index]] + ylab(features[[i]])
      } else {
        plots[[index]] = plots[[index]] + ylab(NULL)
      }
      if (i != n) {
        plots[[index]] = plots[[index]] + 
          theme(axis.ticks.x = element_blank(),
                axis.text.x = element_blank())
      }
      plots[[index]] = plots[[index]] +
        theme(plot.margin=grid::unit(c(0,0,0,0),"cm"),
              axis.ticks.y = element_blank(),
              axis.text.y = element_blank())
    }
  }
  do.call(grid.arrange, c(plots, ncol=n, top=title))
}

trainfuncs$submit = function(preds, params) {
  preds = as.vector(preds)
  submit = data.frame(index = seq.int(length(preds)) - 1, stars = preds)
  write.csv(submit, params$csv, row.names = FALSE, quote = FALSE)
  submit
}
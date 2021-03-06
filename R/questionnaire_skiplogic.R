
question_is_skipped_apply_condition_to_data<-function(data,condition){
  # if condition isn't a scalar, throw an error:
  if(length(condition)>1){stop("multiple elements passed as skiplogic condition")}
  if(!is.vector(condition) & !is.null(condition)){stop("skiplogic condition must be a single element string")}

  # if condition is any kind of empty, assume not skipped:
  all_false<-rep(FALSE,nrow(data))
  if(is.null(condition)){return(all_false)}
  if(condition %in% c(NA,"NA","N/A")){return(all_false)}
  if(grepl("^[[:space:]]*$",condition)){return(all_false)}
  # standardise variable names in condition
    condition_vars<-extract_all_varnames_from_condition(condition,rify = T)
    condition_varnames_standardised<-to_alphanumeric_lowercase(condition_vars)
    for(i in seq_along(condition_vars)){
      condition<-str_replace(condition,condition_vars[i],condition_varnames_standardised[i])
    }


# make sure all variable names all exist in the data
  if(!all(condition_varnames_standardised %in% names(data))){stop(paste0(
    "can't parse skiplogic: \n",
    "condition: '",condition,"'\n",
    "variable name(s) not found:\n",paste(condition_varnames_standardised[!(condition_varnames_standardised%in%names(data))],collapse="\n"))
  )}

  # parse the condition into an R expression:
  condition_rexpression<-rify_condition(condition)

  # run the r expression:
  not<-function(x){!x}
  relevant<-with(data,{
  relevant<-tryCatch({
    relevant<-condition_rexpression %>% parse(text = .) %>% eval
    relevant
  },error=function(e){

  stop(paste0("Skiplogic not understood:\n",
         condition,
         "tried to evaluate this as:\n",
         condition_rexpression))
  })
  })

  if(!is.logical(relevant)){
    stop(paste0("Skiplogic successfully executed in R, but did not return a logical value. Condition:\n",
                condition,
                "Condition translated to R:\n",
                condition_rexpression))
  }
  return(!relevant)
}





rify_condition<-function(x){
  x %>% rify_selected %>% rify_logical_operators %>% rify_varnames_in_string
}


rify_varnames_in_string<-function(x){
  # turns "${varname}" into varname by removing any "{", "}",  "$"
    x<-gsub("[\\\\$\\]","",x)
  }

rify_logical_operators<-function(x){
  # "and" , "or" -> "&" , "|"
  #  "=" -> "=="
  # both trying to avoid false matches (don't do "==" -> "==="),  "band" -> "b&" etc.
  x<-gsub("[[:space:]]and[[:space:]]","&",x) %>% # "and" with spaces around
     gsub("^and[[:space:]]","&",.) %>% # "and" at start of string
     gsub("[[:space:]]and$","&",.) %>% # "and" at end of string
     gsub("^and$","&",.) %>% # lonely "and"
     gsub("[[:space:]]or[[:space:]]","|",.) %>% # "or" with spaces around
     gsub("^or[[:space:]]","|",.) %>% # "or" at start of string
     gsub("[[:space:]]or$","|",.) %>% # "or at end of string
    gsub("^or$","|",.) # lonely "or"

  single_equal_sign_pattern<-"([^=<>!])[=]([^=])"
  x <-gsub(single_equal_sign_pattern,"\\1==\\2",x) # equal sign that doesn't have "=" before or after, and doesnt have "<" or ">" before.
  x
}


# RIFY "selected" patterns
rify_selected<-function(x){
  # define patterns
  varname_chars_pattern<-"[A-z0-9_\\.]*"
  choices_chars_pattern<-"[a-z0-9_]*"
  selected_start_pattern<-"selected[[:space:]]*\\([[:space:]]*\\$\\{"
  selected_middle_pattern<-"\\}[[:space:]]*,[[:space:]]*[\"']*"
  selected_end_pattern<-"[\"']*\\)"
  selected_total_pattern<-paste0(selected_start_pattern,varname_chars_pattern,selected_middle_pattern,choices_chars_pattern,selected_end_pattern)
  # find all selected conditions
  selected_expressions<-str_extract_all(x,selected_total_pattern) %>% unlist
  # rify them
  selected_expressions_replacements<-sapply(selected_expressions,rify_isolated_selected_condition) %>% unname
  # replace in condition string
  for(i in seq_along(selected_expressions)){
    x<-sub(pattern = selected_total_pattern,
           replacement = selected_expressions_replacements[i],
           x = x)
  }
  x
}


rify_isolated_selected_condition<-function(x){
  selected_start_pattern<-"selected[[:space:]]*\\([[:space:]]*\\$\\{"
  selected_middle_pattern<-'\\}[[:space:]]*,[[:space:]]*["\']*'
  selected_end_pattern <-'["\']*\\)'
  # expression(var_list <- strsplit(as.character(data$groupepers_derniermois), " "),
  #            var_evaluated <- sapply(var_list, function(x){any("pers_deplace" %in% x)}) %>% unlist)
   gsub(selected_end_pattern,'"%in% x)}) %>% unlist',x) %>% gsub(selected_middle_pattern,'%>% as.character %>% strsplit (., " ")
                                                                 var_evaluated <- sapply(var_list, function(x){any("',.) %>% gsub(selected_start_pattern,'var_list <-',.) %>% paste0(.)
}



extract_all_varnames_from_condition<-function(condition,rify=T){

  var_start_pattern<-"\\$\\{"
  var_end_pattern<-  "\\}"
  varname_chars_pattern<-"[A-z0-9_\\.]*"
  condition_variable_pattern<-paste0(var_start_pattern,varname_chars_pattern,var_end_pattern)
  variables<-str_extract_all(condition,condition_variable_pattern) %>% unlist %>% unique
  if(rify){variables %<>% gsub(var_start_pattern,"",.) %>% gsub(var_end_pattern,"",.)}
  return(variables)
}


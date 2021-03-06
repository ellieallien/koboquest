# where are the examples stored?

example.data.path<-function(examplename){
  return(paste0("./test_data/",examplename,"/"))
}


# set available examples' metadata:

example_names<-c("example1","example2")
# Metadata for examples.
# Data frame with one row per

example_metadata<-data.frame(
  name=example_names,
  path=sapply(example_names,example.data.path) %>% unname,
  choice.label.column.to.use=c("Label::English","Label::English"),
  stringsAsFactors = F
)

# two ways to load examples:
## example <- load.example("example1")
  ## names(example$data)
## load_example("example1,global_space=T)
## names(data)
##############################################################################################################################
##############################################################################################################################
##############################################################################################################################



read.example.csv<-function(filename,examplename){
  koboquest:::read.csv.auto.sep(paste0(example.data.path(examplename),filename))
}


load.example<-function(name="example1",global_space=F,with_questionnaire=T){


  ex<-example_metadata[which(example_names==name),,drop=F] %>% as.list

  exfile<-function(file){
    read.example.csv(file,ex$name)
  }
  exfilepath<-function(file){
    paste0(ex$path,file)
  }

  ex$data<-exfile("data.csv")
  if(with_questionnaire){
  ex$questionnaire<-load_questionnaire(ex$data,
                                        questions = exfilepath("kobo_questions.csv"),
                                        choices = exfilepath("kobo_choices.csv"),
                                        choices.label.column.to.use = ex$choice.label.column.to.use)
  }

  ex$tf <- data.frame("dependent.var" = c("population_group", "when_continue", "males_13_15","uasc_boys", "household_expenditure", "sep_accidental", "bla", NA, NA),
                                    "independent.var" = c("district_localadmin", "when_continue", "children_0_4", "uasc_girls", "household_expenditure", "sep_forced", "hehe", NA, NA))  %>% t %>% as.data.frame(., stringsAsFactors = F)
  colnames(ex$tf) <- c("select_one", "select_one_NA_heavy", "numeric", "numeric_NA_heavy", "select_multiple", "select_multiple_NA_heavy","fake", "NA", "NULL")
  ex$tf[,9] <- c(NULL, NULL)


  if(global_space){
    data<-ex$data
    if(with_questionnaire){
      questionnaire<-ex$questionnaire
    }

    return(NULL)
  }

  return(ex)
}







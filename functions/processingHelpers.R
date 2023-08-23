# Helper functions for processing triad data

# Reads and processes triadic data into a dataframe
# @param file_path    A string for the path to the file of the dataset
# @param answer_type  A string specifying the name of the column containing
# correct answers formatted AB, AC, or BC. If left blank
# @return X           A dataframe containing the parsed triad data
process_triad_data <- function(file_path, answer_col=NULL) {
  X = readr::read_csv(file_path,show_col_types = F)
  
  raw_answer_cols = c('AB', 'AC', 'BC')
  percent_answer_cols = c('pAC', 'pBC', 'pBC')
  
  # Rename answer column to standard if existing
  if (!is.null(answer_col) && answer_col %in% colnames(X)) {
    if (any(c('AB', 'AC', 'BC')))
      colnames(X)[colnames(df) == answer_col] <- "human_coded_answer"
    
  } else if (all(raw_answer_cols %in% colnames(X))) {
    
    # Calculate answer probabilities if required 
    if (!(all(percent_answer_cols %in% colnames(X)))) {
      X <- X %>% rowwise %>% 
        mutate(
          num_responses = sum(AB, AC, BC),
          pAB = AB/num_responses,
          pAC = AC/num_responses,
          pBC = BC/num_responses,
        ) %>% 
        select(-num_responses)
    }
    
    # Calculate the answer and difficulty for each triad 
    X = X %>%
      mutate(
        max_val = pmax(pAB, pAC, pBC),
        human_coded_answer = str_c(
          ifelse(pAB == max_val, "AB|", ""),
          ifelse(pAC == max_val, "AC|", ""),
          ifelse(pBC == max_val, "BC|", ""),
          sep = ""
        ),
        difficulty = (1 - max_val) * 3/2,
      ) %>% 
      select(-max_val)
    
  } else {
    print("Triad answer data not found. Answer frequency should be stored in 
          columns c(AB, AC, BC)")
  }
  
  return(X)
}


# Generates prompts by inserting triads between a prompt prefix and suffix
# @param df             A dataframe containing the triad data
# @param num_triads     An integer representing the number of triads per prompt  
# @param prompt_start   A string for the prompt section preceeding the triads
# @param prompt_end     A string for the prompt section following the triads
# @return prompts       A datafram containing prompt strings
generate_prompts <- function(df, num_triads, prompt_start, prompt_end) {
  prompts = data.frame(prompt=character(), stringsAsFactors=FALSE)
  
  # Remaining triads for final prompt
  rem = nrow(X) %% num_triads
  
  # Build prompts with that many triads from the data
  for (i in seq(from=1, to=nrow(X)-rem, by=num_triads)) {
    
    # Add the triads together, format correctly
    triads = str_sub(
      paste(X[seq(from=i, i+num_triads-1),]$triad, collapse=""), 
      1, -2
    )
    
    next_prompt = paste(prompt_start, triads, prompt_end,sep="")
    
    prompts <- prompts %>% add_row(prompt = next_prompt)
  }
  
  if (rem > 0) {
    remaining_triads = paste(X[seq(from=nrow(X)-rem+1, to=nrow(X)),]$triad, collapse="")
    leftovers_prompt = paste(prompt_start, remaining_triads, prompt_end, sep="")
    prompts <- prompts %>% add_row(prompt = leftovers_prompt)
  }
  return(prompts)
}

# Text mining on Data analyst job informaiton

## Overview
In order to get reqired details related to data analyst position, I plan to scrape the job post info from the linkedin, and implement text mining to understand the general or perferrable requrements from the employers.

##### Web scraping all the data analyst positions - Python
Generally, there are two issues during the process.

- Login Issue: 
  a. login with request session(I used)
  b. Selenium (slow / need to keep the login history)

- Ajax Issue:
  How to identify and find the data that we want to scapped.
  
#### Text Mining on the positions information

- Preprocessing:
  Nan Value removal
  Stop words list creation
  keep all letters in lower-case
  remove punctuation
  remove stop words
  remove addtional spaces

- Word frequency and co-occurance analysis

- Graphics mapping
  job distribution in selected cities
  skill sets frequency indexed significance
  key words cloud mapping
 


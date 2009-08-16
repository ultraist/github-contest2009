#!/bin/sh

TIMELOG="./log"

echo start `date` >> $TIMELOG

# make temporary results
perl forkbase_recommender.pl
perl author_recommender.pl
perl co_occurrence_recommender.pl
perl popular_recommender.pl

# bagging
perl bagging_recommender.pl

# make results
perl conv_results.pl ./results_bagging.txt
perl check_results.pl

echo end `date` >> $TIMELOG

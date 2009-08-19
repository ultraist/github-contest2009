#!/bin/sh

TIMELOG="./timelog"

echo `date` start >> $TIMELOG

# make temporary results
perl forkbase_recommender.pl
perl author_recommender.pl
perl co_occurrence_recommender.pl
perl popular_recommender.pl

# ensemble
perl ensemble_recommender.pl

# make results
perl conv_result.pl ./results_ensemble.txt
perl check_result.pl

echo `date` end >> $TIMELOG
